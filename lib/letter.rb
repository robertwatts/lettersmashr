require 'mongoid'

# Store, query and return Letter::Photo mongoid documents
module Letter

  # Saves a Photo.  Will create a new one or update an existing one
  #
  # @param args [Map] the photo letter values
  def self.save(args = {})
    Photo.new(args).upsert
  end

  # Remove an existing Letter::Photo from the store
  #
  # @param photo_letter_id [Integer] the photo letter id
  def self.delete(photo_letter_id)
    Photo.delete_all(:_id => photo_letter_id)
  end

  # Checks whether a Letter::Photo exists
  #
  # @param photo_letter_id [Integer] the photo letter id
  # @return boolean whether a Letter::Photo with this id exists
  def self.exists?(photo_letter_id)
    Photo.where(:_id => photo_letter_id).exists?
  end

  # Has the given Letter::Photo got a date older than the given date?
  #
  # @param photo_letter_id [Integer] the photo letter id
  # @param date the new photo_letter date
  # @return boolean if stored date is older than given date
  def self.modified?(photo_letter_id, date)
    Photo.where(:_id => photo_letter_id, :flickr_last_update.lt => date).exists?
  end

  # Using Mongo Random Patttern, return a random Letter::Photo for a given a char
  # http://cookbook.mongodb.org/patterns/random-attribute/
  #
  # @param char [String] the char desired
  # @param tags [Array<String>] an optional array of tags the returning letter must contain at least one of
  # @return Letter::Photo a Letter::Photo object
  def self.random(char, *required_tags)
    random = Random.rand()

    # TODO make more BEAUTIFUL
    if required_tags.empty?
      photo = Photo.where(:char => char, :random.gte => random).first
      if photo.nil?
        photo = Photo.where(:char => char, :random.lte => random).first
      end
    else
      photo = Photo.with_any_tags(required_tags).where(:char => char, :random.gte => random).first
      if photo.nil?
        photo = Photo.with_any_tags(required_tags).where(:char => char, :random.lte => random).first
      end
    end

    photo
  end

  # Return an array of available tags for a given word
  #
  # @param word [String] the word the test for available tags
  # @return [Array<String>] a String array of tags available for all letters
  def self.available_tags(word)

  end

  # Mongo collection of PhotoLettter
  class Photo
    include Mongoid::Document
    include Mongoid::TagsArentHard
    store_in collection: "letter_photos"

    field :_id, type: Integer, default: ->{ flickr_id }                                   # Custom id field: use flickr_id
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
