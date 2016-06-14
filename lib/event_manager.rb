#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-
require 'faraday'
require 'nokogiri'
require 'json'
require 'icalendar'
require 'pp'

module EventManager
  class Base
    BASE_URL = nil
    attr_reader :user_id

    def initialize(id)
      @user_id = id
      @http = Faraday.new(:url => self.class::BASE_URL) do |faraday|
        faraday.request  :url_encoded
        faraday.adapter  Faraday.default_adapter
      end
    end

    def events(raw = false)
      list = get_events_list

      if raw
        ret = list
      else
        ret = []
        list["events"].each do |evt|
          if evt["canceled"] == false
            ret << {
              :id => evt["public_id"],
              :name => evt["title"],
              :start_date =>  Date.parse(evt["date"]["start_date"]),
              :url => evt["links"]["invitation_tiny"],
            }
          end
        end
      end
      ret
    end

    def event_guests(event_id, ans = :all, raw = false)
      ans_map = { "Y" => :yes, "M" => :maybe, "N" => :no }
      list = get_event_guests_list(event_id)

      if raw
        ret = list
      else
        ret = []
        list["guests"].each do |guest|
          if guest["profile"]["service_type"] == "1" #Twitter
            rsvp = guest["rsvp"]
            if ans == :all || ans == ans_map[rsvp]
              ret << {
                :display_name => guest["profile"]["display_name"],
                :name => guest["profile"]["name"],
                :rsvp => ans_map[rsvp]
              }
            end
          end
        end
      end
      ret
    end

    private
    def get_events_list #must overridde
      {}
    end

    def get_event_guests_list(event_id) #must overridde
      {}
    end
  end

  class Tweetvite < Base
    BASE_URL = 'http://tweetvite.com'

    private
    def get_events_list
      #/api/1.0/rest/users/events_created?user_id=**********&format=json
      params = {
        :user_id => @user_id,
        :format => "json"
      }
      res = @http.get '/api/1.0/rest/users/events_created', params
      JSON.parse(res.body)
    end

    def get_event_guests_list(event_id)
      #/api/1.0/rest/events/guest_list?public_id=ExampleAPI&format=json
      params = {
        :public_id => event_id,
        :format => "json"
      }
      res = @http.get '/api/1.0/rest/events/guest_list', params
      JSON.parse(res.body)
    end
  end

  class Twipla < Base
    BASE_URL = 'http://twipla.jp'

    private
    def get_events_list
      #/users/******
      path = "/users/#{@user_id}"
      res = @http.get path

      doc = Nokogiri::HTML(res.body)
      query = "//span[@class='status-body' and preceding-sibling::span[1]/a/@href='#{path}']//a[starts-with(@href, '/events/')]/@href"
      events = []
      doc.xpath(query).each do |node|
        res = @http.get "#{node.text}/.ics"
        cal = Icalendar.parse(res.body.force_encoding("utf-8")).first
        event = cal.events.first

        evt = {
          "event_id" => event.url.path.split("/")[-1],
          "public_id" => event.url.path.split("/")[-1],
          "hosted_by" => "@#{@user_id}",
          "title" => event.summary,
          "date" => {
            "start_date" => event.dtstart.strftime("%Y/%m/%d"),
          },
          "description" => event.description,
          "links" => {
            "invitation" => event.url.to_s,
            "invitation_tiny" => event.url.to_s,
          },
          "canceled" => false,
        }
        events << evt
        sleep 1
      end
      { "events" => events }
    end

    def get_event_guests_list(event_id)
      #/events/*******
      res = @http.get "/events/#{event_id}"

      ans_type = {
        :yes => /^参加者 \([0-9]+人\)/,
        :maybe => /^興味あり \([0-9]+人\)/,
        :no => /^不参加 \([0-9]+人\)/,
      }
      guests = []
      doc = Nokogiri::HTML(res.body)
      doc.css('div.member_list').each do |node|
        rsvp = nil
        case node.content
        when ans_type[:yes]   then rsvp = "Y"
        when ans_type[:maybe] then rsvp = "M"
        when ans_type[:no]    then rsvp = "N"
        end

        if rsvp
          node.css('a.namelist').each do |a|
            id = a.attributes["s"].value
            name = a.attributes["n"].value
            image_url = a.parent.xpath("img/@src")
            image_url = image_url.empty? ? nil : image_url.first.value
            guests << {
              "userid" => id,
              "rsvp" => rsvp,
              "profile" => {
                "service_type" => "1",  #Twitter
                "name" => id,
                "profile_image_url" => image_url,
                "display_name" => name,
                "url" => "#{self.class::BASE_URL}/users/#{id}",
                "profile_url" => nil,
              },
            }
          end
        end
      end
      { "guests" => guests }
    end
  end
end

#evt = EventManager::Twipla.new("2289bb")
#g = evt.event_guests("77786")
