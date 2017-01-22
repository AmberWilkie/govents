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
    @date_query = 'month'
    @meetup_date = (86400 * 30 * 3).to_s
    @events_json = get_meetup_events
    @city_json = get_city_events
    render 'events/index'
  end

  def today
    @query = ''
    @date_query = 'today'
    @meetup_date = 86400
    @events_json = get_meetup_events
    @city_json = get_city_events
    render 'events/index'
  end

  private

  def get_city_events
    HTTParty.get("http://esb.goteborg.se/TEIK/001/Kalendarie/?startDate=#{Date.today}&date=#{@date_query}&type=freetext&searchstring=#{@query}")
  end

  def get_meetup_events

    params = {text: @query,
              lon: '11.9746',
              lat: '57.7089',
              country: 'se',
              status: 'upcoming',
              format: 'json',
              # time: "0, #{@meetup_date}",
              page: '100'}
    meetup_api = MeetupApi.new
    events = meetup_api.open_events(params)
  end

end