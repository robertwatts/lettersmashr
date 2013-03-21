require 'configurability'
require 'flickraw'
require 'mongoid'
require_relative 'models/photo_letter'

# Manages access to Importer API
class Importer

  # Add a new PhotoLetter to the store
  def initialize
    # Importer Config
    import_config = Configurability::Config.load(File.dirname(__FILE__) + '/../config/import.yml')

    # Setup Mongoid
    Mongoid.load!(File.dirname(__FILE__) + '/../config/mongoid.yml', :development)

    # Setup and authenticate FlickrAPI using FlickrRaw
    FlickRaw.api_key = import_config.flickr.apiKey
    FlickRaw.shared_secret= import_config.flickr.sharedSecret
    flickr.access_token = import_config.flickr.token
    flickr.access_secret = import_config.flickr.secret
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
  end

  def last_import_record
    ImportRecord.order_by([:started_at, :desc]).limit(1).first
  end

  # Class method to import PhotoLetter
  def import
    last_update = DateTime.new(1970,1,1)

    import_record = last_import_record

    unless import_record.nil?
      last_update = import_record.ended_at
      puts "Last import: #{import_record.to_s}"
    end

    puts "Retrieving photos since #{last_update}"

    # Set up variables for new import record
    import_begin = Time.now
    import_success = false
    import_created = 0
    import_modified = 0
    import_deleted = 0

    page_count = @letter_pool.photos.to_i / 250 + 1
    begin
      # Analyze every photo in the pool, only importing what is required
      1.upto(page_count) do |page|
        puts "Processing page #{page} of #{page_count}"

        flickr.groups.pools.getPhotos(
            :group_id => @letter_pool.nsid, per_page: 250,
            :page => page,
            :extras=> 'last_update,tags,license,url_sq,url_t,url_s,url_q').each do |photo|
          analyzer = PhotoAnalyzer.new(photo, last_update)


          if analyzer.should_delete      # Delete photo
            Letters::delete(photo.id)
            import_deleted += 1
            puts "Deleted photo #{photo.id}"
          elsif analyzer.should_import   # Save the photo (create or update)
            Letters::save(
                _id: photo.id,
                char: analyzer.char,
                tags: analyzer.tags,
                flickr_license: photo.license,
                flickr_last_update: photo.lastupdate,
                flickr_owner: photo.owner,
                flickr_url_sq: defined?(photo.url_sq) ? photo.url_sq : nil,
                flickr_url_t: defined?(photo.url_t) ? photo.url_t : nil,
                flickr_url_s: defined?(photo.url_s) ? photo.url_s : nil,
                flickr_url_q: defined?(photo.url_q) ? photo.url_q : nil
            )

            if analyzer.exists
              import_modified += 1
              puts "Modified photo #{photo.id}"
            else
              import_created += 1
              puts "Created photo #{photo.id}"
            end
          end
        end
      end
      import_success = true
      puts "Finished processing. Created: #{import_created} Modified: #{import_modified} Deleted: #{import_deleted}"
    ensure
      import_end = Time.now
      ImportRecord.create(
          started_at: import_begin,
          ended_at: import_end,
          success: import_success,
          duration: import_end - import_begin,
          created: import_created,
          modified: import_modified,
          deleted: import_deleted
      )
    end
  end

  # Authenticate with Flickr API
  def flickr_authenticate
    FlickRaw.api_key = config.flickr.apiKey
    FlickRaw.shared_secret = config.flickr.sharedSecret

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
    attr_reader :char, :tags, :exists, :should_delete, :should_import

    class << self
      # Load the list of Flickr tags to ignore on import
      @@tag_ignore_list = File.read(File.dirname(__FILE__) + '/../config/tag_ignore_list').split(' ')
      puts "Ignore list: #{@@tag_ignore_list}"
    end

    # Construct with a flick raw photo object
    def initialize(photo, last_update)
      @last_update = last_update

      @valid_license = photo.license.to_i.between?(1,2) || photo.license.to_i.between?(4,5) || photo.license.to_i > 6
      @exists = Letters.exists?(photo.id)
      @should_import = @valid_license && !@char.nil? && Time.at(photo.lastupdate.to_i).to_datetime >= @last_update
      @should_delete = @exists && !@should_import

      @tags = []
      @char = nil
      #Process tags
      photo.tags.split(' ').each do
      |tag|
        if tag.length == 1
          @char = tag.downcase
        elsif !@@tag_ignore_list.include?(tag)
          @tags << tag
        end
      end
    end

  end

  # Holder of import record information as a Mongoid document
  class ImportRecord
    include Mongoid::Document

    field :started_at, :type => Time
    field :ended_at, :type => Time
    field :success, :type => Boolean
    field :duration, :type => Integer
    field :created, :type => Integer
    field :modified, :type => Integer
    field :deleted, :type => Integer

    def to_s # called with print / puts
      "ImportRecord [Started: #{started_at}, Ended: #{ended_at}, Duration: #{duration}s, " +
          "Completed successfully: #{success} Created :#{created},Modified: #{modified}, Deleted: #{deleted}"
    end
  end

end
#
## Run this class
#puts 'Beginning import'
#importer = Importer.new
#importer.import
#puts importer.last_import_record.to_s
#puts 'Import ended'