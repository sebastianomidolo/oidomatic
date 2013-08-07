-- lastmod  9 luglio 2013
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
 def estrai_biblioteche(s,abe)
  doc=Nokogiri::HTML(s)
  a=doc.search(".paging").search(".linkmappa").to_a.collect {|x| x.text}
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
   doc=Nokogiri::HTML(s)
   size=doc.search("#details").size
   size==1 ? true : false
 end
 def estrai_biblioteche(s,abe)
  doc=Nokogiri::HTML(s)
  a=doc.search("#items").search("a").to_a.collect {|x| x.text.strip.split(" - ").last}
  a.uniq
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


-- cavour.cilea.it unito
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
 def estrai_biblioteche(s,abe)
  doc=Nokogiri::HTML(s)
  a=doc.search(".testolocalizzazioni").search("a").to_a.collect {|x| x.text.gsub("\n","").strip}
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
 def estrai_biblioteche(s,abe)
   doc=Nokogiri::HTML(s)
   a=doc.search(".td1").to_a.collect {|x| t=x.text.strip; n=x.parent.children[2].text.strip if (t =~ /^Poss/); n}
   a.compact.uniq
 end
'
where id=4;



update entities
set procedures='
 def nontrovato(s)
   doc=Nokogiri::HTML(s)
   f=doc.search("#form1")[0]
   return false if f.nil?
   (f["action"] == "/Opac/RicercaBase.aspx") ? true : false
 end
 def trovato(s)
   puts "sbam page size: #{s.size}"
   doc=Nokogiri::HTML(s)
   f=doc.search("#form1")[0]
   return false if f.nil?
   puts %Q{in trovato sbam: #{f["action"]}}
   (f["action"].split("?").first == "/Opac/EsameTitolo.aspx") ? true : false
 end
 def ricavabid_daoid(oid)
  return nil if oid.blank?
  data=Entity.fetch_web_page("http://sbam.erasmo.it/Opac/EsameTitolo.aspx?IDTIT=#{oid}")
  doc=Nokogiri::HTML(data)
  doc.search("#lbBid").text
 end
 def estrai_biblioteche(s,abe)
   doc=Nokogiri::HTML(s)
   a=doc.search("#gvSbnLocalizza").search("tr").to_a.collect {|x| x.search("span")[0].text}
   a.uniq
 end
'
where id=5;


update entities
set procedures='
 def nontrovato(s)
   doc=Nokogiri::HTML(s)
   false
 end
 def trovato(s)
   doc=Nokogiri::HTML(s)
   x=doc.search("h3").to_a.collect {|x| x.text if x.text=~/Dublin/}.compact.size
   x>0 ? true : false
 end
 def ricavabid_daoid(oid)
  return nil if oid.blank?
  nil
 end
'
where id=8;


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



