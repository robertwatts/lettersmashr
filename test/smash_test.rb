require File.dirname(__FILE__) +  '/test_helper'
require File.dirname(__FILE__) +  '/../lib/smash'

class SmashTest < MiniTest::Unit::TestCase

  def setup
    create_test_photo_data()
  end

  def teardown
    delete_test_photo_data()
  end

  def test_create_img
    puts "Creating image"
    puts ENV['BLITLINE_APPLICATION_ID']
    str = Smash.create_img("aab")
  end
end
