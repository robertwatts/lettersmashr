require_relative 'test_helper'
require_relative '../tools/importer'
  
MockPhoto = Struct.new(:id, :license, :lastupdate, :owner, :url_sq, :url_t, :url_s, :url_q, :tags)

class ImportTest < MiniTest::Unit::TestCase

 def setup
  create_test_data() #see test_helper.rb

  @test_flickr_photo_exists = MockPhoto.new(
    1, 1, DateTime.parse('2013-03-20 21:49:10 -0400').to_i, 'owner1',  'http://www.yahoo.com', 'http://www.yahoo.com', 'http://www.yahoo.com', nil,
      'a tag1 tag2 canon')

  @test_flickr_photo_new = MockPhoto.new(
    100, 1, DateTime.parse('2013-03-20 21:49:10 -0400').to_i, 'owner1',  'http://www.yahoo.com', 'http://www.yahoo.com', 'http://www.yahoo.com', nil,
      'z tag1 tag3 canon')

  @test_flickr_photo_new_bad_license = MockPhoto.new(
    101, 3, DateTime.parse('2013-03-20 21:49:10 -0400').to_i, 'owner1',  'http://www.yahoo.com', 'http://www.yahoo.com', 'http://www.yahoo.com', nil,
      'z tag1 tag2 canon')

  @test_flickr_photo_exists_new_date = MockPhoto.new(
    1, 1, DateTime.parse('2013-07-21 21:49:10 -0400').to_i, 'owner1',  'http://www.yahoo.com', 'http://www.yahoo.com', 'http://www.yahoo.com', nil,
      'a tag1 tag2 canon')

  @test_flickr_photo_exists_changed_license = MockPhoto.new(
    1, 3, DateTime.parse('2013-03-20 21:49:10 -0400').to_i, 'owner1',  'http://www.yahoo.com', 'http://www.yahoo.com', 'http://www.yahoo.com', nil,
      'a tag1 tag2 canon')
  end

  def teardown
    delete_test_data()
  end

  def test_parse_flickr_date
    assert Time.at(1369824900).to_datetime
  end

  # Add new photo letter, delete and ensure deletion
  def test_photo_analyzer_exists
    analyzer = Importer::PhotoAnalyzer.new(@test_flickr_photo_exists)
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
    analyzer = Importer::PhotoAnalyzer.new(@test_flickr_photo_new)
    assert analyzer.char == 'z', 'Expecting char z'
    assert !analyzer.exists, 'This photo should not exist'
    assert analyzer.import, 'This photo needs to be imported'
    assert analyzer.tags.count == 2 ,'Tags should contain 2 elements'
    assert analyzer.tags.include?('tag1'), 'Tags should contain tag1'
    assert analyzer.tags.include?('tag3'), 'Tags should contain tag3'
    assert !analyzer.tags.include?('canon'), 'Tags should not contain canon'
    assert !analyzer.delete, 'This photo should not be deleted'
  end

  def test_photo_analyzer_should_update
    analyzer = Importer::PhotoAnalyzer.new(@test_flickr_photo_exists_new_date)
    assert analyzer.char == 'a', 'Expecting char a'
    assert analyzer.exists, 'This photo should exist'
    assert analyzer.import, 'This photo needs to be imported'
    assert analyzer.tags.count == 2 ,'Tags should contain 2 elements'
    assert analyzer.tags.include?('tag1'), 'Tags should contain tag1'
    assert analyzer.tags.include?('tag2'), 'Tags should contain tag2'
    assert !analyzer.tags.include?('canon'), 'Tags should not contain canon'
    assert !analyzer.delete, 'This photo should not be deleted'
  end

   def test_photo_analyzer_should_not_import
    analyzer = Importer::PhotoAnalyzer.new(@test_flickr_photo_new_bad_license)
    assert !analyzer.exists, 'This photo should not exist'
    assert !analyzer.import, 'This photo should not be imported'
    assert !analyzer.delete, 'This photo should not be deleted'
    assert analyzer.tags.nil? , 'Tags should not be processed'
    assert analyzer.char.nil?,  'Char should not be set'
  end

  def test_photo_analyzer_should_delete_changed_license
    analyzer = Importer::PhotoAnalyzer.new(@test_flickr_photo_exists_changed_license)
    assert analyzer.delete, 'This photo should be deleted'
    assert !analyzer.import, 'This photo should not be imported'
    assert analyzer.exists, 'This photo should exist'
    assert analyzer.tags.nil? , 'Tags should not be processed'
    assert analyzer.char.nil?,  'Char should not be set'
  end


end
