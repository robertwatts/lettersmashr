require 'mongoid'
require 'set'
require File.expand_path('../models/letter', __FILE__)

# Store, query and return Letter::Photo mongoid documents
module LetterSmashr

  class << self
    
    # Using Mongo Random Patttern, return a random Letter::Photo for a given a char
    # http://cookbook.mongodb.org/patterns/random-attribute/
    #
    # @param char [String] the char desired
    # @param tags [Array<String>] an array of tags the returning letter must contain at least one of, default is empty
    # @return LetterImage a LetterImage object
    def random(char, required_tags=[])
      random = Random.rand()

      if required_tags.nil? || required_tags.empty?
        letter_image = LetterImage.where(:char => char, :random.gte => random).first
        if photo.nil?
          letter_image = LetterImage.where(:char => char, :random.lte => random).first
        end
      else
        letter_image = LetterImage.with_all_tags(required_tags).where(:char => char, :random.gte => random).first
        if photo.nil?
          letter_image = LetterImage.with_all_tags(required_tags).where(:char => char, :random.lte => random).first
        end
      end

      return photo
    end

    # Determine whether there are more LetterImage objects available
    # 
    # @param letter_image_ids [Array<String>] an array of LetterImage ids to exclude
    # @param requird_tags [Array<String>] an array of tags the returning letter must contain at least one of, default is empty
    # @return [Boolean] a boolean indicating whether more LetterImage objects exist
    def more_letter_image?(letter_image_ids=[], required_tags=[]) 
      return true
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
        tag_set = LetterImage.where(:char => chars.shift).all_tags

        # Intersect tags_set with the remaining chars
        text.chars.each { |char|
          tag_set = tag_set & LetterImage.where(:char => char).all_tags
        }
      else
         # Populate the tag_set for the first char
        tag_set = LetterImage.where(:char => chars.shift).with_all_tags(also_tagged_with).all_tags

        # Intersect tags_set with the remaining chars
        text.chars.each { |char|
          tag_set = tag_set & LetterImage.where(:char => char).with_all_tags(also_tagged_with).all_tags
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

  

end
