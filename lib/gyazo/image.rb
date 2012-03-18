module Gyazo; end

class Gyazo::Image
  include Mongoid::Document
  include Mongoid::Timestamps

  field :gyazo_hash, :type => String
  field :body, :type => BSON::Binary
  validates_uniqueness_of :hash

  index [[:created_at, Mongo::DESCENDING]], :sparse => true
end
