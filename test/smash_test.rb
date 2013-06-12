require File.dirname(__FILE__) +  '/test_helper'
require File.dirname(__FILE__) +  '/../lib/smash'

class SmashTest < MiniTest::Unit::TestCase

  def setup
    create_test_photo_data()
  end

  def teardown
    delete_test_photo_data()
  end

  def test_smash_single_threaded
    id = Smash.enqueue('ab', ['tag4'])                                            # Kick off
    assert Base64.urlsafe_decode64(id) == '2,3|tag4', 'Should decode ab|tag4'     # Check ID encoding
    assert !Smash.processing?(id), 'Should have been processed: ' + id            # Check it's processed (.start will block during test)
    assert Smash.exists?(id), 'Should exist: ' + id                               # Check it exists

    smashed_image = Smash.image(id)

    assert !smashed_image.nil?, 'SmashedImage cannot be nil'                      # Check that an object is returned
    assert smashed_image.url.include?('/blitline')                                # Check a url has been created
    assert smashed_image.text == 'ab', 'Expect text ab'                           # Check text is correct
    assert smashed_image.photo_ids.include?(2)
    assert smashed_image.photo_ids.include?(3)
    assert smashed_image.width == 480, smashed_image.width.to_s + ' should be 240'     # Check width
    assert smashed_image.height == 240, smashed_image.height.to_s + ' should be 240'   # Check height

  end
end
