-- lastmod 11 febbraio 2012
-- lastmod 10 febbraio 2012
-- lastmod 19 gennaio 2012

update entities set procedures=null where procedures notnull;

-- museo torino
update entities
set procedures='
 def nontrovato(s)
   r = (/No results for sid/ =~ s)
   r.nil? ? false : true
 end
 def trovato(s)
   r = (/<div id="biblio_form_container">/ =~ s)
   r.nil? ? false : true
 end
'
where id=0;

-- museo torino (digitalizzati)
update entities
set procedures='
 def nontrovato(s)
   r = (/404 Page Not Found/ =~ s)
   r.nil? ? false : true
 end
 def trovato(s)
   r = (/onLoad="afterLoad()"/ =~ s)
   if r.nil?
     r = (/<h1>Index of/ =~ s)
   end
   r.nil? ? false : true
 end
'
where id=7;


-- librinlinea
-- 
update entities
set procedures='
 def nontrovato(s)
   r = (/bid inesistente:/ =~ s)
   r.nil? ? false : true
 end
 def trovato(s)
   r = (/Dove lo trovi/ =~ s)
   r.nil? ? false : true
 end
 def disabled_estrai_biblioteche(s,abe)
  # puts %Q{In estrai_biblioteche per #{abe.entity.name} - bid="#{abe.bib_entry.sbnbid}" - bib_entry #{abe.bib_entry.id} s.size=#{s.size}}
  doc=Hpricot(s)
  # puts doc.class
  # t=doc.search(%Q{//div[@id="tabs"]})
  t=doc.search(%Q{//ul[@class="paging"]})
  # a=t.search("a").to_a.collect {|e| e.inner_html.strip}
  a=t.search("//a[@class=linkmappa]").to_a.collect {|e| e.inner_html.strip}
  # a.shift
  a.uniq
 end
'
where id=1;

-- bct clavis
update entities
set procedures='
 def nontrovato(s)
   r = (/<title>Pagina non trovata/ =~ s)
   r.nil? ? false : true
 end
 def trovato(s)
   r = (/<div class="detail">/ =~ s)
   r.nil? ? false : true
 end
 def disabled_estrai_biblioteche(s,abe)
  puts %Q{In estrai_biblioteche per #{abe.entity.name} - bid="#{abe.bib_entry.sbnbid}" - bib_entry #{abe.bib_entry.id} s.size=#{s.size}}
  doc=Hpricot(s)
  puts doc.class
  t=doc.search(%Q{//div[@id="tab-items"]})
  a=t.search("a").to_a.collect {|e| e.inner_html.strip.split(" - ").last}
  a.uniq
  #  puts a.inspect
 end
 def ricavaoid_dabid(bid)
  return nil if bid.blank?
  Net::HTTP.get("tobi.selfip.info", "/titles/clavis_mid/#{bid}")
 end
 def ricavabid_daoid(oid)
  return nil if oid.blank?
  Net::HTTP.get("tobi.selfip.info", "/titles/clavis_mid2bid/#{oid}")
 end
'
where id=2;


-- cavour.cilea.it
update entities
set procedures='
 def nontrovato(s)
   r = (/NESSUN DOCUMENTO ESTRATTO/ =~ s)
   r.nil? ? false : true
 end
 def trovato(s)
   # criterio da migliorare
   r = (/unimarc/ =~ s)
   r.nil? ? false : true
 end
 def disabled_estrai_biblioteche(s,abe)
  puts %Q{In estrai_biblioteche per #{abe.entity.name} - bid="#{abe.bib_entry.sbnbid}" - bib_entry #{abe.bib_entry.id} s.size=#{s.size}}
  doc=Hpricot(s)
  # puts doc.class
  t=doc.search(%Q{//span[@class="testolocalizzazioni"]})
  a=t.search("a").to_a.collect {|e| e.inner_html.strip.gsub("&#039;", %Q{"})}
  a.delete_if {|x| /Tutte/=~x}
  a.uniq
 end
'
where id=3;

-- polito
update entities
set procedures='
 def nontrovato(s)
   r = (/record richiesto non esiste/ =~ s)
   r.nil? ? false : true
 end
 def trovato(s)
   r = (/Formato completo del record/ =~ s)
   r.nil? ? false : true
 end
 def disabled_estrai_biblioteche(s,abe)
  # puts "Non funziona ancora per polito"
  puts %Q{In estrai_biblioteche per #{abe.entity.name} - bid="#{abe.bib_entry.sbnbid}" - bib_entry #{abe.bib_entry.id} s.size=#{s.size}}
  doc=Hpricot(s)
  puts doc.class
  
  ar=[]
  doc.search("td[text()*=Poss. da]").each do |x|
     x=x.parent.search("a")
     next if x.nil?
     ar << x.inner_text.strip
  end
  # puts "ar: #{ar.inspect}"
  ar
 end
'
where id=4;



-- biella - decommentare questa insert per riattivare biella
-- insert into entities(id,name,baseurl,sbn,itempath) values (6,'Sistema bibliotecario biellese','www.polobibliotecario.biella.it',true,'vufind/Record/__%%__');

update entities
set procedures='
 def nontrovato(s)
   r = (/Record Does Not Exist/ =~ s)
   r.nil? ? false : true
 end
 def trovato(s)
   r = (/Esporta il record/ =~ s)
   r.nil? ? false : true
 end
'
where id=6;



