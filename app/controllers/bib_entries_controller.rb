class BibEntriesController < ApplicationController
  # GET /bib_entries
  # GET /bib_entries.xml
  def index
    @bib_entries = BibEntry.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @bib_entries }
    end
  end

  # GET /bib_entries/1
  # GET /bib_entries/1.xml
  def show
    @bib_entry = BibEntry.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @bib_entry }
    end
  end

  def allinea
    @bib_entry = BibEntry.find(params[:id])
    @bib_entry.riallinea_entry
    render :action=>:show
  end

end
