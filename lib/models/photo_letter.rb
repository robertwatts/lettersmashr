require 'mongoid'

class PhotoLetter
  include Mongoid::Document

  # Custom id field: use flickr_id
  field :_id, type: Integer, default: ->{ flickr_id }

  field :char, type: String
  field :capital, type: Boolean, default: ->{char.upcase}
  field :tags, type: Array
  field :imported, type: DateTime, default: DateTime.now

  field :flickr_id, type: Integer
  field :flickr_license, type: Integer
  field :flickr_owner, type: String
  field :flickr_last_update, type: DateTime

  field :flickr_url_sq, type: String #75x75
  field :flickr_url_t, type: String #100x100
  field :flickr_url_s, type: String #240x240
  field :flickr_url_q, type: String #150x150

end