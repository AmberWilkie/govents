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
    @date_query = Date.today + 60
    @meetup_date = 1485072000000000

    @events_json = Rails.cache.fetch("meetup", expires_in: 30.minutes) do
      @events_json = get_meetup_events
    end

    @city_json = Rails.cache.fetch("gbg_stad", expires_in: 30.minutes) do
      @city_json = get_city_events
    end

    @facebook_events = Rails.cache.fetch("facebook", expires_in: 30.minutes) do
      @facebook_events = get_facebook_events
    end

    @grid_number = get_grid_number

    render 'events/index'
  end

  def query_events
    @query = params[:query]
    @meetup_date_query = 'month'
    @date_query = Date.today + 30
    @meetup_date = 1485072000000000
    @events_json = get_meetup_events
    @city_json = get_city_events
    @facebook_events = get_facebook_events
    @grid_number = get_grid_number

    # Show a 'sorry' message if no responses returned
    if @grid_number == 10
      @message = "Your search returned no results. Try 'Get All Events' or searching for something else."
    end

    render 'events/index'
  end

  def more
    get_pustervik_events
    render 'events/more'
  end

  private

  def get_city_events
    events = []
    all_events = HTTParty.get("http://esb.goteborg.se/TEIK/001/Kalendarie/?startDate=#{Date.today}&date=#{@meetup_date_query}&type=freetext&searchstring=#{@query}")

    if all_events['activities']
      all_events['activities'].each do |event|
        if !event['recurring'] && (event['endDate'].nil? || event['endDate'].to_date < (Date.today + 2.weeks)) && event['startDate'].to_date >= Date.today
          events << event
        end
      end
    end

    events.sort_by { |k, v| k['startDate'] }.first(50)
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
    events['results'].sort_by { |k, v| k['time'] }.first(50)
  end

  def get_facebook_events

    if @query == '' || @query.nil?
      @queries = ['gbg', 'gothenburg', 'goteborg']
    else
      @queries = [@query + ' gbg', @query + ' gothenburg', @query + ' goteborg']
    end

    events = []

    @queries.each do |query|
      request = HTTParty.get("https://graph.facebook.com/search?q=#{query}&type=event&center=57.7089,11.9746&distance=1000&access_token=#{ENV['FACEBOOK_CODE']}&fields=description,place,name,start_time&until=#{@date_query}")
      request['data'].each do |event|
        if event['start_time'].to_date >= Date.today
          events << event
        end
      end
    end
    events.sort_by { |k, v| k['start_time'] }
  end

  def get_grid_number
    number = 4
    number += 2 if @events_json.empty?
    number += 2 if @facebook_events.empty?
    number += 2 if @city_json.empty?
    number == 8 ? 12 : number
  end

  def get_pustervik_events
    @pustervik_events = []
    page = Nokogiri::HTML(open('http://pustervik.nu/category/arkiv-event/'), nil, 'UTF-8')
    page.css('div.textwidget')[1].css('p').each do |event|
      @pustervik_events << event
    end
    @pustervik_events.delete_at(0)
    @pustervik_events = @pustervik_events[0].to_s.split('<br>')
    @pustervik_events.delete_at(0)
    @pustervik_events.each do |event|
      # Add the pustervik URL
      event.gsub!(/c\=\"/, 'c="http://www.pustervik.nu')
      event.gsub!(/f\=\"/, 'f="http://www.pustervik.nu')
    end
  end

end