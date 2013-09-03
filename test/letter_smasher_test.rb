require_relative 'test_helper'
require_relative '../models/letter'

class LetterSmasherTest < MiniTest::Unit::TestCase

  def setup
    create_test_data() #see test_helper.rb
  end

  def teardown
    delete_test_data()
  end

  def test_random
    # pl_x = Letter.random('x')
    # assert pl_x.nil?

    # pl_b = Letter.random('b') # There can be only one b
    # assert !pl_b.nil? , 'Cannot be nil'
    # assert pl_b.char == 'b', 'Letter::Photo  must have char b'

    # pl_b = Letter.random('b', ['tag2','tag4']) # There can be only one b
    # assert !pl_b.nil? , 'Cannot be nil'
    # assert pl_b.char == 'b', 'Letter::Photo  must have char b'

    # a_chars = Letter::LetterImage.where(:char => 'a')
    # assert a_chars.count == 2, 'There must be two Letter::Photo  with char a'
    # puts a_chars[0].random.to_s + " " + a_chars[0].id.to_s + " " + a_chars[0].imported.to_s
    # puts a_chars[1].random.to_s + " " + a_chars[1].id.to_s + " " + a_chars[1].imported.to_s

    # pl_a = Letter.random('a', ['tag3']) # Make sure we get the 2nd a
    # assert pl_a.id == @test_letter_photo_data2[:flickr_id], 'We expect the second A photoLetter'

    # # Loop until we've hit both a's, throw exception if not found within 1000 tries
    # id = Letter.random('a').id
    # id2 = Letter.random('a').id
    # attempts = 0
    # until id2 != id || attempts == 1000 do
    #     id2 = Letter.random('a').id
    #     attempts += 1
    # end
    # puts "Attempts to find next random a: " + attempts.to_s
    # if (id == id2)
    #   warn 'Unable to the second Letter::Photo for character "a"'
    # end
  end

  
end
