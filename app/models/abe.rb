# lastmod  8 gennaio 2012  - has_many :items (meglio non usarne i metodi)
#                            def current_libraries
# lastmod  4 gennaio 2012
# lastmod 27 dicembre 2011 - def get_libraries
# lastmod 16 dicembre 2011
# lastmod 15 dicembre 2011

class Abe < ActiveRecord::Base
  set_primary_keys :bib_entry_id,:entity_id
  belongs_to :bib_entry
  belongs_to :entity
  has_many :items, :foreign_key=>[:bib_entry_id,:entity_id]

  def get_libraries
    e=self.entity
    be=self.bib_entry
    # puts "recupero biblioteche per #{self.entity.name} - #{self.bib_entry.source_oid}"
    url="http://#{e.baseurl}/#{e.itempath}"
    url.sub!('__%%__',be.source_oid)
    # puts "url: '#{url}'"
    pnam='estrai_biblioteche'
    eval("undef #{pnam}") if self.respond_to?(pnam)
    eval(e.procedures) if !e.procedures.blank?
    x=self.respond_to?(pnam)
    if x
      puts "posso chiamare estrai_biblioteche per #{e.name}"
      data=Entity.fetch_web_page(url)
      fd=File.open("/tmp/testpage.html",'w')
      fd.write(data)
      fd.close
      # data=File.read("/tmp/testpage.html")
      l=send(pnam,data,self)
      # puts "x: #{x} - l=#{l}"
      return l
    else
      puts "non posso chiamare #{pnam} per #{e.name}"
      return []
    end
  end

  def current_libraries
    Library.find_by_sql(%Q{
      SELECT l.* FROM items i JOIN libraries l ON(i.library_id=l.id)
       WHERE bib_entry_id = #{self.bib_entry_id} AND i.entity_id=#{self.entity_id};
    })
  end

end
