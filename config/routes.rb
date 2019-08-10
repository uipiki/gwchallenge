Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root to: 'condition#information'
  get 'condition/information' => 'condition/information'
  get 'condition/calc' => 'condition/calc'

end
