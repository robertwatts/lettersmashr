require 'sinatra'
require 'mongoid'
require_relative 'lib/models/photo_letter'

# render a word as a picture based on an input string
get '/' do
  'Hello visitor '
end
