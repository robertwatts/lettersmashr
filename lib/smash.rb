require 'resque/errors'
require 'blitline'
require 'base64'
require File.expand_path('../letter', __FILE__)

# Create new images from given
module Smash

  class << self
    # Resque in progress redis key
    def worker_in_progess_key
     "in_progess"
    end

    # Encdoe an image id for an Array of Letter:Photo ids
    # @return [String] an the array of ids, base64 encoded
    def encode_img_id(photo_letter_ids, *required_tags)
      return Base64.urlsafe_encode64(photo_letter_ids.join(',') + "|" + required_tags.join(','))
    end

    # Returns an image url for a given id
    # Will wait for a job to finish, if one is in progress
    # @param enc_id [String] the enc_id of a ProcessedImage
    # @return [String] an image_url, or nil if not available
    def img_url(enc_id)
      begin
        # Check if a processing job is in progress
        job_in_prog = Resque.redis.sismember(worker_in_progess_key, enc_id)
        # If a processing job is not in progress then check for a ProcessedImage
        if !job_in_prog && ProcessedImage.where(:_id => enc_id).exists?
          processed_image = ProcessedImage.find(enc_id).url
        end
      end while job_in_prog # Keep trying until the job finishes

      # If the image can not be found then create a new one
      if processed_image.nil?
        return nil
      end

      return processed_image.url
    end

    # Create an array of Letter::Photo objects from a given string
    #
    # @param text [String] the inbound string
    # @param tags [Array<String>] an optional array of tags each Letter::Photo must contain at least one of
    # @return [String] an enc_id
    def process_img(text, *required_tags)
      letter_photos = Array.new
      letter_photo_ids = Array.new
      text.each_char { |letter|
        letter_photo = Letter.random(letter, *required_tags)
        letter_photos << letter_photo
        letter_photo_ids << letter_photo._id
      }

      processed_image_id = encode_img_id(letter_photo_ids, *required_tags)    # Create enc_id
      Resque.enqueue(ImageWorker, processed_image_id, letter_photos, text)    # Enqueue a new job
      return processed_image_id                                               # Return enc_id
    end


  end

  # ProcessedImage class, a mongoid document
  class ProcessedImage
    include Mongoid::Document
    store_in collection: "processed_image"

    field :_id, type: Integer, default: ->{ enc_id }  # Custom id field: use enc_id
    field :enc_id, type: String                       # Encoded id
    field :url, type: String                          # S3 URL
    field :text, type: String                         # Text of image
    field :photo_ids, type: Array                     # Array of Letter::Photo ids
    field :created, type: DateTime, default: ->{ DateTime.now }
    field :accessed, type: Integer, default: 0        # Access count for this image
    field :width, type: Integer
    field :height, type: Integer
  end

  # Resque worker
  class ImageWorker
    @queue = :image_process
    attr_reader :processed_image_id, :photo_array, :text

    def initialize(processed_image_id, photo_array, text)
      @processed_image_id = processed_image_id
      @photo_array = photo_array
      @text = text
    end

    # Resque execution method
    def self.perform(processed_image_id, photo_array, text)
      (new processed_image_id, photo_array, text).process_image
    rescue Resque::TermException
      Resque.enqueue(self)
    end

    # Process the photo_array
    def process_image
      puts "Processing image " + @text
      # Create an array of photo urls
      # TODO Make flickr url choice configurable
      photo_urls = Array.new
      photo_ids = Array.new
      photo_array.each { |photo_letter|
        photo_urls << photo_letter.flickr_url_s
        photo_ids << photo_letter._id
      }

      # Add this id to the in progress set
      Resque.redis.sadd(worker_in_progess_key, @processed_image_id)

      begin
        # Get first and array of the rest
        # TODO Check for length!
        src_photo_url = photo_urls[0]
        other_photo_urls = photo_urls.slice(1, photo_urls.length).join(",")

        # Send request to Blitline
        blitline_app_id = ENV['BLITLINE_APPLICATION_ID']
        blitline_service = Blitline.new
        blitline_service.add_job_via_hash({
          "application_id" => ENV['BLITLINE_APPLICATION_ID'],
          "src" => src_photo_url,
          "functions" => [
            {
              "name" => "append",
              "params" => {
                "other_images" => other_photo_urls,
                "vertical" => false
              },
              "save" => {
                "image_identifier" => @processed_image_id
              }
            }
          ]
        })

        # Get job id from Blitline Response
        job_id = blitline_service.post_jobs.images[0].job_id

        # Poll BlitLine until job is complete
        # TODO replace with Postback!
        response = Net::HTTP.get('cache.blitline.com', "listen/{job_id}")
        data = JSON.parse(response)

        # TODO Check for bad response

        # # Save ProcessedImage
        Photo.new(
          enc_id: processed_image_id,
          text: text,
          photo_ids: photo_letter_ids,
          url: data.images[0].s3_url,
          width: data.images[0].width,
          height: data.images[0].height
        ).upsert

      ensure
        Resque.redis.srem(Smash.worker_in_progess_key, @processed_image_id)
      end
    end
  end
end
