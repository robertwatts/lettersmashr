require File.dirname(__FILE__) +  '/test_helper'
require 'minitest/autorun'
require 'rack/test'
require File.dirname(__FILE__) +  '/../app'

class AppTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_smash
    post '/api/v1/smash/ab?tags=tag4'
    assert last_response.ok?
    assert Base64.urlsafe_decode64(last_response.body) == '2,3|tag4'
  end

end
