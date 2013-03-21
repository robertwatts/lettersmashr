require File.dirname(__FILE__) +  '/test_helper'
require File.dirname(__FILE__) +  '/../lib/letters'
require File.dirname(__FILE__) +  '/../lib/models/photo_letter'

class LettersTest < MiniTest::Unit::TestCase

  def setup
    @letters = Letters.new
    @test_photo_letter_data = {
        char: 'a',
        tags: %w(tag1 tag2),
        flickr_id: 1,
        flickr_license: 1,
        flickr_last_update: '2013-03-20 21:49:10 -0400',
        flickr_owner: 'owner1',
        flickr_url_sq: 'http://www.yahoo.com',
        flickr_url_t: 'http://www.yahoo.com',
        flickr_url_s: 'http://www.yahoo.com',
        flickr_url_q: nil
    }
  end

  def teardown
    PhotoLetter.delete_all
  end

  # Add new photo letter, delete and ensure deletion
  def test_create_delete
    puts 'Creating test photo: ' + @test_photo_letter_data[:flickr_id].to_s
    @letters.save(@test_photo_letter_data)
    assert @letters.exists?(@test_photo_letter_data[:flickr_id]), 'PhotoLetter was not created'

    puts 'Deleting test photo: ' + @test_photo_letter_data[:flickr_id].to_s
    @letters.delete(@test_photo_letter_data[:flickr_id])
    assert !@letters.exists?(@test_photo_letter_data[:flickr_id]), 'PhotoLetter could not be deleted'
  end
end