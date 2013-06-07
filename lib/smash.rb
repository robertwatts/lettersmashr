require 'blitline'
require File.expand_path('../letter', __FILE__)

# Create new images from given
module Smash

   # Create an array of Letter::Photo objects from a given string
  #
  # @param str [String] the inbound string
  # @param tags [Array<String>] an optional array of tags each Letter::Photo must contain at least one of
  # @return [String] a URL
  def self.create_img(str, *required_tags)
    # Create array of photo urls
    puts "Converting " + str

    str.each_char {|c| print c, ' ' }


    photo_urls = Array.new
    str.each_char { |letter|
      photo_urls << Letter.random(letter, *required_tags).flickr_url_s
    }

    src_photo_url = photo_urls[0]
    other_photo_urls = photo_urls.slice(1, photo_urls.length).join(",")

    blitline_app_id = ENV['BLITLINE_APPLICATION_ID']
    puts "App id " + blitline_app_id

    blitline_service = Blitline.new
    blitline_service.add_job_via_hash({
      "application_id" => "7rQOE3emCXfncM5smSAS87w",
      "src" => src_photo_url,
      "functions" => [
        {
          "name" => "append",
          "params" => {
              "other_images" => other_photo_urls,
              "vertical" => false
            },
            "save" => {
              "image_identifier" => "foo"
            }
        }
      ]
    })
    puts blitline_service.post_jobs
  end

end
