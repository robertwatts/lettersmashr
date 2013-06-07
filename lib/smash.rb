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
    str.each_char {|c| print c, ' ' }

    # Create an array of photo urls
    # TODO Make flickr url choice configurable
    photo_urls = Array.new
    str.each_char { |letter|
      photo_urls << Letter.random(letter, *required_tags).flickr_url_s
    }

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
              "image_identifier" => "foo"
            }
        }
      ]
    })
    # TODO Do something with response
    puts blitline_service.post_jobs
  end

end
