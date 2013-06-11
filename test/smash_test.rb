require File.dirname(__FILE__) +  '/test_helper'
require File.dirname(__FILE__) +  '/../lib/smash'

class SmashTest < MiniTest::Unit::TestCase

  def setup
    create_test_photo_data()
  end

  def teardown
    delete_test_photo_data()
  end

  def test_img_url
    # puts "Methods"
    # puts Smash.methods
    # puts "P Methods"
    # puts Smash.public_methods
    # puts "S Methods"
    # puts Smash.singleton_methods
    assert Smash.img_url('bad_enc_id').nil?
  end

  def test_process_img
    enc_id = Smash.process_img('ab', ['tag4'])
    puts enc_id
  end

  def test_encode_smashed_image_id
    enc_id = Smash.encode_smashed_image_id(['test1', 'test2'])
    assert Base64.urlsafe_decode64(enc_id) == 'test1,test2|', 'Should decode test1, test2'

    enc_id = Smash.encode_smashed_image_id(['test1', 'test2'], ['tag1', 'tag2'])
    puts enc_id
    puts Base64.urlsafe_decode64(enc_id)
    assert Base64.urlsafe_decode64(enc_id) == 'test1,test2|tag1,tag2', 'Should decode test1, test2|tag1,tag2'

  end
end
