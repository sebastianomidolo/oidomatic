Oidomatic::Application.routes.draw do
  resources :libraries
  resources :bib_entries
  resources :entities

  # map.getinfo '/getinfo', :controller => 'getinfo', :action => 'gti'
  match '/getinfo' => 'getinfo#gti'

  # map.getinfo '/mtwrite', :controller => 'getinfo', :action => 'mtwrite'
  match '/mtwrite' => 'getinfo#mtwrite'

  # map.getinfo '/mtget', :controller => 'getinfo', :action => 'mtget'
  match '/mtget' => 'getinfo#mtget'

  # 25 gennaio 2012
  # map.getinfo '/bsow', :controller => 'getinfo', :action => 'bid_and_source_oid_write'
  match '/bsow' => 'getinfo#bid_and_source_oid_write'

  root :to => 'home#index'
end
