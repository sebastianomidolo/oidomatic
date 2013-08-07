# lastmod 17 giugno 2013 (html_safe)
# lastmod 4 ottobre 2011
module EntitiesHelper
  def entities_sistemi_attivi
    r=[]
    Entity.all(:order=>'id').each do |e|
      next if [12].include?(e.id)
      td=[]
      td << content_tag(:td, e.name)
      r << content_tag(:tr, td.join.html_safe)
    end
    content_tag(:table, r.join.html_safe)
  end
end
