Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  namespace :events do
    get '/', controller: :events, action: :index
    get '/all_events', controller: :events, action: :get_events, as: :get_events
    post '/', controller: :events, action: :query_events, as: :query_events
    get '/today', controller: :events, action: :today, as: :today
  end

  # get '/', controller: :events, action: :index
  root to: '/events', controller: 'events/events', action: :index
end
