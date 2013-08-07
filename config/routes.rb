Oidomatic::Application.routes.draw do
  resources :libraries
  resources :bib_entries do
    member do
      get 'allinea'
    end
  end

  resources :entities

  match '/getinfo' => 'getinfo#gti'

  match '/mtwrite' => 'getinfo#mtwrite'

  match '/mtget' => 'getinfo#mtget'

  match '/bsow' => 'getinfo#bid_and_source_oid_write'

  match '/museotorino/:oid/:type' => 'getinfo#proxy_for_mt'

  match '/museotorino/:type' => 'getinfo#proxy_for_mt'


  root :to => 'home#index'
end
