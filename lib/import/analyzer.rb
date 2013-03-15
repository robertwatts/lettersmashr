# Analyzes the Flickr photo metadata and determine characteristics relevant to LetterSmash\
class Analyzer
  attr_reader :letter

  # Construct with a flick raw photo object
  def initialize(photo)
    @photo = photo
    @letter = determine_letter()
  end

  # Determine the letter
  private def determine_letter

  end

end