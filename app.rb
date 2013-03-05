require 'sinatra'
require 'models/photo_letter'
require 'mongoid'

configure do
  Mongoid.configure do |config|
    name = "fsg_ident"
    host = "localhost"
    config.master = Mongo::Connection.new.db(name)
  end
end

before do
  content_type :json
end

# render a word as a picture based on an input string
get '/photoword/:word' do
  letterword = WordMaker.makeWord(params[:word])
  if user
    user.to_json
  else
    error 500, {:error => "Unable to create word " + params[:word]}.to_json
  end
end

#Find available themes, types, etc by word
get '/availability' do


end