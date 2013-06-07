require File.dirname(__FILE__) +  '/test_helper'
require File.dirname(__FILE__) +  '/../lib/letters'

class LettersTest < MiniTest::Unit::TestCase

  def setup
    @test_photo_letter_data = {
        char: 'a',
        tags: %w(tag1 tag2),
        flickr_id: 1,
        flickr_license: 1,
        flickr_last_update: DateTime.parse('2013-03-20 21:49:10 -0400').to_i,
        flickr_owner: 'owner1',
        flickr_url_sq: 'http://www.yahoo.com',
        flickr_url_t: 'http://www.yahoo.com',
        flickr_url_s: 'http://www.yahoo.com',
        flickr_url_q: nil
    }
    Letters.save(@test_photo_letter_data)

    @test_photo_letter_data2 = {
        char: 'a',
        tags: %w(tag2 tag3),
        flickr_id: 2,
        flickr_license: 1,
        flickr_last_update: DateTime.parse('2013-03-20 21:49:10 -0400').to_i,
        flickr_owner: 'owner1',
        flickr_url_sq: 'http://www.yahoo.com',
        flickr_url_t: 'http://www.yahoo.com',
        flickr_url_s: 'http://www.yahoo.com',
        flickr_url_q: nil
    }
    Letters.save(@test_photo_letter_data2)

    @test_photo_letter_data3 = {
        char: 'b',
        tags: %w(tag2 tag4),
        flickr_id: 3,
        flickr_license: 1,
        flickr_last_update: DateTime.parse('2013-03-20 21:49:10 -0400').to_i,
        flickr_owner: 'owner1',
        flickr_url_sq: 'http://www.yahoo.com',
        flickr_url_t: 'http://www.yahoo.com',
        flickr_url_s: 'http://www.yahoo.com',
        flickr_url_q: nil
    }
    Letters.save(@test_photo_letter_data3)
  end

  def teardown
    Letters::PhotoLetter.delete_all
  end

  def test_insert_new
    assert Letters.exists?(@test_photo_letter_data[:flickr_id]), 'PhotoLetter was not created'
    assert Letters::PhotoLetter.find(@test_photo_letter_data[:flickr_id]).char == @test_photo_letter_data[:char]
    assert Letters::PhotoLetter.find(@test_photo_letter_data[:flickr_id]).tags.include?('tag1'), 'Missing tag'
    assert !Letters::PhotoLetter.find(@test_photo_letter_data[:flickr_id]).tags.include?('badtag'), 'Includes bad tag'
  end

  def test_update_existing
    assert Letters.exists?(@test_photo_letter_data[:flickr_id]), 'PhotoLetter was not created'

    @test_photo_letter_data[:char] = 'b'
    Letters.save(@test_photo_letter_data)
    assert Letters.exists?(@test_photo_letter_data[:flickr_id]), 'PhotoLetter was not created'

    changed_letter = Letters::PhotoLetter.find(@test_photo_letter_data[:flickr_id])
    assert changed_letter.char == 'b', 'PhotoLetter was not updated'
  end

  def test_delete
    assert Letters.exists?(@test_photo_letter_data[:flickr_id]), 'PhotoLetter was not created'

    Letters.delete(@test_photo_letter_data[:flickr_id])
    assert !Letters.exists?(@test_photo_letter_data[:flickr_id]), 'PhotoLetter could not be deleted'
  end

  def test_modified
    assert Letters.exists?(@test_photo_letter_data[:flickr_id]), 'PhotoLetter was not created'
    assert !Letters.modified?(@test_photo_letter_data[:flickr_id], DateTime.parse('2003-03-20 21:49:10 -0400')), 'PhotoLetter has a more recent time'
    assert Letters.modified?(@test_photo_letter_data[:flickr_id], DateTime.now), 'PhotoLetter has a newer time'
  end

  def test_random_photo_letter
    pl_x = Letters.random_photo_letter('x')
    assert pl_x.nil?

    pl_b = Letters.random_photo_letter('b') # There can be only one b
    assert !pl_b.nil? , 'Cannot be nil'
    assert pl_b.char == 'b', 'PhotoLetter must have char b'

    pl_b = Letters.random_photo_letter('b', ['tag2','tag4']) # There can be only one b
    assert !pl_b.nil? , 'Cannot be nil'
    assert pl_b.char == 'b', 'PhotoLetter must have char b'

    a_chars = Letters::PhotoLetter.where(:char => 'a')
    assert a_chars.count == 2, 'There must be two PhotoLetter with char a'
    puts a_chars[0].random.to_s + " " + a_chars[0].id.to_s + " " + a_chars[0].imported.to_s
    puts a_chars[1].random.to_s + " " + a_chars[1].id.to_s + " " + a_chars[1].imported.to_s

    pl_a = Letters.random_photo_letter('a', ['tag3']) # Make sure we get the 2nd a
    assert pl_a.id == @test_photo_letter_data2[:flickr_id], 'We expect the second A photoLetter'

    # Loop until we've hit both a's, throw exception if not found within 1000 tries
    pl_a = Letters.random_photo_letter('a')
    id = pl_a.id
    attempts = 0
    begin
        pl_a2 = Letters.random_photo_letter('a')
        new_id = pl_a2.id
        attempts += 1
    end until new_id != id || attempts == 10
    assert new_id != id, 'We must find the other a PhotoLetter'
  end

  def test_from_string
    str  = Letters.from_string('a')
    assert str.length == 1, 'must contain one'
    str  = Letters.from_string('aa')
    assert str.length == 2, 'must contain two'
    str  = Letters.from_string('aab')
    assert str.length == 3, 'must contain three'
  end

end
