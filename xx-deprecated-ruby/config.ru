require './app'
require 'resque/server'

$stdout.sync = true

run Rack::URLMap.new \
  "/"       => Sinatra::Application,
  "/resque" => Resque::Server.new
