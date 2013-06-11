require 'resque/errors'
require 'blitline'
require 'base64'
require 'multi_json'
require File.expand_path('../letter', __FILE__)

# Create new images from given
module Smash

  class << self
    # Resque in progress redis key
    # Encdoe an image id for an Array of Letter:Photo ids
    # @return [String] an the array of ids, base64 encoded
    def encode_smashed_image_id(photo_letter_ids, *required_tags)
      return Base64.urlsafe_encode64(photo_letter_ids.join(',') + "|" + required_tags.join(','))
    end

    # Returns an image url for a given id
    # Will wait for a job to finish, if one is in progress
    # @param smashed_image_id [String] the smashed_image_id of a SmashedImage
    # @return [String] an image_url, or nil if not available
    def img_url(smashed_image_id)
      begin
        # Check if a processing job is in progress
        job_in_prog = Resque.redis.sismember(worker_in_progess_key, smashed_image_id)
        # If a processing job is not in progress then check for a SmashedImage
        if !job_in_prog && SmashedImage.where(:_id => smashed_image_id).exists?
          processed_image = SmashedImage.find(smashed_image_id).url
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
    # @return [String] an smashed_image_id
    def process_img(text, *required_tags)
      letter_photo_urls = Array.new
      letter_photo_ids = Array.new
      text.each_char { |letter|
        letter_photo = Letter.random(letter, *required_tags)
        letter_photo_urls << letter_photo.flickr_url_s                              # TODO make configurable?
        letter_photo_ids << letter_photo._id
      }

      smashed_image_id = encode_smashed_image_id(letter_photo_ids, *required_tags)  # Create smashed_image_id
      image_worker_config = {
        "smashed_image_id" => smashed_image_id,
        "text" => text,
        "letter_photo_urls" => letter_photo_urls,
        "letter_photo_ids" => letter_photo_ids
      }

      Resque.enqueue(ImageWorker, image_worker_config)                              # Enqueue a new job
      return smashed_image_id                                                       # Return smashed_image_id
    end

    def worker_in_progess_key
      return "in_progess"
    end
  end

  # SmashedImage class, a mongoid document
  class SmashedImage
    include Mongoid::Document
    store_in collection: "processed_image"

    field :_id, type: Integer, default: ->{ smashed_image_id }  # Custom id field: use smashed_image_id
    field :smashed_image_id, type: String                       # Encoded id
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
    attr_reader :config

    def initialize(config)
      @config = config
    end

    # Resque execution method
    def self.perform(config)
      (new config).process_image
    rescue Resque::TermException
      Resque.enqueue(self)
    end

    # Process the photo_array
    def process_image
      # Add this id to the in progress set
      Resque.redis.sadd(Smash.worker_in_progess_key, @processed_image_id)

      begin
        # Get first and array of the rest
        # TODO Check for length!
        src_photo_url = @config["letter_photo_urls"][0]
        other_photo_urls = @config["letter_photo_urls"].slice(1, @config["letter_photo_urls"].length).join(",")

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
                "image_identifier" => @config['smashed_image_id']
              }
            }
          ]
        })

        blitline_job = blitline_service.post_jobs                 # Post job to Blitline
        job_id = blitline_job['results'][0]['job_id']             # Get job_id from Blitline

        # Poll BlitLine until job is complete
        # TODO replace with Postback!
        # TODO Check for bad response
        response = Net::HTTP.get('cache.blitline.com', '/listen/' + job_id)
        data = MultiJson.load(response)
        results = MultiJson.load(data['results'])                 # Double decode required by inconsistent Blitline JSON

        # Save SmashedImage
        SmashedImage.new(
          smashed_image_id: @config['smashed_image_id'],
          text: @config['text'],
          photo_ids: @config['letter_photo_urls'],
          url: results['images'][0]['s3_url'],
          width: results['images'][0]['width'],
          height: results['images'][0]['height']
        ).upsert

        puts "Created SmashedImage: " + @config['text']
      ensure
        # Whatever happens, remove this image id from the in progress set
        Resque.redis.srem(Smash.worker_in_progess_key, @processed_image_id)
      end
    end
  end
end
