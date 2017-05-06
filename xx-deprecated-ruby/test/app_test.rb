require File.dirname(__FILE__) +  '/test_helper'
require 'minitest/autorun'
require 'rack/test'
require File.dirname(__FILE__) +  '/../app'

class AppTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def setup
    create_test_data() #see test_helper.rb
  end

  def teardown
    delete_test_data()
  end

  def app
    Sinatra::Application
  end

  # def test_convert_tags
  #   assert convert_tags(nil) == nil
  #   assert convert_tags([]) == nil
  #   assert convert_tags(['tag1']) == ['tag1']
  #   assert convert_tags('tag1,tag2') == ['tag1', 'tag2']
  # end

  # def test_smash_and_grab
  #   post '/api/v1/smash/ab?tags=tag4'
  #   assert last_response.status == 202, 'Response should be 202, instead: ' + last_response.status.to_s

  #   smashed_image_id = last_response.body
  #   assert Base64.urlsafe_decode64(smashed_image_id) == '2,3|tag4', 'Returned ID not decoding as expected'

  #   get '/api/v1/image/' + smashed_image_id
  #   assert last_response.status == 200, 'Response status is not 200: ' + last_response.status.to_s
  # end

end
