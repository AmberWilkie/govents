Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  namespace :events do
    get '/', controller: :events, action: :index
    post '/', controller: :events, action: :get_events, as: :get_events
  end

  # get '/', controller: :events, action: :index
  root to: '/events', controller: :events, action: :index
end
