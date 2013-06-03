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
    PhotoLetter.delete_all(_id: photo_letter_id)
  end

  # Checks whether a PhotoLetter exists
  #
  # @param photo_letter_id [Integer] the photo letter id
  def self.exists?(photo_letter_id)
    PhotoLetter.where(_id: photo_letter_id).exists?
  end

  # Returns the modified date of a PhotoLetter
  #
  # @param photo_letter_id [Integer] the photo letter id
  def self.modified_date(photo_letter_id)
    PhotoLetter.find(photo_letter_id).flickr_last_update
  end

  # Create an array of PhotoLetter objects to represent the given word
  #
  # @param word [String] the word desired
  # @param tags [Array<String>] an optional array of tags the returning array must contain
  # @return [Array<PhotoLetter>] an array of photo letter objects
  def self.random_word(word, *tags)

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

    # Custom id field: use flickr_id
    field :_id, type: Integer, default: ->{ flickr_id }

    field :char, type: String
    field :capital, type: Boolean, default: ->{char.upcase}
    field :tags, type: Array
    field :imported, type: DateTime, default: DateTime.now

    field :flickr_id, type: Integer
    field :flickr_license, type: Integer
    field :flickr_owner, type: String
    field :flickr_last_update, type: DateTime

    field :flickr_url_sq, type: String #75x75
    field :flickr_url_t, type: String #100x100
    field :flickr_url_s, type: String #240x240
    field :flickr_url_q, type: String #150x150

  end

end
