require File.dirname(__FILE__) +  '/test_helper'
require 'minitest/autorun'
require 'rack/test'
require File.dirname(__FILE__) +  '/../app'

class AppTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def setup
    create_test_photo_data() #see test_helper.rb
  end

  def teardown
    delete_test_photo_data()
  end

  def app
    Sinatra::Application
  end

  def test_smash_and_status
    post '/api/v1/smash/ab?tags=tag4'
    assert last_response.status == 202, 'Response should be 202, instead: ' + last_response.status.to_s

    smashed_image_id = last_response.body
    assert Base64.urlsafe_decode64(smashed_image_id) == '2,3|tag4', 'Returned ID not decoding as expected'

    get '/api/v1/status/' + smashed_image_id

    while last_response.status == 200 do
      puts "Waiting for redirect"
    end

    assert last_response.status == 302, 'Response status is not a 302 redirect: ' + last_response.status.to_s
    puts last_response.headers['Location']
    assert !last_response.headers['Location'].nil?


  end

end
