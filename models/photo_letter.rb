require 'mongoid'

class PhotoLetter
  include Mongoid::Document

  field :letter, :type => String
  field :capital, :type => boolean
  field :originalFormat, :type => String
  field :owner, :type => PhotoOwner
  field :description, :type => String
  field :theme, :type => String[]
  field :colours, :type => String[]

end