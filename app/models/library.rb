# lastmod  4 gennaio 2012
class Library < ActiveRecord::Base
  belongs_to :entity
  has_many :items
end

