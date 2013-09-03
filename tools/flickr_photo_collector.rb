require 'flickraw'
require_relative 'import'

# Connects to Flickr and collects Photo data from the OneLetter group pool
class FlickrPhotoCollector

  attr_reader :count

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

    @photo_count.photos.to_i / 100 + 1
  end

  def get_photos
    flickr.groups.pools.getPhotos(
        :group_id => @letter_pool.nsid, per_page: 100,
        :page => page,
        :extras => 'last_update,tags,license,url_sq,url_t,url_s')
  end

end