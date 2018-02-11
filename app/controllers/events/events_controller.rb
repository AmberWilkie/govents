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

    begin
      @events_json = Rails.cache.fetch("meetup", expires_in: 30.minutes) do
        @events_json = get_meetup_events
      end
    rescue
      @events_json = []
    end

    begin
      @city_json = Rails.cache.fetch("gbg_stad", expires_in: 30.minutes) do
        @city_json = get_city_events
      end
    rescue
      @city_json = []
    end

    begin
      @facebook_events = Rails.cache.fetch("facebook", expires_in: 30.minutes) do
        @facebook_events = get_facebook_events
      end
    rescue
      @facebook_events = []
    end
    puts 'something'

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
    page = Nokogiri::HTML(open('http://pustervik.nu/kalender/'), nil, 'UTF-8')
    page.xpath("//ul")[3].css('li.event').each do |event|
      pustervik_events << event.to_s
    end
    pustervik_events.delete_at(0)
    pustervik_events.delete_at(0)

    events = pustervik_events.map do |event|
      # Add the pustervik URL
      event.gsub!(/c\=\"/, 'c="http://www.pustervik.nu')
      event.gsub!(/f\=\"/, 'f="http://www.pustervik.nu')

      # Get the title for the accordion
      index = pustervik_events.find_index(event)
      h2 = Nokogiri.HTML(pustervik_events[index]).css('h2')
      title = "#{h2.children.css('span').text} #{h2.children[2].text}"
      {title: title, description: event}
    end
    events
  end

  def get_gu_events
    gu_events = []
    page = Nokogiri::HTML(open('https://www.gu.se/english/about_the_university/news-calendar/Calendar'), nil, 'UTF-8')
    page.css('div.record').each do |event|
      gu_events << event.to_s
    end
    gu_events
  end

  def get_chalmers_events
    chalmers_events = []
    page = Nokogiri::XML(open('https://www.chalmers.se/sv/om-chalmers/kalendarium/Sidor/default.aspx'), nil, 'UTF-8')
    page.css('div.item').each do |event|
      hash = {}
      hash[:description] = {
        time: event&.children&.css('div.calendar')&.first&.to_s,
        text: event&.children&.css('div.desc')&.first&.to_s 
      }
      hash[:title] = event&.css('div.desc.visible-xs')&.css('span')&.text
      chalmers_events << hash
    end
    chalmers_events
  end

end
