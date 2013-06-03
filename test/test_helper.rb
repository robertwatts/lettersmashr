require 'minitest/autorun'
Bundler.require(:default, :test)

# Set up Mongoid
puts 'Initializing Mongoid ' + ENV['RACK_ENV']
Mongoid.load!(File.dirname(__FILE__) + '/../config/mongoid.yml')
