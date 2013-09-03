# This class represents a smashed image of LetterImage objects, forming a word
class SmashedImage
  include Mongoid::Document
  store_in collection: 'smashed_images'

  field :_id, type: String, default: ->{ smashed_image_id }   # Custom id field: use smashed_image_id
  field :smashed_image_id, type: String                       # Encoded id
  field :url, type: String                                    # S3 URL
  field :text, type: String                                   # Text of image
  field :photo_ids, type: Array                               # Array of Letter::Photo ids
  field :tags, type: Array                                    # Array of tags used to create this image
  field :created, type: DateTime, default: ->{ DateTime.now } # Timestamp
  field :accessed, type: Integer, default: 0                  # Access count for this image
  field :width, type: Integer                                 # Width of smashed image
  field :height, type: Integer                                # Height of smashed image

  # After an upsert make sure the this image id is removed from in progress set
  after_upsert do |document|
    puts "After insert: " + document.text
    Resque.redis.srem(ImageSmasher.worker_in_progess_key, document.smashed_image_id)
  end
end