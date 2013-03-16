require 'mongoid'

class PhotoLetter
  include Mongoid::Document

  field :char, :type => String
  field :capital, :type => Boolean, :default => :char.upcase
  field :tags, :type => Array
  field :imported, :type => DateTime, :default => DateTime.now

  field :flickr_id, :type => Integer
  field :flickr_license, :type => Integer
  field :flickr_owner, :type => String
  field :flickr_last_update, :type => DateTime

end