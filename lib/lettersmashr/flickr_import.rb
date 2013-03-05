require 'flickraw'

FlickRaw.api_key = "edd1fdca15b5740203fd7e4b7d3ffbb0"
FlickRaw.shared_secret= "c041f8188aa39723"

info = flickr.photos.getInfo(:photo_id => "8523432283")

puts info.to_hash.to_json
puts info.tags.to_hash.to_json









