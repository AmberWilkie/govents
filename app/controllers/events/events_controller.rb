require 'nokogiri'
require 'open-uri'
require 'httparty'

class Events::EventsController < ApplicationController

  def index
    @events_json = nil
    render 'events/index'
  end

  def get_events
    @query = params[:query]
    @meetup_date_query = 'month'
    @date_query = Date.today + 30
    @meetup_date = 1485072000000000 # Need to find a real number to use here that makes any sense.
    @events_json = get_meetup_events
    @city_json = get_city_events
    @facebook_events = get_facebook_events
    render 'events/index'
  end

  def today
    @query = ''
    @meetup_date_query = 'today'
    @date_query = Date.today.strftime('%Y-%m-%d')
    @meetup_date = 1485072000000
    @events_json = get_meetup_events
    @city_json = get_city_events
    @facebook_events = get_facebook_events
    render 'events/index'
  end

  private

  def get_city_events
    HTTParty.get("http://esb.goteborg.se/TEIK/001/Kalendarie/?startDate=#{Date.today}&date=#{@meetup_date_query}&type=freetext&searchstring=#{@query}")
  end

  def get_meetup_events

    params = {text: @query,
              lon: '11.9746',
              lat: '57.7089',
              country: 'se',
              status: 'upcoming',
              format: 'json',
              time: "0, #{@meetup_date}",
              page: '100'}
    meetup_api = MeetupApi.new
    events = meetup_api.open_events(params)
  end

  def get_facebook_events

    if @query == ''
      @query = '*'
    end

    HTTParty.get("https://graph.facebook.com/search?q=#{@query}&type=event&center=57.7089,11.9746&distance=1000&access_token=#{ENV['FACEBOOK_CODE']}&fields=description,place&until=#{@date_query}" )

  end

end