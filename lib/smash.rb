require 'resque/errors'
require 'blitline'
require 'base64'
require 'multi_json'
require File.expand_path('../letter', __FILE__)

# Create new images from given
module Smash

  class << self
    # Checks if a SmashedImage is currently  processing
    # @param smashed_image_id [String] the smashed_image_id of a SmashedImage
    # @return [Boolean] true if being worked on, false if not
    def processing?(smashed_image_id)
      return Resque.redis.sismember(ImageSmasher.worker_in_progess_key, smashed_image_id)
    end

    # Checks if a SmashedImage exists
    # @param smashed_image_id [String] the smashed_image_id of a SmashedImage
    # @return [Boolean] true if exists, false if not
    def exists?(smashed_image_id)
      return SmashedImage.where(:_id => smashed_image_id).exists?
    end

    # Returns a url of a SmashedImage
    # @param smashed_image_id [String] the smashed_image_id of a SmashedImage
    # @return [String] the url of the smashed image
    def image(smashed_image_id)
      SmashedImage.find(smashed_image_id)
    end

    # Starts smashing a new image based on the current text and tags
    #
    # @param text [String] the inbound string
    # @param tags [Array<String>] an optional array of tags each letter must contain at least one of
    # @return [String] an smashed_image_id
    def enqueue(text, *required_tags)
      letter_photo_urls = Array.new
      letter_photo_ids = Array.new
      text.each_char { |letter|
        puts "getting letter"
        puts letter
        puts required_tags
        letter_photo = Letter.random(letter, *required_tags)
        letter_photo_urls << letter_photo.flickr_url_s                              # TODO make configurable
        letter_photo_ids << letter_photo._id
      }

      # Create smashed_image_id by base64 encoding the ids and requireds tags in a url safe way
      smashed_image_id = Base64.urlsafe_encode64(letter_photo_ids.join(',') + "|" + required_tags.join(','))

      # Create the ImageSmasherConfig struct for this job
      image_smasher_config = ImageSmasherConfig.new(smashed_image_id, letter_photo_ids, letter_photo_urls, text)

      # Enqueue the job with Resque and return the smashed_image_id
      Resque.enqueue(ImageSmasher, image_smasher_config)
      return smashed_image_id
    end
  end

  # SmashedImage class, a mongoid document
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
  end

  # Config struct for the ImageSmasher
  ImageSmasherConfig = Struct.new(:smashed_image_id, :letter_photo_ids, :letter_photo_urls, :text)

  # Resque worker
  class ImageSmasher
    @queue = :smash
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

    # Key used to store in-progress images
    def self.worker_in_progess_key
      "in_progess"
    end

    # Process the photo_array
    def process_image
      # Add this id to the in progress set
      Resque.redis.sadd(ImageSmasher.worker_in_progess_key, @config['smashed_image_id'])

      begin
        # Get first and array of the rest
        # TODO Check for length!
        src_photo_url = @config['letter_photo_urls'][0]
        other_photo_urls = @config['letter_photo_urls'].slice(1, @config['letter_photo_urls'].length).join(",")

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
          photo_ids: @config['letter_photo_ids'],
          url: results['images'][0]['s3_url'],
          width: results['images'][0]['meta']['width'].to_i,
          height: results['images'][0]['meta']['height'].to_i
        ).upsert
      ensure
        # Whatever happens, remove this image id from the in progress set
        Resque.redis.srem(ImageSmasher.worker_in_progess_key, @config['smashed_image_id'])
      end
    end
  end
end
