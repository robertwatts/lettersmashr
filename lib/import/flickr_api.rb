require 'configurability'
require 'flickraw'
require 'singleton'

# Singleton that holds a configured instance of FlickRaw::Flickr class
class FlickrApi
  include Singleton

  attr_reader :api

  def initialize
    import_config = Configurability::Config.load(File.dirname(__FILE__) + '/../../config/import.yml')
    FlickRaw.api_key = import_config.flickr.apiKey
    FlickRaw.shared_secret= import_config.flickr.sharedSecret
    flickr.access_token = import_config.flickr.token
    flickr.access_secret = import_config.flickr.secret
    puts "You are now authenticated as #{flickr.test.login.username}"
    @api = flickr
  end

end