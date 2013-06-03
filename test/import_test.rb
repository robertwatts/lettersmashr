require File.dirname(__FILE__) +  '/test_helper'
require File.dirname(__FILE__) +  '/../lib/import'

class ImportTest < MiniTest::Unit::TestCase

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
  end

  # Add new photo letter, delete and ensure deletion
  def test_photo_analyzer_exists

  end

  def test_photo_analyzer_should_delete
  end

  def test_photo_analyzer_should_create
  end
end
