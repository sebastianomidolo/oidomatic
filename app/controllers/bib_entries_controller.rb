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

  # GET /bib_entries/new
  # GET /bib_entries/new.xml
  def new
    @bib_entry = BibEntry.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @bib_entry }
    end
  end

  # GET /bib_entries/1/edit
  def edit
    @bib_entry = BibEntry.find(params[:id])
  end

  # POST /bib_entries
  # POST /bib_entries.xml
  def create
    @bib_entry = BibEntry.new(params[:bib_entry])

    respond_to do |format|
      if @bib_entry.save
        format.html { redirect_to(@bib_entry, :notice => 'BibEntry was successfully created.') }
        format.xml  { render :xml => @bib_entry, :status => :created, :location => @bib_entry }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @bib_entry.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /bib_entries/1
  # PUT /bib_entries/1.xml
  def update
    @bib_entry = BibEntry.find(params[:id])

    respond_to do |format|
      if @bib_entry.update_attributes(params[:bib_entry])
        format.html { redirect_to(@bib_entry, :notice => 'BibEntry was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @bib_entry.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /bib_entries/1
  # DELETE /bib_entries/1.xml
  def destroy
    @bib_entry = BibEntry.find(params[:id])
    @bib_entry.destroy

    respond_to do |format|
      format.html { redirect_to(bib_entries_url) }
      format.xml  { head :ok }
    end
  end
end
