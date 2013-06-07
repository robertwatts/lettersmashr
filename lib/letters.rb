require 'mongoid'

# Letters manager that stores and queries and returns PhotoLetter objects
module Letters

  # Saves a PhotoLetter.  Will create a new one or update an existing one
  #
  # @param args [Map] the photo letter values
  def self.save(args = {})
    PhotoLetter.new(args).upsert
  end

  # Remove an existing PhotoLetter from the store
  #
  # @param photo_letter_id [Integer] the photo letter id
  def self.delete(photo_letter_id)
    PhotoLetter.delete_all(:_id => photo_letter_id)
  end

  # Checks whether a PhotoLetter exists
  #
  # @param photo_letter_id [Integer] the photo letter id
  # @return boolean whether a PhotoLetter with this id exists
  def self.exists?(photo_letter_id)
    PhotoLetter.where(:_id => photo_letter_id).exists?
  end

  # Has the given PhotoLetter got a date older than the given date?
  #
  # @param photo_letter_id [Integer] the photo letter id
  # @param date the new photo_letter date
  # @return boolean if stored date is older than given date
  def self.modified?(photo_letter_id, date)
    PhotoLetter.where(:_id => photo_letter_id, :flickr_last_update.lt => date).exists?
  end

  # Using Mongo Random Patttern, return a random PhotoLetter for a given a char
  # http://cookbook.mongodb.org/patterns/random-attribute/
  #
  # @param char [String] the char desired
  # @param tags [Array<String>] an optional array of tags the returning letter must contain at least one of
  # @return [PhotoLetter] a PhotoLetter object
  def self.random_photo_letter(char, *required_tags)
    random = Random.rand()
    #puts random

    # TODO make more BEAUTIFUL
    if required_tags.empty?
      random_photo_letter = PhotoLetter.where(:char => char, :random.gte => random).first
      if random_photo_letter.nil?
        random_photo_letter = PhotoLetter.where(:char => char, :random.lte => random).first
      end
    else
      random_photo_letter = PhotoLetter.with_any_tags(required_tags).where(:char => char, :random.gte => random).first
      if random_photo_letter.nil?
        random_photo_letter = PhotoLetter.with_any_tags(required_tags).where(:char => char, :random.lte => random).first
      end
    end

    random_photo_letter
  end

  # Create an array of PhotoLetter objects from a given string
  #
  # @param str [String] the inbound string
  # @param tags [Array<String>] an optional array of tags each PhotoLetter must contain at least one of
  # @return [Array<PhotoLetter>] an array of photo letter objects
  def self.from_string(str, *required_tags)
    photo_letters = Array.new
    str.chars.each { |char| photo_letters << random_photo_letter(char, required_tags) }
    photo_letters
  end

  # Return an array of available tags for a given word
  #
  # @param word [String] the word the test for available tags
  # @return [Array<String>] a String array of tags available for all letters
  def self.available_tags(word)

  end

  # Mongo collection of PhotoLettter
  class PhotoLetter
    include Mongoid::Document
    include Mongoid::TagsArentHard
    store_in collection: "photo_letters"

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
    field :flickr_url_q, type: String #150x150

    # Index the char, tags and random in the same index, run in background
    index({ char: 1, random: 1 }, { unique: false, background: true })

  end

end
