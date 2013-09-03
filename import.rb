require 'mongoid'
require 'resque/errors'
require 'flickraw'
require_relative 'models/letter'

# Manages access to Importer API
class Import
  extend Resque::Plugins::ConcurrentRestriction
  concurrent 1  # Only allow Import to have one worker

  @queue = :import

  # Add a new Letter::Photo to the store
  def initialize

    # Setup and authenticate FlickrAPI using FlickrRaw
    FlickRaw.api_key = ENV['FLICKR_APP_KEY']
    FlickRaw.shared_secret = ENV['FLICKR_SHARED_SECRET']
    flickr.access_token = ENV['FLICKR_TOKEN']
    flickr.access_secret = ENV['FLICKR_SECRET']
    puts "You are now authenticated as #{flickr.test.login.username}"

    # Find the "One Letter" group from the Flickr API user's group pool list
    available_group_pools = flickr.groups.pools.getGroups

    @letter_pool = nil
    available_group_pools.each { |group|
      if group.name == 'One Letter'
        @letter_pool = group
        puts 'Initialized One Letter Group Pool'
        break
      end
    }

    # Abort if not found
    abort('Unable to find One Letter group, exiting') if @letter_pool.nil?

    # Set up redis keys to track import runs over time
    @redis_all_time_count = "all_time_run_count"
    @redis_all_time_created = "all_time_created"
    @redis_all_time_modified = "all_time_modified"
    @redis_all_time_deleted = "all_time_deleted"
    @redis_most_recent_started = "most_recent_started"
    @redis_most_recent_success = "most_recent_success"
    @redis_most_recent_duration = "most_recent_duration"
    @redis_most_recent_created = "most_recent_created"
    @redis_most_recent_modified = "most_recent_modified"
    @redis_most_recent_deleted = "most_recent_deleted"

    puts "Successfully initialized import worker instance"
  end

  # Resque execution method
  def self.perform
      (new).import
  rescue Resque::TermException
      Resque.enqueue(self)
  end

  

  ## 
  # Has the given Letter::Photo got a date older than the given date?
  # @param photo_letter_id [Integer] the photo letter id
  # @param date the new photo_letter date
  # @return boolean if stored date is older than given date
  def modified?(photo_letter_id, date)
    Photo.where(:_id => photo_letter_id, :flickr_last_update.lt => date).exists?
  end

  ##
  # Class method to import Letter::Photo
  def import
    # Set up variables for new import record
    import_begin = Time.now
    import_success = false
    import_created = 0
    import_modified = 0
    import_deleted = 0

    page_count = @letter_pool.photos.to_i / 100 + 1
    begin
      # Analyze every photo in the pool, only importing what is required
      1.upto(page_count) do |page|
        puts "Processing page #{page} of #{page_count}"

        flickr.groups.pools.getPhotos(
            :group_id => @letter_pool.nsid, per_page: 100,
            :page => page,
            :extras=> 'last_update,tags,license,url_sq,url_t,url_s').each do |photo|

          # Create a PhotoAnalyzer object from the Flickr photo
          analyzer = PhotoAnalyzer.new(photo)

          if analyzer.delete      # Delete photo
            LetterImage.delete_all(:_id => photo.id)
            import_deleted += 1
            puts "Deleted photo #{photo.id}"
          elsif analyzer.import   # Save the photo (create or update)
            LetterImage.new(
                char: analyzer.char,
                tags: analyzer.tags,
                flickr_id: photo.id,
                flickr_license: photo.license,
                flickr_last_update: Time.at(photo.lastupdate.to_i).to_datetime,
                flickr_owner: photo.owner,
                flickr_url_sq: defined?(photo.url_sq) ? photo.url_sq : nil,
                flickr_url_t: defined?(photo.url_t) ? photo.url_t : nil,
                flickr_url_s: defined?(photo.url_s) ? photo.url_s : nil,
                flickr_url_q: defined?(photo.url_q) ? photo.url_q : nil
            ).upsert

            if analyzer.exists
              import_modified += 1
              puts "Modified photo #{photo.id}"
            elsif
              import_created += 1
              puts "Created photo #{photo.id}"
            end
          end
        end
      end
      import_success = true
      puts "Finished processing. Success: #{import_success} Created: #{import_created} Modified: #{import_modified} Deleted: #{import_deleted}"
    ensure
      import_end = Time.now

      # Set all time stats
      Resque.redis.incr @redis_all_time_count
      Resque.redis.incrby @redis_all_time_created, import_created
      Resque.redis.incrby @redis_all_time_modified, import_modified
      Resque.redis.incrby @redis_all_time_deleted, import_deleted

      # Set most recent stats
      Resque.redis.set @redis_most_recent_duration,  import_end - import_begin
      Resque.redis.set @redis_most_recent_started, import_created
      Resque.redis.set @redis_most_recent_modified, import_modified
      Resque.redis.set @redis_most_recent_deleted, import_deleted
      Resque.redis.set @redis_most_recent_started, import_begin

      # Set most recent success date, if applicable
      if import_success
        Resque.redis.set @redis_most_recent_success, import_begin
      end
    end
  end

  # Authenticate with Flickr API
  def flickr_authenticate
    FlickRaw.api_key = ENV["FLICKR_APP_KEY"]
    FlickRaw.shared_secret = ENV["FLICKR_SHARED_SECRET"]

    token = flickr.get_request_token
    auth_url = flickr.get_authorize_url(token['oauth_token'], :perms => 'delete')

    puts "Open this url in your process to complete the authentication process : #{auth_url}"
    puts 'Copy here the number given when you complete the process.'
    verify = gets.strip

    begin
      flickr.get_access_token(token['oauth_token'], token['oauth_token_secret'], verify)
      login = flickr.test.login
      puts "You are now authenticated as #{login.username} with token #{flickr.access_token} and secret #{flickr.access_secret}"
    rescue FlickRaw::FailedResponse => e
      puts "Authentication failed : #{e.msg}"
    end
  end


  # Analyzes the Importer photo metadata and determine characteristics relevant to LetterSmash
  #
  # 1) Checks flickr license has a value matching 1,2,4,5,7,8 :
  #    * 0 All Rights Reserved
  #    * 1 Attribution-NonCommercial-ShareAlike License (http://creativecommons.org/licenses/by-nc-sa/2.0/)
  #    * 2 Attribution-NonCommercial License (http://creativecommons.org/licenses/by-nc/2.0/)
  #    * 3 Attribution-NonCommercial-NoDerivs License (http://creativecommons.org/licenses/by-nc-nd/2.0/)
  #    * 4 Attribution License (http://creativecommons.org/licenses/by/2.0/)
  #    * 5 Attribution-ShareAlike License (http://creativecommons.org/licenses/by-sa/2.0/)
  #    * 6 Attribution-NoDerivs License (http://creativecommons.org/licenses/by-nd/2.0/)
  #    * 7 No known copyright restrictions (http://flickr.com/commons/usage/)
  #    * 8 United States Government Work (http://www.usa.gov/copyright.shtml)
  # 2) Checks whether a letter can be determined
  # 3) Determines colors
  # 4) Determines any other tags that might be interesting
  class PhotoAnalyzer
    attr_reader :char, :tags, :exists, :delete, :import

    class << self
      # Load the list of Flickr tags to ignore on import
      @@tag_ignore_list = File.read(File.dirname(__FILE__) + '/config/tag_ignore_list').split(' ')
      puts "Ignore list: #{@@tag_ignore_list}"
    end

    # Construct with a flickraw photo object
    def initialize(photo)
      @valid_license = photo.license.to_i.between?(1,2) || photo.license.to_i.between?(4,5) || photo.license.to_i > 6
      @exists = Letter.where(:_id => photo.id).exists?

      if @valid_license
        # Process if valid license
        @tags = []
        @char = nil
        #Process tags
        photo.tags.split(' ').each do |tag|
          if tag.length == 1
            @char = tag.downcase
          elsif !@@tag_ignore_list.include?(tag)
            @tags << tag
          end
        end

        @import = !@char.nil? && (!@exists || Letter.where(:_id => photo.id, :flickr_last_update.lt => Time.at(photo.lastupdate.to_i).to_datetime).exists?)
        @delete = false
      else
        # Delete if license is not valid
        @import = false
        @delete = @exists
      end
    end
  end
end