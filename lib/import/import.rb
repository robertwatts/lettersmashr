#!/usr/bin/env ruby
=begin
import.rb: Imports image metadata from the "One Letter" flickr group pool
=end

require 'flickraw'
require 'configurability'
require 'mongoid'

# Set up
puts 'Loading mongoid environment development'
Mongoid.load!('config/mongoid.yml', :development)

# Setup Flickr credentials
import_config = Configurability::Config.load('config/import.yml')
FlickRaw.api_key = import_config.flickr.apiKey
FlickRaw.shared_secret= import_config.flickr.sharedSecret
flickr.access_token = import_config.flickr.token
flickr.access_secret = import_config.flickr.secret
puts "You are now authenticated as #{flickr.test.login.username}"

# Find the One Letter group from the user's group pool list
available_group_pool = flickr.groups.pools.getGroups
one_letter_group_pool = nil
available_group_pool.each { |group|
  if group.name == 'One Letter'
    one_letter_group_pool = group
  end
}

# Process the One Letter group pool, or exit if it cannot be found
if one_letter_group_pool.nil?
  abort('Unable to find One Letter group, exiting')
end

photoCount = one_letter_group_pool.photos.to_i
pageCount = photoCount / 500 + 1
puts "Processing #{one_letter_group_pool.name} (#{one_letter_group_pool.nsid}) with #{photoCount} photos"

# Process every photo in the pool, inserting into Mongo as we go
1.upto(pageCount) {
    |page|
  puts "Processing page #{page} of #{pageCount}"
  photos = flickr.groups.pools.getPhotos(:group_id => one_letter_group_pool.id, per_page: '500', :page => page)
  photos.each {
      |photo|
    puts photo.id + ' ' + photo.title
  }
}
