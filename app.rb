require 'bundler'
Bundler.require(:default)
require File.expand_path('../lib/import', __FILE__)
require File.expand_path('../lib/letter', __FILE__)
require File.expand_path('../lib/smash', __FILE__)
require 'resque_scheduler'
require 'slim'

configure do
  puts 'Initializing Mongoid ' + ENV['RACK_ENV']
  Mongoid.load!(File.dirname(__FILE__) + '/config/mongoid.yml')

  puts "Initializing redis " + ENV["REDISTOGO_URL"]
  redis_uri = URI.parse(ENV["REDISTOGO_URL"])

  puts "Initializing Resque"
  Resque.redis = Redis.new(:host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password)
  Resque.redis.namespace = "resque:lettersmashr"

  puts "Initializing Import Resque schedule"
  Resque.schedule = YAML.load_file(File.dirname(__FILE__)  + "/config/resque_schedule.yml")
end

set :slim, :pretty => true

get '/' do
  slim :index
end

# Converts a comma delimited tag http parameter into an array
def convert_tags(tags)
  if (tags.nil? || tags.empty?)
    return nil
  else
    tags_array = []
    if !tags.nil?
      tags_array = tags.split(',')
    end
    return tags_array
  end
end

# Smash a new image based on supplied letters and required tags.
#
# Default response is 202 "Accepted", meaning that "request has been accepted for processing, but the processing
# has not been completed" - See 10.2.3 202 Accepted http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
#
# The response body will contain an identifier for the smashed image currently being processed
post '/api/v1/smash/:text' do
  tags_array = convert_tags(params['tags'])

  # Enqueue the image for smashing...
  smashed_image_id = Smash.enqueue(params['text'], *tags_array)

  # If explicity requested, wait until processing has finished and redirect
  if !params.include?('redirect') && params['redirect'] == 'true'
    sleep(1) until !Smash.processing?(smashed_image_id)
    if Smash.exists?(smashed_image_id)
      redirect Smash.url(smashed_image_id)
    else
      halt(500)  # There was an error processing
    end
  end

  # By default, simply return the smashed_image_id as the response body
  status 202
  puts "Created: " + params['text']
  return smashed_image_id
end

# Returns a smashed image, or a notification that it is processing
get '/api/v1/image/:smashed_image_id' do
  smashed_image_id = params['smashed_image_id']

  processing = Smash.processing?(smashed_image_id)
  exists = Smash.exists?(smashed_image_id)

  # If unable to find the smashed image either processing or in storage, return 404
  if (!processing && !exists)
    halt(404)
  end

  # Create nil image object and popuate if it's not processing and it exists
  image = nil
  if (!processing && exists)
    smashed_image = Smash.image(smashed_image_id)
    image = {
      "url" => smashed_image.url,
      "width" => smashed_image.width,
      "height" => smashed_image.height
    }
  end

  {
    "ready" => !processing,
    "image" => image
  }.to_json
end

get '/api/v1/random_letter_photo/:letter' do
  content_type :json
  tags_array = convert_tags(params['tags'])
  Letter.random(params['letter'], *tags_array).to_json
end

# Generate a list of tags available for the supplied letters and required tags
get '/api/v1/tags' do

end

get '/import' do
  Resque.enqueue(Import)
end

get '/stats' do
  slim :stats, locals: { :letterPhotoTotalCount => Letter::Photo.count,
    :aLetterPhotoCount => Letter::Photo.where(:char => 'a').count,
    :bLetterPhotoCount => Letter::Photo.where(:char => 'b').count,
    :cLetterPhotoCount => Letter::Photo.where(:char => 'c').count,
    :dLetterPhotoCount => Letter::Photo.where(:char => 'd').count,
    :eLetterPhotoCount => Letter::Photo.where(:char => 'e').count,
    :fLetterPhotoCount => Letter::Photo.where(:char => 'f').count,
    :gLetterPhotoCount => Letter::Photo.where(:char => 'g').count,
    :hLetterPhotoCount => Letter::Photo.where(:char => 'h').count,
    :iLetterPhotoCount => Letter::Photo.where(:char => 'i').count,
    :jLetterPhotoCount => Letter::Photo.where(:char => 'j').count,
    :kLetterPhotoCount => Letter::Photo.where(:char => 'k').count,
    :lLetterPhotoCount => Letter::Photo.where(:char => 'l').count,
    :mLetterPhotoCount => Letter::Photo.where(:char => 'm').count,
    :nLetterPhotoCount => Letter::Photo.where(:char => 'n').count,
    :oLetterPhotoCount => Letter::Photo.where(:char => 'o').count,
    :pLetterPhotoCount => Letter::Photo.where(:char => 'p').count,
    :qLetterPhotoCount => Letter::Photo.where(:char => 'q').count,
    :rLetterPhotoCount => Letter::Photo.where(:char => 'r').count,
    :sLetterPhotoCount => Letter::Photo.where(:char => 's').count,
    :tLetterPhotoCount => Letter::Photo.where(:char => 't').count,
    :uLetterPhotoCount => Letter::Photo.where(:char => 'u').count,
    :vLetterPhotoCount => Letter::Photo.where(:char => 'v').count,
    :xLetterPhotoCount => Letter::Photo.where(:char => 'x').count,
    :yLetterPhotoCount => Letter::Photo.where(:char => 'y').count,
    :zLetterPhotoCount => Letter::Photo.where(:char => 'z').count,
  }
end



