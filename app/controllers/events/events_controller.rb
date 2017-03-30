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
    @pustervik_events = Rails.cache.fetch("pustervik", expires_in: 30.minutes) do
      @pustervik_events = get_pustervik_events
    end

    @gu_events = Rails.cache.fetch("ugbg", expires_in: 30.minutes) do
      @gu_events = get_gu_events
    end

    @chalmers_events = Rails.cache.fetch("chalmers", expires_in: 30.minutes) do
      @chalmers_events = get_chalmers_events
    end

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
    pustervik_events = []
    page = Nokogiri::HTML(open('http://pustervik.nu/category/arkiv-event/'), nil, 'UTF-8')
    page.css('div.textwidget')[1].children.each do |event|
      pustervik_events << event.to_s
    end
    pustervik_events.delete_at(0)
    pustervik_events.delete_at(0)
    pustervik_events.each do |event|
      # Add the pustervik URL
      event.gsub!(/c\=\"/, 'c="http://www.pustervik.nu')
      event.gsub!(/f\=\"/, 'f="http://www.pustervik.nu')
    end
    pustervik_events
  end

  def get_gu_events
    gu_events = []
    page = Nokogiri::HTML(open('http://www.gu.se/english/about_the_university/news-calendar/Calendar'), nil, 'UTF-8')
    page.css('div.record').each do |event|
      gu_events << event.to_s
    end
    gu_events
  end

  def get_chalmers_events
    chalmers_events = []
    page = Nokogiri::XML(open('http://www.chalmers.se/en/about-chalmers/calendar/_layouts/ChalmersPublicWeb/EventsRSS.aspx?categories=7db7bdaf-b5f2-4853-a2a1-ea24465cbf16|1584214e-dd8f-4cb4-bf25-fe92608bebfa|8fdbc553-8c2b-466b-aa61-cbe81c2412a4&locations=34f62c47-a64f-4193-b9a2-fca6e16df0a9'), nil, 'UTF-8')
    page.css('item').each do |event|
      hash = {}
      hash[:description] = event.css('description')[0].children[0].text.gsub('f="/', 'f="http://www.chalmers.se/').gsub('c="/', 'c="http://www.chalmers.se/')
      hash[:link] = event.children[0].children[0].text
      hash[:title] = event.children[2].children[0].text
      chalmers_events << hash
    end
    chalmers_events
  end

end