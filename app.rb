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

get '/import' do
  Resque.enqueue(Import)
end
