require File.dirname(__FILE__) + '/flickr_api'
require File.dirname(__FILE__) + '/analyzer'
require File.dirname(__FILE__) + '/../models/photo_letter'

# Manages access to OneLetterGroupPool API
class OneLetterGroupPool

  attr_reader :photo_count, :page_count

  def initialize
    # Find the One Letter group from the user's group pool list
    flickr = FlickrApi.instance.api
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

  # Return photos in this group
  def get_photos(last_update)

    puts "Retrieving photos since #{last_update}"

    page_count = @letter_pool.photos.to_i / 500 + 1

    photoLetters = Array.new

    # Process every photo in the pool, filtering by license, last_update and taxonomic validity
    1.upto(page_count) do
        |page|
      puts "Processing page #{page} of #{page_count}"

      FlickrApi.instance.api.groups.pools.getPhotos(:group_id => @letter_pool.nsid, per_page: 500,
                                                    :page => page, :extras=> 'last_update,tags,license', ).each do
        |photo|
        analyzer = Analyzer.new(photo, last_update)

        if analyzer.import?
          puts "Inserting new photo letter #{analyzer.char}"
          photoLetters << {
            char: analyzer.char,
            tags: analyzer.tags,
            flickr_id: photo.id,
            flickr_license: photo.license,
            flickr_last_update: photo.last_update,
            flickr_owner: photo.owner
          }
        end
      end
    end

    puts "Finished processing: #{photoLetters.length} photos to be imported"

  end

end