# -*- coding: utf-8 -*-
# -*- mode: ruby;-*-
# lastmod 10 luglio 2013

require 'csv'

desc 'Importazione standard da csv'
task :standard_import => :environment do
  puts "ok"

  def do_import(entity,fname,fd,fd_items)
    puts "import per #{entity.name}"
    fd_items.write("-- items for #{entity.name} (da lanciare dopo)\n")
    fd_items.write(%Q{DELETE FROM items WHERE entity_id=#{entity.id};\n})

    fd.write("-- #{entity.name}\n")
    fd.write("BEGIN;\n")
    # fd.write(%Q{DELETE FROM libraries WHERE entity_id=#{entity.id};\n})
    fd.write(%Q{DELETE FROM abes WHERE entity_id=#{entity.id};\n})
    fd.write(%Q{DELETE FROM bib_entries WHERE entity_id=#{entity.id};\n})

    # Inserimento biblioteche
    biblist=[]
    CSV::parse(open(fname)).each do |r|
      id,bid,library_name=r
      next if id.blank? or (id =~ /^(#| )/) or library_name.blank?
      library_name.strip!
      # puts "Inserisco biblioteca '#{library_name}'"
      biblio=Library.find_or_create_by_entity_id_and_name(entity.id,library_name)
      biblist << biblio
    end
    biblioteche_da_cancellare=Library.all(:conditions=>{:entity_id=>entity.id}) - biblist
    puts "#{biblioteche_da_cancellare.size} biblioteche da cancellare"

    fd_items.write("CREATE TEMP TABLE temp_items (source_oid varchar(80), entity_id integer, library_id integer);\n")
    hash_for_libraries={}
    biblist.each do |l|
      hash_for_libraries[l.name]=l.id
    end

    # Inserimento bib_entries
    fd.write(%Q{COPY bib_entries (oid,source_oid,entity_id,sbn_id) FROM stdin;\n})
    fd_items.write(%Q{COPY temp_items (source_oid,entity_id,library_id) FROM stdin;\n})
    prec_id=nil
    prec_be=nil
    CSV::parse(open(fname)).each do |r|
      id,bid,library_name=r
      next if id.blank? or (id =~ /^(#| )/)
      id.strip!

      # puts "id '#{id}' - bid #{bid} (library '#{library_name}')"
      # se il "bid" inizia con una cifra seguita da ":" la cifra rappresenta l'id dell'entity
      # e ciò che segue i ":" è il source_oid della entity, esempio:
      # bid="2:197025" => source_oid 197025 del sistema BCT (entity.id 2)

      if id!=prec_id
        prec_id=id
        e_id,source_oid=bid.split(":")
        if (e_id =~ /^\d(.*)$/).nil?
          puts "sbn bid #{bid}"
          if bid.size!=10
            # non faccio altri controlli a parte la lunghezza, fidandomi dei dati in input
            puts "bid associato a #{id} non lungo 10 caratteri: #{bid}"
            next
          end
          be=BibEntry.trovabid(bid)
          if be.nil?
            puts "questo bid non è presente in oidomatic '#{bid}' (caso non trattato, per ora)"
            next
          else
            puts "trovato bid #{bid} con oid #{be.oid}"
          end
        else
          puts "#{Entity.find(e_id).name} - source_oid '#{source_oid}'"
          be=BibEntry.find(:first,:conditions=>{:entity_id=>e_id,:source_oid=>source_oid})
          if be.nil?
            puts "questo source_oid non è presente in oidomatic '#{source_oid}' (caso non trattato)"
            next
          else
            puts "trovato source_oid #{source_oid} con oid #{be.oid}"
          end
        end
        fd.write("#{be.oid}\t#{id}\t#{entity.id}\tfalse\n")
        prec_be=be
      else
        puts "ripetizione id #{id}"
      end
      if !library_name.blank? and !prec_be.nil?
        puts "library: #{library_name} =>#{hash_for_libraries[library_name]}"
        fd_items.write("#{id}\t#{entity.id}\t#{hash_for_libraries[library_name]}\n")
      end
    end
    fd.write("\\.\n")
    fd_items.write("\\.\n")

    sql=%Q{INSERT INTO abes (bib_entry_id,entity_id) (SELECT id,entity_id FROM bib_entries WHERE entity_id = #{entity.id});\n}
    fd.write(sql)

    sql=%Q{INSERT INTO items (library_id,entity_id,bib_entry_id)
       (SELECT ti.library_id,be.entity_id,be.id FROM temp_items TI join bib_entries be
          USING(entity_id,source_oid));
        DROP TABLE temp_items;\nCOMMIT;\n}
    fd_items.write(sql)
  end

  Dir[(File.join(File.join(Rails.root,'data'),'*'))].each do |fname|
    next if fname =~ /~$/ or !(fname =~ /\.csv$/) or File.directory?(fname)
    entity_id=File.basename(fname,".csv").split('_').last
    next if (entity_id =~ /^\d(.*)$/).nil?
    if Entity.exists?(entity_id)
      entity=Entity.find(entity_id)
      puts "Processo #{fname} per #{entity.name}"
      sqlfile=File.join(File.dirname(fname),File.basename(fname,".csv")+'.sql')
      outfd=File.open(sqlfile,'w')
      sqlfile_items=File.join(File.dirname(fname),File.basename(fname,".csv")+'_items.sql')
      outfd_items=File.open(sqlfile_items,'w')
      do_import(entity,fname,outfd,outfd_items)
      outfd_items.close
      outfd.close
    else
      puts "Ignoro file #{fname}"
    end
  end

  
end
