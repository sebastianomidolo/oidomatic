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
    url==theurl ? nil : theurl
  end


  def Entity.trova_da_url(url)
    return nil if url.blank?
    Entity.all.each do |e|
      next if e.baseurl.nil?
      return e if !(/#{e.baseurl}/ =~ url).nil?
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
    tempdir = File.join(RAILS_ROOT, 'tmp')
    tf = Tempfile.new("webpage",tempdir)
    html_file=tf.path

    uag='Mozilla/4.0 (MSIE 6.0; Windows NT 5.1)'
    comando = "/usr/local/bin/wget  --user-agent='#{uag}' -o /dev/null -O #{html_file} \"#{url}\""
    # puts comando
    Kernel.system(comando)
    fd = File.open(html_file)
    data = fd.read
    fd.close
    tf.close(true)
    data
  end


end
