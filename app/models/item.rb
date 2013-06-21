# lastmod  8 gennaio 2012
# lastmod  4 gennaio 2012

class Item < ActiveRecord::Base
  set_primary_keys [:bib_entry_id, :entity_id, :library_id]
  belongs_to :bib_entry
  belongs_to :entity
  belongs_to :library

  belongs_to :abe, :foreign_key=>[:bib_entry_id,:entity_id]
end


