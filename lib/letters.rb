require 'mongoid'
require File.expand_path('../models/photo_letter', __FILE__)

# Letters manager that stores and queries and returns PhotoLetter objects
class Letters

  # Saves a PhotoLetter.  Will create a new one or update an existing one
  #
  # @param args [Map] the photo letter values
  def save(args = {})
    PhotoLetter.new(args).save!
  end

  # Remove an existing PhotoLetter from the store
  #
  # @param photo_letter_id [Integer] the photo letter id
  def delete(photo_letter_id)
    PhotoLetter.delete_all(_id: photo_letter_id)
  end

  # Checks whether a PhotoLetter exists
  #
  # @param photo_letter_id [Integer] the photo letter id
  def exists?(photo_letter_id)
    PhotoLetter.where(_id: photo_letter_id).exists?
  end

  # Create an array of PhotoLetter objects to represent the given word
  #
  # @param word [String] the word desired
  # @param tags [Array<String>] an optional array of tags the returning array must contain
  # @return [Array<PhotoLetter>] an array of photo letter objects
  def random_word(word, *tags)

  end

  # Return an array of available tags for a given word
  #
  # @param word [String] the word the test for available tags
  # @return [Array<String>] a String array of tags available for all letters
  def available_tags(word)

  end

end
