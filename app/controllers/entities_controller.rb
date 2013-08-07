# lastmod 21 dicembre 2011
# lastmod  4 ottobre 2011

class EntitiesController < ApplicationController
  # GET /entities
  # GET /entities.xml
  def index
    @entities = Entity.all(:conditions=>'id not in (12)')
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @entities }
    end
  end

  def oids
    @entity = Entity.find(params[:id])
  end

  # GET /entities/1
  # GET /entities/1.xml
  def show
    @entity = Entity.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @entity }
    end
  end

end
