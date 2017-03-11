Rails.application.routes.draw do
  namespace :events do
    get '/', controller: :events, action: :get_events
    get '/all_events', controller: :events, action: :get_events
    post '/all_events', controller: :events, action: :get_events, as: :get_events
    post '/', controller: :events, action: :query_events, as: :query_events
    get '/today', controller: :events, action: :today, as: :today
    get '/more', controller: :events, action: :more, as: :more
  end

  root to: '/events', controller: 'events/events', action: :get_events
end
