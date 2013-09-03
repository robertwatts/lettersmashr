# A randomly selected LetterImage and an indication that there might be more available
class RandomLetter
  attr_reader :letter_image, :has_more

  # Using Mongo Random Patttern, initialize a RandomLetter for a given a char
  # http://cookbook.mongodb.org/patterns/random-attribute/
  #
  # @param char [String] the char desired
  # @param tags [Array<String>] an array of tags the returning letter must contain at least one of, default is empty
  # @param excluded_ids [Array<String>] an array of IDs to exclude from the random selection
  # @return [LetterSmashr::RandomLetterImage] a LetterSmashr::RandomLetterImage object
  def initialize(char, required_tags=[], excluded_ids=[])
    random = Random.rand()

    if required_tags.nil? || required_tags.empty?
      @letter_image = LetterImage.where(:char => char, :random.gte => random).first
      if photo.nil?
        @letter_image = LetterImage.where(:char => char, :random.lte => random).first
      end
    else
      @letter_image = LetterImage.with_all_tags(required_tags).where(:char => char, :random.gte => random).first
      if @letter_image.nil?
        @letter_image = LetterImage.with_all_tags(required_tags).where(:char => char, :random.lte => random).first
      end
    end

    @has_more = true  #TODO Implement!
  end
end