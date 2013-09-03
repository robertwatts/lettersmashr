require 'bundler'
Bundler.require(:default)
require 'resque_scheduler'
require 'slim'
require 'json'

require_relative 'models/letter'
require_relative 'import'

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

# Smash a new image based on supplied letters and required tags.
#
# Default response is 202 "Accepted", meaning that "request has been accepted for processing, but the processing
# has not been completed" - See 10.2.3 202 Accepted http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
#
# The response body will contain an identifier for the smashed image currently being processed
post '/api/v1/smash/:text' do
  # Enqueue the image for smashing...
  smashed_image_id = Smash.enqueue(params['text'], params['tags'])

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


get '/api/v1/smash_letters/:letter' do
  content_type :json
  SmashedLetters.new(params['letter'], params['tags']).to_json
end


# Return a single random photo for a given letter
get '/api/v1/random_letter/:letter' do
  content_type :json
  RandomLetter.new(params['letter'], params['tags'], params['excluded_ids']).to_json
end

# Generate a list of tags available for the supplied letters and required tags
get '/api/v1/tags' do
  content_type :json
  TagList.new(params['text'], params['also_tagged_with'], params['start_with']).to_json
end

get '/import' do
  Resque.enqueue(Import)
end

get '/stats' do
  slim :stats, locals: { :letterPhotoTotalCount => LetterImage.count,
    :aLetterPhotoCount => LetterImage.where(:char => 'a').count,
    :bLetterPhotoCount => LetterImage.where(:char => 'b').count,
    :cLetterPhotoCount => LetterImage.where(:char => 'c').count,
    :dLetterPhotoCount => LetterImage.where(:char => 'd').count,
    :eLetterPhotoCount => LetterImage.where(:char => 'e').count,
    :fLetterPhotoCount => LetterImage.where(:char => 'f').count,
    :gLetterPhotoCount => LetterImage.where(:char => 'g').count,
    :hLetterPhotoCount => LetterImage.where(:char => 'h').count,
    :iLetterPhotoCount => LetterImage.where(:char => 'i').count,
    :jLetterPhotoCount => LetterImage.where(:char => 'j').count,
    :kLetterPhotoCount => LetterImage.where(:char => 'k').count,
    :lLetterPhotoCount => LetterImage.where(:char => 'l').count,
    :mLetterPhotoCount => LetterImage.where(:char => 'm').count,
    :nLetterPhotoCount => LetterImage.where(:char => 'n').count,
    :oLetterPhotoCount => LetterImage.where(:char => 'o').count,
    :pLetterPhotoCount => LetterImage.where(:char => 'p').count,
    :qLetterPhotoCount => LetterImage.where(:char => 'q').count,
    :rLetterPhotoCount => LetterImage.where(:char => 'r').count,
    :sLetterPhotoCount => LetterImage.where(:char => 's').count,
    :tLetterPhotoCount => LetterImage.where(:char => 't').count,
    :uLetterPhotoCount => LetterImage.where(:char => 'u').count,
    :vLetterPhotoCount => LetterImage.where(:char => 'v').count,
    :xLetterPhotoCount => LetterImage.where(:char => 'x').count,
    :yLetterPhotoCount => LetterImage.where(:char => 'y').count,
    :zLetterPhotoCount => LetterImage.where(:char => 'z').count,
  }
end



