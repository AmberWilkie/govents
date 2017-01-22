require 'nokogiri'
require 'open-uri'

class Events::EventsController < ApplicationController

  def index
    @events_json = nil
    render 'events/index'
  end

  def get_events
    @query = params[:query]
    @events_json = get_meetup_events
    @library_events = get_library_events
    @library_children = @library_events.css('div.isotope').children.length
    render 'events/index'
  end

  private

  def get_library_events
    page = Nokogiri::HTML(open("https://goteborg.se/wps/portal/?uri=gbglnk:kalendarium-ck&searchstring=#{@query}&date=halfyear&type=freetext"),
                          nil,
                          'UTF-8')
  end

  def get_meetup_events

    params = {text: @query,
              lon: '11.9746',
              lat: '57.7089',
              country: 'se',
              status: 'upcoming',
              format: 'json',
              page: '100'}
    meetup_api = MeetupApi.new
    events = meetup_api.open_events(params)

  end

end