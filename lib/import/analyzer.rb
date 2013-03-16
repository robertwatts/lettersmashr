=begin
  Analyzes the OneLetterGroupPool photo metadata and determine characteristics relevant to LetterSmash

  1) Checks license is either 1,2,4,5,7,8 from OneLetterGroupPool license feed:
    <licenses>
      <license id="0" name="All Rights Reserved" url="" />
      <license id="1" name="Attribution-NonCommercial-ShareAlike License" url="http://creativecommons.org/licenses/by-nc-sa/2.0/" />
      <license id="2" name="Attribution-NonCommercial License" url="http://creativecommons.org/licenses/by-nc/2.0/" />
      <license id="3" name="Attribution-NonCommercial-NoDerivs License" url="http://creativecommons.org/licenses/by-nc-nd/2.0/" />
      <license id="4" name="Attribution License" url="http://creativecommons.org/licenses/by/2.0/" />
      <license id="5" name="Attribution-ShareAlike License" url="http://creativecommons.org/licenses/by-sa/2.0/" />
      <license id="6" name="Attribution-NoDerivs License" url="http://creativecommons.org/licenses/by-nd/2.0/" />
      <license id="7" name="No known copyright restrictions" url="http://flickr.com/commons/usage/" />
      <license id="8" name="United States Government Work" url="http://www.usa.gov/copyright.shtml" />
      </licenses>

  2) Checks whether a letter can be determined

  3) Determines colors

  4) Determines any other tags that might be interesting
=end
class Analyzer

  @@tag_ignore_list = File.read(File.dirname(__FILE__) + '/../../config/tag_ignore_list').split(' ')
  puts "Ignore list: #{@tag_ignore_list}"

  attr_reader :char, :tags

  # Construct with a flick raw photo object
  def initialize(photo, last_update)
    @photo = photo
    @last_update = last_update

    @valid_license = photo.license.to_i.between?(1,2) || photo.license.to_i.between?(4,5) || photo.license.to_i > 6

    @tags = []
    @char = nil
    # Process tags
    photo.tags.split(' ').each do
    |tag|
      if tag.length == 1
        @char = tag
      elsif !@@tag_ignore_list.include?(tag)
        @tags << tag
      end
    end
  end

  # Can this photo be imported - license
  def import?
    @valid_license && !@char.nil? && Time.at(@photo.lastupdate.to_i).to_datetime >= @last_update
  end

end