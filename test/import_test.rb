require File.dirname(__FILE__) +  '/test_helper'
require File.dirname(__FILE__) +  '/../lib/import'
require File.dirname(__FILE__) +  '/../lib/letters'

MockPhoto = Struct.new(:id, :license, :lastupdate, :owner, :url_sq, :url_t, :url_s, :url_q, :tags)

class ImportTest < MiniTest::Unit::TestCase

 def setup
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
    puts 'Creating test photo: ' + @test_photo_letter_data[:flickr_id].to_s
    Letters.save(@test_photo_letter_data)

    @test_flickr_photo_exists = MockPhoto.new(
      1, 1, '2013-03-20 21:49:10 -0400', 'owner1',  'http://www.yahoo.com', 'http://www.yahoo.com', 'http://www.yahoo.com', nil,
        'a tag1 tag2 canon')

    @test_flickr_photo_new = MockPhoto.new(
      2, 1, '2013-03-20 21:49:10 -0400', 'owner1',  'http://www.yahoo.com', 'http://www.yahoo.com', 'http://www.yahoo.com', nil,
        'a tag1 tag3 canon')

    @test_flickr_photo_exists_new_date = MockPhoto.new(
      1, 1, '2013-07-21 21:49:10 -0400', 'owner1',  'http://www.yahoo.com', 'http://www.yahoo.com', 'http://www.yahoo.com', nil,
        'a tag1 tag2 canon')

    @test_flickr_photo_exists_changed_license = MockPhoto.new(
      1, 3, '2013-03-20 21:49:10 -0400', 'owner1',  'http://www.yahoo.com', 'http://www.yahoo.com', 'http://www.yahoo.com', nil,
        'a tag1 tag2 canon')
  end

  def teardown
    Letters::PhotoLetter.delete_all
  end

  # Add new photo letter, delete and ensure deletion
  def test_photo_analyzer_exists
    analyzer = Import::PhotoAnalyzer.new(@test_flickr_photo_exists)
    assert analyzer.char == 'a', 'Expecting char a'
    assert analyzer.exists, 'This photo already exists'
    assert !analyzer.import, 'This photo does not need to be imported'
    assert analyzer.tags.count == 2 ,'Tags should contain 2 elements'
    assert analyzer.tags.include?('tag1'), 'Tags should contain tag1'
    assert analyzer.tags.include?('tag2'), 'Tags should contain tag3'
    assert !analyzer.tags.include?('canon'), 'Tags should not contain canon'
    assert !analyzer.delete, 'This photo should not be deleted'
  end

  def test_photo_analyzer_should_create
    analyzer = Import::PhotoAnalyzer.new(@test_flickr_photo_new)
    assert analyzer.char == 'a', 'Expecting char a'
    assert !analyzer.exists, 'This photo should not exist'
    assert analyzer.import, 'This photo needs to be imported'
    assert analyzer.tags.count == 2 ,'Tags should contain 2 elements'
    assert analyzer.tags.include?('tag1'), 'Tags should contain tag1'
    assert analyzer.tags.include?('tag3'), 'Tags should contain tag3'
    assert !analyzer.tags.include?('canon'), 'Tags should not contain canon'
    assert !analyzer.delete, 'This photo should not be deleted'
  end

  def test_photo_analyzer_should_update
    analyzer = Import::PhotoAnalyzer.new(@test_flickr_photo_exists_new_date)
    assert analyzer.char == 'a', 'Expecting char a'
    assert analyzer.exists, 'This photo should exist'
    assert analyzer.import, 'This photo needs to be imported'
    assert analyzer.tags.count == 2 ,'Tags should contain 2 elements'
    assert analyzer.tags.include?('tag1'), 'Tags should contain tag1'
    assert analyzer.tags.include?('tag2'), 'Tags should contain tag2'
    assert !analyzer.tags.include?('canon'), 'Tags should not contain canon'
    assert !analyzer.delete, 'This photo should not be deleted'
  end

  def test_photo_analyzer_should_delete_changed_license
    analyzer = Import::PhotoAnalyzer.new(@test_flickr_photo_exists_changed_license)
    assert analyzer.delete, 'This photo should be deleted'
    assert !analyzer.import, 'This photo should not be imported'
    assert analyzer.exists, 'This photo should exist'
    assert analyzer.tags.nil? , 'Tags should be processed'
    assert analyzer.char.nil?,  'Char should not be set'
  end


end
