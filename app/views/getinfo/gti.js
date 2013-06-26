<%
    @text=[]
    if !@bib_entry.nil?
      @bib_entry.localizzazioni(:all, [@entity.id], 3).each do |l|
        biblist=l[:biblioteche].size==0 ? '' : " (#{l[:biblioteche].join(', ')})"
        @text << content_tag(:span, link_to(l[:label], l[:href])) + biblist
      end
      if @text.blank?
        @msg=''
      else
        if @bid.nil?
          @msg='<em>Altri sistemi bibliotecari:</em>&nbsp;'
        else
          @msg='<em>Vedi</em>&nbsp;'
        end
      end
    else
      # @text << "Opera non reperibile in Piemonte (per dire qualcosa)"
      # @msg = "record not found - href=#{@url}"
    end
    @text="#{@msg}#{@text.join(' | ')}"
-%>
document.getElementById('oidomaticdiv').innerHTML='<%="#{@text}".html_safe %>'




