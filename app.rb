require 'bundler'
Bundler.require(:default)
require File.expand_path('../lib/import', __FILE__)
require 'resque_scheduler'

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

# Smash a new image based on supplied letters and required tags.
#
# Default response is 202 "Accepted", meaning that "request has been accepted for processing, but the processing
# has not been completed" - See 10.2.3 202 Accepted http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
#
# The response body will contain an identifier for the smashed image currently being processed
post '/api/v1/smash/:text' do
  status 202
  tags = params['tags']
  tags_array = []
  if !tags.nil?
    tags_array = tags.split(',')
  end
  Smash.enqueue(params['text'], tags_array)
end

# Check the processing status of a smashed image.
#
# If the smashed image is not ready then the method will respond with 200 Successful, to indicate that a successful
# status check has occurred.  The response body will also contain a pending notification.
#
# However, if the smashed image is ready then method will respond with 303 See Other with Location header pointing
# at the URL for the smashed image.  The response body will contain metadata about the image, such as height and width.
# See http://stackoverflow.com/questions/5079367/use-http-status-202-for-asynchronous-operations
get '/api/v1/status/:smashed_image_id' do
  smashed_image_id = params['smashed_image_id']
  if Smash.processing?(smashed_image_id)
    status 200
  elsif Smash.exists?(smashed_image_id)
    status 303
    url = Smash.url(smashed_image_id)
  else
    status 404
  end
end

# Generate a list of tags available for the supplied letters and required tags
get '/api/v1/tags' do

end



