require 'bundler'
Bundler.require(:default)
require File.expand_path('../lib/import', __FILE__)

configure do
  puts "Initializing redis " + ENV["REDISTOGO_URL"]
  uri = URI.parse(ENV["REDISTOGO_URL"])

  puts 'Initializing Mongoid ' + ENV['RACK_ENV']
  Mongoid.load!(File.dirname(__FILE__) + '/config/mongoid.yml')

  puts "Initializing Resque"
  Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  Resque.redis.namespace = "resque:lettersmashr_import"
  set :redis, ENV["REDISTOGO_URL"]

  puts "Initializing Import Resque schedule"
  Resque.schedule = YAML.load_file(File.dirname(__FILE__)  + "/config/resque_schedule.yml")
end

get '/import' do
  Resque.enqueue(Import)
end
