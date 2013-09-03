require_relative 'test_helper'
require_relative '../models/tag_list'

class TagListTest < MiniTest::Unit::TestCase

  def setup
    create_test_data() #see test_helper.rb
  end

  def teardown
    delete_test_data()
  end

  def test_tag_list
    # Find by text
    tag_list = TagList.new('ab').tags
    assert tag_list.length == 2, 'Wrong length ' + tag_list.length.to_s + ', expecting 4'
    assert tag_list.include?('tag2')
    assert tag_list.include?('tag4')

    tag_list = TagList.new('b').tags
    assert tag_list.length == 3
    assert tag_list.include?('tag2')
    assert tag_list.include?('tag4')
    assert tag_list.include?('tag5')

    # Find by text and start_with
    tag_list = TagList.new('ab', [], 'tag').tags
    assert tag_list.length == 2, 'Wrong length ' + tag_list.length.to_s + ', expecting 2'
    assert tag_list.include?('tag2')
    assert tag_list.include?('tag4')

    tag_list = TagList.new('ab', [], 'tag4').tags
    assert tag_list.length == 1, 'Wrong length ' + tag_list.length.to_s + ', expecting 1'
    assert tag_list.include?('tag4')

    # Find by text, existing tag and start_with
    tag_list = TagList.new('b', ['tag5'], 'tag').tags
    assert tag_list.length == 2, 'Wrong length ' + tag_list.length.to_s + ', expecting 2'
    assert tag_list.include?('tag2')
    assert tag_list.include?('tag4')

    tag_list = TagList.new('b', ['tag2', 'tag5'], 'tag4').tags
    assert tag_list.length == 1, 'Wrong length ' + tag_list.length.to_s + ', expecting 1'
    assert tag_list.include?('tag4')

    tag_list = TagList.new('ab', ['tag2'], 'tag').tags
    assert tag_list.length == 1, 'Wrong length ' + tag_list.length.to_s + ', expecting 1'
    assert tag_list.include?('tag4')
  end
end