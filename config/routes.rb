Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get 'login' => 'session#entry'
  get 'signup' => 'session#new'

  get 'user/:user_id/entry' => 'user#entry'
  # temp
  get 'user/entry' => 'user#entry'

  get 'user/:user_id/profile' => 'user#profile'
  post 'user/:user_id/profile' => 'user#profile'

  get 'group/new' => 'group#new'
  post 'group/new' => 'group#new'
  get 'group/:group_id/edit' => 'group#edit'
  post 'group/:group_id/edit' => 'group#edit'

  get 'score/:group_id/list' => 'score#list'

  get 'condition/index' => 'condition/index'
  post 'condition/index' => 'condition/calc'


end
