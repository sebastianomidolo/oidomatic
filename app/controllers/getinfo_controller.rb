# -*- coding: utf-8 -*-
# lastmod 30 ottobre 2012  - modifica a mtget
# lastmod 25 gennaio 2012  - def bid_and_source_oid_write
# lastmod 20 gennaio 2012
# lastmod 19 gennaio 2012
# lastmod 16 dicembre 2011
# lastmod 15 dicembre 2011

class GetinfoController < ApplicationController
  def gti
    @url=params[:href]
    @entity=Entity.trova_da_url(@url)
    logger.warn("url: #{@url}")
    if !@entity.nil?
      @bib_entry=BibEntry.trova_per_source_oid(@entity,@entity.extract_oid_from_url(@url))
      if @bib_entry.nil?
        oid=@entity.extract_oid_from_url(@url)
        logger.warn("valuto se aggiungere oid '#{oid}' per #{@entity.name}")
        @bib_entry=BibEntry.insert_new_if_sbn_else_try(@entity,oid)
      end
    else
      @bid=params[:bid]
      if !@bid.nil?
        logger.warn("richiesta diretta su bid '#{@bid}'")
        @bib_entry=BibEntry.trovabid(@bid)
      end
    end
    render :text=>'not found', :content_type=>'text' and return if @bib_entry.nil?

    respond_to do |format|
      format.js
      format.json {
        render :json=>@bib_entry.localizzazioni(:all, [@entity.id])
      }
      format.xml {
        render :xml=>@bib_entry.localizzazioni(:all, [@entity.id])
      }
      format.html {
        render :text=>'';
      }
    end
  end
  
  def mtget
    resp={}
    # resp[:debug]=true
    if !params[:bid].blank?
      bid=params[:bid]
      @bib_entry=BibEntry.find(:first,:conditions=>{:sbn_id=>true,:source_oid=>bid})
      resp[:bid]=bid
      # Modifico su richiesta di Vivanti, vedi email 30 ottobre 2012:
      # era: locmode=:single diventa:
      locmode=:all
    end
    if !params[:mt].blank?
      mt=params[:mt]
      @bib_entry=BibEntry.find(:first,:conditions=>{:entity_id=>0,:source_oid=>mt})
      resp[:mt]=mt
      locmode=:all
    end
    if !params[:poli_id].blank?
      poli_id=params[:poli_id]
      @bib_entry=BibEntry.find(:first,:conditions=>{:entity_id=>4,:source_oid=>poli_id})
      resp[:poli_id]=poli_id
      locmode=:all
    end
  
    if @bib_entry.nil?
      resp[:status]='404 NOT FOUND'
    else
      resp[:status]='200 OK'
      # Esclude Entities 0 (museo torino) e 7 (museo torino digitalizzati)
      resp[:consistenze]=@bib_entry.localizzazioni(locmode,[0,7])
    end
    render :json=>resp.to_json
  end

  def mtwrite
    # Valutare se inserire un metodo di autenticazione su questa azione
    resp={}
    if !params[:mt].blank?
      @mt=params[:mt]
      resp[:mt]=@mt
      @mt_entry=BibEntry.find(:first,:conditions=>{:entity_id=>0,:source_oid=>@mt})
    end
    if !params[:bid].blank?
      @bid=params[:bid]
      resp[:bid]=@bid
      @sbn_entry=BibEntry.find(:first,:conditions=>{:sbn_id=>true,:source_oid=>@bid})
    end
    if !params[:polito].blank?
      @polito=params[:polito]
      resp[:polito]=@polito
      @polito_entry=BibEntry.find(:first,:conditions=>{:entity_id=>4,:source_oid=>@polito})
    end
    if @mt.nil?
      resp[:error]='missing mt identifier'
    else
      if @mt_entry.nil?
        @mt_entry=BibEntry.insert_new(Entity.find(0),@mt)
        resp[:msg]='creazione mt entry'
      else
        resp[:msg]='entry esistente per mt'
      end
    end
    if @sbn_entry.nil?
      if !@sbn.nil?
        resp[:bid_report]="devo creare bid sbn #{@bid} per #{@mt_entry.inspect}"
        @mt_entry.edit_source_oid(Entity.find(1),@bid)
      end
    else
      resp[:bid_report]="esiste entry sbn: #{@sbn_entry.source_oid}  #{@mt_entry.inspect}"
    end
    if @polito_entry.nil?
      if !@polito.nil?
        resp[:polito_report]="devo creare id polito #{@polito} per #{@mt_entry.inspect}"
        @mt_entry.edit_source_oid(Entity.find(4),@polito)
      end
    else
      resp[:polito_report]="esiste entry polito: #{@polito_entry.source_oid}  #{@mt_entry.inspect}"
    end
    render :json=>resp.to_json
  end

  def bid_and_source_oid_write
    # Valutare se inserire un metodo di autenticazione su questa azione
    resp={}
    if !params[:bid].blank?
      @bid=params[:bid]
      @sbn_entry=BibEntry.find(:first,:conditions=>{:sbn_id=>true,:source_oid=>@bid})
    else
      resp[:error]='missing bid'
      render :json=>resp.to_json and return
    end
    if !params[:entity_id].blank?
      @entity=Entity.find(params[:entity_id])
    else
      resp[:error]='missing entity_id'
      render :json=>resp.to_json and return
    end
    if !params[:source_oid].blank?
      @source_oid=params[:source_oid]
      @bib_entry=BibEntry.find(:first,:conditions=>{:entity_id=>@entity.id,:source_oid=>@source_oid})
    else
      resp[:error]='missing source_oid'
      render :json=>resp.to_json and return
    end

    if @bib_entry.nil?
      @bib_entry=BibEntry.insert_new(@entity,@source_oid)
      resp[:msg]="creazione bib_entry con source_oid #{@source_oid}"
    end

    if @sbn_entry.nil?
      @sbn_entry=BibEntry.insert_new(nil,@bid)
      resp[:msg]="creazione sbn_entry con bid #{@bid}"
    end

    oid=BibEntry.associa([@bib_entry,@sbn_entry])

    resp[:bid]=@bid
    resp[:entity]=@entity.name
    resp[:source_oid]=@source_oid
    resp[:sbn_entry]=@sbn_entry.id
    resp[:bib_entry]=@bib_entry.id
    resp[:oid]=oid

    be=BibEntry.find(:first, :conditions=>"oid=#{oid}")
    be.harvest
    be.aggiorna_lista_biblioteche

    render :json=>resp.to_json
  end

  # http://bctdoc.selfip.net/issues/49
  def proxy_for_mt
    oid=params[:oid]
    type=params[:type]

    resp={}
    case type
    when 'bid'
      @bib_entry=BibEntry.find(:first,:conditions=>{:sbn_id=>true,:source_oid=>oid})
      resp[:bid]=oid
    when 'mt'
      @bib_entry=BibEntry.find(:first,:conditions=>{:entity_id=>0,:source_oid=>oid})
      resp[:mt]=oid
    when 'poli_id'
      @bib_entry=BibEntry.find(:first,:conditions=>{:entity_id=>4,:source_oid=>oid})
      resp[:poli_id]=oid
    end

    if @bib_entry.nil?
      resp[:status]='404 NOT FOUND'
    else
      resp[:status]='200 OK'
      # Esclude Entities 0 (museo torino) e 7 (museo torino digitalizzati)
      resp[:consistenze]=@bib_entry.localizzazioni(:all,[0,7])
    end
    render :json=>resp.to_json
  end

end
