# This class represents a letter that has been uploaded to the Flickr One Letter Pool
class Letter
  include Mongoid::Document
  include Mongoid::TagsArentHard
  store_in collection: "letters"

  field :_id, type: Integer, default: ->{ flickr_id }                   # Custom id field: use flickr_id
  field :random, type: BigDecimal, default: ->{ Random.new.rand() }     # Used to select random documents

  field :char, type: String
  field :capital, type: Boolean, default: ->{char.upcase}

  taggable_with :tags, seperator: ' '

  field :imported, type: DateTime, default: ->{ DateTime.now}

  field :flickr_id, type: Integer
  field :flickr_license, type: Integer
  field :flickr_owner, type: String
  field :flickr_last_update, type: DateTime

  field :flickr_url_sq, type: String #75x75
  field :flickr_url_t, type: String #100x100
  field :flickr_url_s, type: String #240x240

  # Index the char, tags and random in the same index, run in background
  index({ char: 1, random: 1 }, { unique: false, background: true })

end