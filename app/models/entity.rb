# lastmod 19 gennaio 2012
# lastmod  4 gennaio 2012   - has_many :libraries - def add_libraries - has_many :items
# lastmod 21 dicembre 2011  - def extract_oid_from_url
# lastmod 18 dicembre 2011
# lastmod 16 dicembre 2011
# lastmod 15 dicembre 2011

class Entity < ActiveRecord::Base
  has_many :bib_entries
  has_many :abes
  has_many :libraries
  has_many :items


  def check_baseurl
    Entity.fetch_web_page(self.baseurl)
  end

  def itempath_template
    "http://#{baseurl}/#{itempath}"
  end

  def random_entries(max=10)
    # sql=%Q{select a.* from abes a left join bib_entries be on(a.bib_entry_id=be.id
    # and a.entity_id=be.entity_id) where a.entity_id = #{self.id} order by oid desc limit #{max};}
    if self.sbn
      sql=%Q{select s1.id as bib_entry_id, #{self.id} as entity_id from (select be.oid,be.id from abes a
left join bib_entries be on(a.bib_entry_id=be.id) where be.sbn_id) as s1 JOIN (select
be.oid,be.id from abes a left join bib_entries be
on(a.bib_entry_id=be.id) where not be.sbn_id) as s2 using(oid) order by random() limit #{max};}
    else
      sql=%Q{select s1.id as bib_entry_id, #{self.id} as entity_id from (select be.oid,be.id from abes a
left join bib_entries be on(a.bib_entry_id=be.id and
a.entity_id=be.entity_id) where a.entity_id=#{self.id}) as s1 JOIN (select
be.oid,be.id from abes a left join bib_entries be
on(a.bib_entry_id=be.id and a.entity_id=be.entity_id) where
a.entity_id!=#{self.id}) as s2 using(oid) order by random() limit #{max};}
    end
    Abe.find_by_sql(sql)
  end

  def add_libraries(names)
    libs=[]
    names.each do |n|
      # puts n
      n.squeeze!(' ')
      libs << Library.find_or_create_by_name_and_entity_id(n,self.id)
    end
    libs
  end

  def extract_oid_from_url_orig(url)
    theurl=String.new(url)
    self.itempath_template.split('__%%__').each do |p|
      url.slice!(p)
    end
    url==theurl ? nil : url
  end
  def extract_oid_from_url(url)
    theurl=String.new(url)
    self.itempath_template.split('__%%__').each do |p|
      theurl.slice!(p)
    end
    url = (url==theurl ? nil : theurl)
    return nil if url.nil?
    # url.split('#').first
    url.split(/\&|\/|#|\?/).first
  end

  def Entity.trova_da_url(url)
    # puts "url: #{url}"
    return nil if url.blank?
    Entity.all.each do |e|
      next if e.baseurl.nil? or (/#{e.baseurl}/ =~ url).nil?
      source_oid=e.extract_oid_from_url(url)
      # puts "source_oid: #{source_oid}"
      # return e if !(/#{e.baseurl}/ =~ url).nil?
      return e if !source_oid.blank?
    end
    nil
  end

  def Entity.sbn
    Entity.all(:conditions=>'itempath notnull and baseurl notnull and sbn')
  end
  def Entity.nonsbn
    Entity.all(:conditions=>'itempath notnull and baseurl notnull and not sbn')
  end

  # Alternativa a fetch_web_page (usa Net::HTTP)
  # NB: evitare di utilizzare in quanto al momento non tratta eventuali redirect:
  # meglio usare fetch_web_page
  def Entity.get_url(url)
    x=url.split('/')
    return nil if x[0]!='http:'
    x.shift(2)
    host=x.slice!(0)
    path="/#{x.join('/')}"
    return nil if path.blank?
    # puts "host: '#{host}' - path: '#{path}'"
    res=Net::HTTP.get(host, path)
  end

  def Entity.fetch_web_page(url) 
    puts "fetching url '#{url}'"
    tempdir = File.join(Rails.root, 'tmp')
    tf = Tempfile.new("webpage",tempdir)
    html_file=tf.path

    uag='Mozilla/4.0 (MSIE 6.0; Windows NT 5.1)'
    comando = "/usr/bin/wget  --user-agent='#{uag}' -o /dev/null -O #{html_file} \"#{url}\""
    puts comando
    Kernel.system(comando)
    fd = File.open(html_file)
    data = fd.read
    fd.close
    tf.close(true)
    data
  end


end
