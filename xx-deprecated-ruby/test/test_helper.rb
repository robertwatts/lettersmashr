require 'minitest/autorun'
Bundler.require(:default, :test)

require_relative 'test_photo_collector'
require_relative '../models/letter'
require_relative '../tools/importer'

# Set up Mongoid
puts 'Initializing Mongoid ' + ENV['RACK_ENV']
Mongoid.load!(File.dirname(__FILE__) + '/../config/mongoid.yml')

puts "Initializing redis " + ENV["REDISTOGO_URL"]
redis_uri = URI.parse(ENV["REDISTOGO_URL"])

puts "Initializing Resque"
Resque.redis = Redis.new(:host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password)
Resque.redis.namespace = "resque:lettersmashr"
Resque.inline = true # Make resque run synchronously during tests

# Creates test photo data, for use by tests
def create_test_data
  importer = Importer.new(TestPhotoCollector.new)
  importer.import
end

def delete_test_data
  Letter.delete_all
end
