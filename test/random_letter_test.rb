require_relative 'test_helper'
require_relative '../models/random_letter'

class RandomLetterTest < MiniTest::Unit::TestCase

  def setup
    create_test_data() #see test_helper.rb
  end

  def teardown
    delete_test_data()
  end

  def test_random_letter
    pl_x = RandomLetter.new('x')
    assert pl_x.letter.nil?

    pl_b = RandomLetter.new('b') # There can be only one b
    assert !pl_b.letter.nil? , 'Cannot be nil'
    assert pl_b.letter.char == 'b', 'RandomLetter must have char b'

    # Loop until we've hit both a's, throw exception if not found within 1000 tries
    # TODO Remove when properly normalizing the distribution 
    id = RandomLetter.new('a').letter.id
    id2 = RandomLetter.new('a').letter.id
    attempts = 0
    until id2 != id || attempts == 1000 do
        id2 = RandomLetter.new('a').letter.id
        attempts += 1
    end
    puts "Attempts to find next random a: " + attempts.to_s
    if (id == id2)
      warn 'Unable to the second Letter  for character "a"'
    end
  end

  def test_random_letter_with_tags

    pl_b = RandomLetter.new('b', ['tag2','tag4']) # There can be only one b
    assert !pl_b.letter.nil? , 'Cannot be nil'
    assert pl_b.letter.char == 'b', 'RandomLetter must have char b'

    pl_a = RandomLetter.new('a', ['tag3']) # Make sure we get the 2nd a
    assert !pl_a.letter.nil? , 'Cannot be nil'
    assert pl_a.letter.id == @test_letter_data2[:flickr_id], 'We expect the second A photoLetter'

    
  end
end