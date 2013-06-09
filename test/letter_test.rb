require File.dirname(__FILE__) +  '/test_helper'
require File.dirname(__FILE__) +  '/../lib/letter'

class LetterTest < MiniTest::Unit::TestCase

  def setup
    create_test_photo_data() #see test_helper.rb
  end

  def teardown
    delete_test_photo_data()
  end

  def test_insert_new
    assert Letter.exists?(@test_letter_photo_data[:flickr_id]), 'Letter::Photo  was not created'
    assert Letter::Photo.find(@test_letter_photo_data[:flickr_id]).char == @test_letter_photo_data[:char]
    assert Letter::Photo.find(@test_letter_photo_data[:flickr_id]).tags.include?('tag1'), 'Missing tag'
    assert !Letter::Photo.find(@test_letter_photo_data[:flickr_id]).tags.include?('badtag'), 'Includes bad tag'
  end

  def test_update_existing
    assert Letter.exists?(@test_letter_photo_data[:flickr_id]), 'Letter::Photo was not created'

    @test_letter_photo_data[:char] = 'b'
    Letter.save(@test_letter_photo_data)
    assert Letter.exists?(@test_letter_photo_data[:flickr_id]), 'Letter::Photo was not created'

    changed_letter = Letter::Photo.find(@test_letter_photo_data[:flickr_id])
    assert changed_letter.char == 'b', 'Letter::Photo  was not updated'
  end

  def test_delete
    assert Letter.exists?(@test_letter_photo_data[:flickr_id]), 'Letter::Photo was not created'

    Letter.delete(@test_letter_photo_data[:flickr_id])
    assert !Letter.exists?(@test_letter_photo_data[:flickr_id]), 'Letter::Photo could not be deleted'
  end

  def test_modified
    assert Letter.exists?(@test_letter_photo_data[:flickr_id]), 'Letter::Photo  was not created'
    assert !Letter.modified?(@test_letter_photo_data[:flickr_id], DateTime.parse('2003-03-20 21:49:10 -0400')), 'Letter::Photo  has a more recent time'
    assert Letter.modified?(@test_letter_photo_data[:flickr_id], DateTime.now), 'Letter::Photo  has a newer time'
  end

  def test_random
    pl_x = Letter.random('x')
    assert pl_x.nil?

    pl_b = Letter.random('b') # There can be only one b
    assert !pl_b.nil? , 'Cannot be nil'
    assert pl_b.char == 'b', 'Letter::Photo  must have char b'

    pl_b = Letter.random('b', ['tag2','tag4']) # There can be only one b
    assert !pl_b.nil? , 'Cannot be nil'
    assert pl_b.char == 'b', 'Letter::Photo  must have char b'

    a_chars = Letter::Photo.where(:char => 'a')
    assert a_chars.count == 2, 'There must be two Letter::Photo  with char a'
    puts a_chars[0].random.to_s + " " + a_chars[0].id.to_s + " " + a_chars[0].imported.to_s
    puts a_chars[1].random.to_s + " " + a_chars[1].id.to_s + " " + a_chars[1].imported.to_s

    pl_a = Letter.random('a', ['tag3']) # Make sure we get the 2nd a
    assert pl_a.id == @test_letter_photo_data2[:flickr_id], 'We expect the second A photoLetter'

    # Loop until we've hit both a's, throw exception if not found within 1000 tries
    id = Letter.random('a').id
    id2 = Letter.random('a').id
    attempts = 0
    until id2 != id || attempts == 1000 do
        id2 = Letter.random('a').id
        attempts += 1
    end
    puts "Attempts to find next random a: " + attempts.to_s
    assert id2 != id, 'We must find the other a Letter::Photo '
  end
end
