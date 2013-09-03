require 'set'
require_relative 'letter'

# Determines available tags for the given text string
class TagList
  attr_reader :tags

  # Initalizes a TagList object for the given text
  #
  # @param text [String] the inbound string
  # @param also_tagged_with [Array<String>] an optional array of tags that must also be matched
  # @param start_with [String] an optional string that filters tags that start with this string
  # @return [Array<String>] an array of available tags
    
  def initialize(text, also_tagged_with=[], start_with=nil)
    chars = text.chars.to_a             # Convert text into char

    if also_tagged_with.nil? || also_tagged_with.empty?
      # Populate the tag_set for the first char
      tag_set = Letter.where(:char => chars.shift).all_tags

      # Intersect tags_set with the remaining chars
      text.chars.each { |char|
        tag_set = tag_set & Letter.where(:char => char).all_tags
      }
    else
       # Populate the tag_set for the first char
      tag_set = Letter.where(:char => chars.shift).with_all_tags(also_tagged_with).all_tags

      # Intersect tags_set with the remaining chars
      text.chars.each { |char|
        tag_set = tag_set & Letter.where(:char => char).with_all_tags(also_tagged_with).all_tags
      }

      # Finally, filter any tags returned that are already in also_tagged_with
      tag_set.delete_if {|tag| also_tagged_with.include?(tag)}
    end

    # # Filter by start_with, if required
    if !start_with.nil? && !start_with.empty?
      tag_set.keep_if {|tag| tag.start_with?(start_with) }
    end

    @tags = tag_set
  end
end 
