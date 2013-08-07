# lastmod  2 ottobre 2012   - nuovo metodo unisci_oid
# lastmod 16 marzo 2012     - modifico 'localizzazioni' - esclusionebibl "E' in prestito in..."
# lastmod 15 marzo    2012  - modifico 'localizzazioni' aggiungendo parametro maxbib
# lastmod 25 gennaio  2012  - def BibEntry.associa
# lastmod 20 gennaio  2012  - trasformo in BibEntry.insert_new_if_sbn_else_try
# lastmod 19 gennaio  2012  - def BibEntry.insert_new_if_sbn (vedi 20 gennaio)
#                             def ricava_source_oid_da_bid
# lastmod  8 gennaio  2012  - def aggiorna_lista_biblioteche - def delete_items
# lastmod  4 gennaio  2012  - has_many :bib_entries  -  def add_items
# lastmod 22 dicembre 2011  - def BibEntry.insert_new
#                           - def edit_source_oid
# lastmod 21 dicembre 2011  - def BibEntry.trova_per_source_oid
# lastmod 20 dicembre 2011  - def localizzazioni
# lastmod 18 dicembre 2011  - def harvest
# lastmod 15 dicembre 2011

class BibEntry < ActiveRecord::Base
  attr_accessible :source_oid, :entity_id, :oid, :sbn_id
  belongs_to :entity
  has_many :abes
  has_many :items

  def sbnentry
    BibEntry.find(:first,:conditions=>{:oid=>self.oid, :sbn_id=>true})
  end
  def sbnbid
    b=sbnentry
    b.nil? ? nil : b.source_oid
  end

  def unisci_oid(entry)
    puts "entry.inspect: #{entry.inspect}"
    puts "self.inspect: #{self.inspect}"
    return false if entry.id==self.id or entry.oid==self.oid
    entry.oid=self.oid
    entry.save
    true
  end

  # Aggiunge o modifica un source_oid
  # Modifica del 25 gennaio 2012: se entity.nil? 
  # implica che sia di tipo SBN
  def edit_source_oid(entity,source_oid)
    puts self.entity.inspect
    entity=Entity.first(:conditions=>'sbn') if entity.nil?
    if !self.entity.nil? and self.entity.id==entity.id
      if self.source_oid!=source_oid
        puts "Modifico source_oid da #{self.source_oid} a #{source_oid}"
        self.source_oid=source_oid
        self.save
      end
      return self
    end
    h={}
    h[:source_oid]=source_oid
    if entity.sbn
      puts "aggiungo SBN source_oid #{source_oid} per #{entity.name}"
      h[:sbn_id]=true
    else
      puts "aggiungo non sbn source_oid #{source_oid} per #{entity.name}"
      h[:entity_id]=entity.id
    end
    e=BibEntry.find(:first, :conditions=>h)
    puts h.inspect
    if e.nil?
      h[:oid]=self.oid
      e=BibEntry.create(h) 
    end
    e
  end


  # Il parametro maxbib, aggiunto il 15 marzo 2012, indica il numero massimo
  # di biblioteche (tutte, se non specificato)
  def localizzazioni(mode=:single,exclude=[],maxbib=nil)
    # puts "Localizzo per bib_entry con id #{id} (mode: #{mode})"
    oid = mode==:all ? "be.oid=#{self.oid}" : "be.id=#{self.id}"
    if exclude==[]
      escludi=''
    else
      escludi="AND e.id NOT IN(#{exclude.join(',')})"
    end
    # puts "escludi: #{escludi}"

#    sql=%Q{select be.source_oid,e.name,e.id,
#      e.baseurl,e.itempath
#      from abes a join bib_entries be on(a.bib_entry_id=be.id)
#      join entities e on(a.entity_id=e.id) where #{oid} #{escludi}}

#    sql=%Q{select be.source_oid,e.name,e.id,
#  e.baseurl,e.itempath,array_agg(l.name) as biblioteche
#   from abes a join bib_entries be on(a.bib_entry_id=be.id)
#   join entities e on(a.entity_id=e.id) 
#   left join items i 
#   on (i.bib_entry_id=be.id and i.entity_id=e.id)
#   left join libraries l on(l.id=i.library_id)
# where #{oid} #{escludi} group by be.source_oid,e.name,e.id,e.baseurl,e.itempath;}

    limit=maxbib.nil? ? '' : "limit #{maxbib}"

    sql=%Q{select be.source_oid,e.name,e.id,
  e.baseurl,e.itempath,l.name as biblioteca
   from abes a join bib_entries be on(a.bib_entry_id=be.id)
   join entities e on(a.entity_id=e.id) 
   left join items i 
   on (i.bib_entry_id=be.id and i.entity_id=e.id)
   left join libraries l on(l.id=i.library_id)
 where #{oid} #{escludi} order by e.id,l.name;}

    # require 'csv'
    # puts sql
    pg=BibEntry.connection.execute(sql)
    res=[]
    arraybib=[]
    bib={}
    label={}
    href={}
    pg.each do |i|
      next if !(/in prestito in/ =~ i['biblioteca']).nil?
      id=i['id']
      bib[id] = [] if bib[id].nil?
      bib[id] << i['biblioteca'] if !i['biblioteca'].blank?
      label[id]=i['name']
      href[id]="http://#{i['baseurl']}/#{i['itempath']}".sub('__%%__',i['source_oid'])
    end
    # puts href.inspect
    # puts "maxbib: #{maxbib}"
    label.keys.each do |k|
      # url="http://#{i['baseurl']}/#{i['itempath']}".sub('__%%__',i['source_oid'])
      bibs=bib[k]
      if !maxbib.nil?
        # puts bibs.size-maxbib
        if bibs.size - maxbib > 1
          bibs=bib[k][0..maxbib-1]
          if bib[k].size>maxbib
            i=bibs.size-1
            # bibs.last += " - e altre #{bib[k].size - maxbib} biblioteche"
            bibs[i] = "#{bibs[i]} - e altre #{bib[k].size - maxbib} biblioteche"
          end
        end
      end
      res << {:label=>label[k],:href=>href[k],:biblioteche=>bibs}
      # res << {:label=>label[k],:href=>href[k],:biblioteche=>bib[k]}
    end
    res
  end

  def add_items(libraries)
    libraries.each do |l|
      Item.find_or_create_by_bib_entry_id_and_entity_id_and_library_id(self.id,l.entity.id,l.id)
    end
  end
  def delete_items(libraries)
    libraries.each do |l|
      Item.connection.execute("DELETE FROM items WHERE bib_entry_id=#{self.id} AND entity_id=#{l.entity.id} AND library_id=#{l.id}")
    end
  end

  def harvest
    last_checked=Time.now
    puts "analizzo bib_entry con id = #{self.id} ; oid #{self.oid} ; source_oid=#{self.source_oid}"
    BibEntry.all(:conditions=>"oid=#{self.oid}").each do |be|
      if be.sbn_id==true
        # puts "source_oid #{be.source_oid} SBN"
        oid=be.sbnbid
        ents=Entity.sbn
      else
        # puts "source_oid #{be.source_oid} NON SBN"
        ents=Entity.nonsbn
        oid=nil
      end
      cnt=0
      # next if !be.last_checked.blank?
      ents.each do |e|
        cnt+=1
        url="http://#{e.baseurl}/#{e.itempath}"
        # puts "cnt #{cnt}: #{url}"
        if oid.nil?
          next if be.entity_id!=e.id
          url.sub!('__%%__',be.source_oid)
        else
          url.sub!('__%%__',oid)
        end
        puts "url: '#{url}"
        # da fare: testare se i metodi "trovato" e "non trovato" esistono e fare undef se esistono
        # prima della "eval" (vedi esempio in abe.rb)
        if !e.procedures.blank?
          eval(e.procedures)
          data=Entity.fetch_web_page(url)
          # data=Entity.get_url(url) ; evitare di utilizzare, non tratta la redirezione
          if data.nil?
            puts "pagina vuota da #{url}"
            next
          end
          puts "chiamo metodo 'nontrovato'..."
          # condizione 1
          c1=send("nontrovato", data)
          puts "c1 - nontrovato: #{c1}"
          c2=send("trovato", data)
          puts "c2 - trovato: #{c2}"
          # puts "data per id #{e.id}\n#{data}\n"
          puts "cerco abe per bib_entry #{be.id} e entity #{e.id}"
          if c1==true and c2==false
            puts "questo record (#{[be.id,e.id]}) non esiste su #{e.name}"
            Abe.delete([[be.id,e.id]])
          end
          if c1==false and c2==true
            puts "questo record esiste su #{e.name}"
            if !Abe.exists?([be.id,e.id])
              Abe.create(:bib_entry_id=>be.id,:entity_id=>e.id)
            end
          end
        end
      end
      be.last_checked=last_checked
      be.save!
    end
  end

  # Specificando una entity la lista viene aggiornata solo per quella entity, altrimenti per tutte
  def aggiorna_lista_biblioteche(entity=nil)
    # Recupera le biblioteche dai sistemi che lo permettono
    BibEntry.all(:conditions=>"oid=#{self.oid}").each do |be|
      be.abes.each do |a|
        next if !entity.nil? and a.entity.id!=entity.id
        listabib=a.entity.add_libraries(a.get_libraries)
        correnti=a.current_libraries
        # puts "presenti: #{correnti.inspect}"
        be.delete_items(correnti-listabib)
        puts "abe #{a.inspect} - biblioteche per il sistema #{a.entity.name}: #{listabib.inspect}"
        be.add_items(listabib)
      end
    end
  end

  # Vale per i sistemi non SBN per i quali si sia in grado di risalire all'source_oid
  # partendo dal BID
  def ricava_source_oids_da_bid
    Entity.all(:conditions=>'not sbn').each do |e|
      # puts "e: #{e.inspect}"
      hit=BibEntry.find_by_oid_and_entity_id(self.oid,e.id)
      next if !hit.nil?
      logger.warn("cerco di trovare source_oid per #{e.inspect}")
      source_oid=self.ricava_source_oid_da_bid(e)
      next if source_oid.blank?
      logger.warn("ottenuto source_oid: #{source_oid}")
      self.edit_source_oid(e,source_oid)
    end
    nil
  end

  def ricava_source_oid_da_bid(e)
    puts "e: #{e.name}"
    pnam='ricavaoid_dabid'
    eval("undef #{pnam}") if self.respond_to?(pnam)
    eval(e.procedures) if !e.procedures.blank?
    x=self.respond_to?(pnam)
    source_oid=nil
    if x
      puts "posso chiamare #{pnam} per #{e.name} - #{self.inspect}"
      source_oid=send(pnam,self.sbnbid)
      puts "bid #{self.sbnbid} => #{source_oid}"
    else
      puts "non posso chiamare #{pnam} per #{e.name} - #{self.inspect}"
    end
    source_oid
  end

  # Vale per i sistemi non SBN per i quali si sia in grado di risalire al BID
  # partendo dal source_oid

  def ricava_bid_da_source_oid
    e=entity
    logger.warn("cerco di trovare BID partendo da source_oid #{self.source_oid}")
    puts "entity: #{e.name}"
    pnam='ricavabid_daoid'
    eval("undef #{pnam}") if self.respond_to?(pnam)
    eval(e.procedures) if !e.procedures.blank?
    x=self.respond_to?(pnam)
    bid=nil
    if x
      puts "posso chiamare #{pnam} per #{e.name} - #{self.inspect}"
      bid=send(pnam,self.source_oid)
      logger.warn("source_oid #{self.source_oid} => #{bid}")
    else
      puts "non posso chiamare #{pnam} per #{e.name} - #{self.inspect}"
    end
    puts "bid: #{bid}"
    self.add_sbn_bid(bid) if !bid.nil?
    bid
  end

  def riallinea_entry
    if self.entity.nil?
      self.ricava_source_oids_da_bid
      # puts self.inspect
    else
      self.ricava_bid_da_source_oid
      # puts self.inspect      
    end
    self.harvest
    self.aggiorna_lista_biblioteche
  end

  def add_sbn_bid(bid)
    puts "entrato in allinea_sbn_bid per BibEntry(#{self.id}) con bid #{bid}"
    return nil if bid.blank?
    be=BibEntry.trovabid(bid)
    if be.nil?
      h={}
      h[:sbn_id]=true
      h[:oid]=self.oid
      h[:source_oid]=bid
      be=BibEntry.create(h)
    else
      logger.warn("trovata be con oid #{be.oid} (oid self: #{self.oid})")
      if self.oid!=be.oid
        sql="update bib_entries set oid = #{self.oid} where oid = #{be.oid}"
        logger.warn(sql)
        BibEntry.connection.execute(sql)
      end
    end
  end

  def BibEntry.trova_per_source_oid(entity,source_oid)
    if entity.sbn==true
      BibEntry.find(:first,:conditions=>{:sbn_id=>true,:source_oid=>source_oid})
    else
      BibEntry.find(:first,:conditions=>{:entity_id=>entity.id,:source_oid=>source_oid})
    end
  end

  def BibEntry.trovabid(b)
    BibEntry.find(:first,:conditions=>{:source_oid=>b, :sbn_id=>true})
  end

  def BibEntry.insert_new_if_sbn_else_try(entity,source_oid)
    return nil if source_oid.blank?
    be=nil
    if entity.sbn
      be=BibEntry.trovabid(source_oid)
      return be if !be.nil?
      puts "sistema sbn: #{entity.name} - source_oid da inserire: #{source_oid}"
      be=BibEntry.insert_new(nil,source_oid)
      be.ricava_source_oids_da_bid
    else
      be=BibEntry.trova_per_source_oid(entity,source_oid)
      return be if !be.nil?
      logger.warn("source_oid #{source_oid} per sistema non sbn da inserire ora!")
      be=BibEntry.insert_new(entity,source_oid)
      be.ricava_bid_da_source_oid
    end
    if !be.nil?
      be.harvest
      be.aggiorna_lista_biblioteche
    end
    be
  end

  def BibEntry.associa(bib_entries=[])
    oids={}
    ids=[]
    bib_entries.each do |be|
      puts be.inspect
      oids[be.oid]=true
      ids << be.id
    end
    return oids.keys.first.to_i if oids.keys.size==1
    oid=oids.keys.sort.first
    # puts "oids tra cui scegliere: #{oids.keys.join(',')} - scelto #{oid}"
    # puts "devo aggiornare bib_entries con ids in (#{ids.join(',')})"
    sql="UPDATE bib_entries SET oid=#{oid} WHERE id IN(#{ids.join(',')})"
    logger.warn(sql)
    BibEntry.connection.execute(sql)
    return oid
  end

  # Se entity e' nil, assumo che source_oid sia un bid sbn
  def BibEntry.insert_new(entity,source_oid)
    h={}
    h[:source_oid]=source_oid
    if entity.nil?
        h[:sbn_id]=true
    else
      if entity.sbn
        h[:sbn_id]=true
      else
        h[:entity_id]=entity.id
      end
    end
    h[:oid]=BibEntry.connection.execute("select max(oid) from bib_entries").collect.first['max'].to_i+1
    be=BibEntry.create(h)
    be
  end
end
