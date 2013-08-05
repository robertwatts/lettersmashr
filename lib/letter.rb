require 'mongoid'
require 'set'
# Store, query and return Letter::Photo mongoid documents
module Letter

  class << self
    # Saves a Photo.  Will create a new one or update an existing one
    #
    # @param args [Map] the photo letter values
    def save(args = {})
      Photo.new(args).upsert
    end

    # Remove an existing Letter::Photo from the store
    #
    # @param photo_letter_id [Integer] the photo letter id
    def delete(photo_letter_id)
      Photo.delete_all(:_id => photo_letter_id)
    end

    # Checks whether a Letter::Photo exists
    #
    # @param photo_letter_id [Integer] the photo letter id
    # @return boolean whether a Letter::Photo with this id exists
    def exists?(photo_letter_id)
      Photo.where(:_id => photo_letter_id).exists?
    end

    # Has the given Letter::Photo got a date older than the given date?
    #
    # @param photo_letter_id [Integer] the photo letter id
    # @param date the new photo_letter date
    # @return boolean if stored date is older than given date
    def modified?(photo_letter_id, date)
      Photo.where(:_id => photo_letter_id, :flickr_last_update.lt => date).exists?
    end

    # Using Mongo Random Patttern, return a random Letter::Photo for a given a char
    # http://cookbook.mongodb.org/patterns/random-attribute/
    #
    # @param char [String] the char desired
    # @param tags [Array<String>] an array of tags the returning letter must contain at least one of, default is empty
    # @return Letter::Photo a Letter::Photo object
    def random(char, required_tags=[])
      random = Random.rand()

      if required_tags.nil? || required_tags.empty?
        photo = Photo.where(:char => char, :random.gte => random).first
        if photo.nil?
          photo = Photo.where(:char => char, :random.lte => random).first
        end
      else
        photo = Photo.with_all_tags(required_tags).where(:char => char, :random.gte => random).first
        if photo.nil?
          photo = Photo.with_all_tags(required_tags).where(:char => char, :random.lte => random).first
        end
      end

      return photo
    end

    # Determines available tags for the given text string
    #
    # @param text [String] the inbound string
    # @param also_tagged_with [Array<String>] an optional array of tags that must also be matched
    # @param start_with [String] an optional string that filters tags that start with this string
    # @return [Array<String>] an array of available tags
    def tag_list(text, also_tagged_with=[], start_with=nil)
      chars = text.chars.to_a             # Convert text into char

      if also_tagged_with.nil? || also_tagged_with.empty?
        # Populate the tag_set for the first char
        tag_set = Photo.where(:char => chars.shift).all_tags

        # Intersect tags_set with the remaining chars
        text.chars.each { |char|
          tag_set = tag_set & Photo.where(:char => char).all_tags
        }
      else
         # Populate the tag_set for the first char
        tag_set = Photo.where(:char => chars.shift).with_all_tags(also_tagged_with).all_tags

        # Intersect tags_set with the remaining chars
        text.chars.each { |char|
          tag_set = tag_set & Photo.where(:char => char).with_all_tags(also_tagged_with).all_tags
        }

        # Finally, filter any tags returned that are already in also_tagged_with
        tag_set.delete_if {|tag| also_tagged_with.include?(tag)}
      end

      # # Filter by start_with, if required
      if !start_with.nil? && !start_with.empty?
        tag_set.keep_if {|tag| tag.start_with?(start_with) }
      end

      return tag_set.sort!  # Return sorted tag_set
    end
  end

  # Photo mongo doc
  class Photo
    include Mongoid::Document
    include Mongoid::TagsArentHard
    store_in collection: "letter_photos"

    field :_id, type: Integer, default: ->{ flickr_id }                   # Custom id field: use flickr_id
    field :random, type: BigDecimal, default: ->{ Random.new.rand() }     # Used to select random documents

    field :char, type: String
    field :capital, type: Boolean, default: ->{char.upcase}

    taggable_with :tags, seperator: ' '

    field :imported, type: DateTime, default: ->{ DateTime.now}

    field :flickr_id, type: Integer
    field :flickr_license, type: Integer
    field :flickr_owner, type: String
    field :flickr_last_update, type: DateTime

    field :flickr_url_sq, type: String #75x75
    field :flickr_url_t, type: String #100x100
    field :flickr_url_s, type: String #240x240

    # Index the char, tags and random in the same index, run in background
    index({ char: 1, random: 1 }, { unique: false, background: true })

  end

end
