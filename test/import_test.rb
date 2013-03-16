require 'minitest/spec'
require 'minitest/autorun'
require File.dirname(__FILE__) + '/../lib/import/flickr_api'
require File.dirname(__FILE__) + '/../lib/import/one_letter_group_pool'

describe OneLetterGroupPool do
  it 'can be initialized' do
    OneLetterGroupPool.new
  end

  it 'can load photos' do
    pool = OneLetterGroupPool.new
    photos = pool.get_photos(Date.today)
    assert photos.length.nil?
  end
end

