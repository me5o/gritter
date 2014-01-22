#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-
require 'faraday'
require 'json'
require 'date'
require 'pp'

class EventManager
  attr_reader :user_id

  def initialize(id)
    base_url = 'http://tweetvite.com'

    @user_id = id
    @http = Faraday.new(:url => base_url) do |faraday|
      faraday.request  :url_encoded
#      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end
  end

  def events(raw = false)
    #/api/1.0/rest/users/events_created?user_id=**********&format=json
    params = {
      :user_id => @user_id,
      :format => "json"
    }
    res = @http.get '/api/1.0/rest/users/events_created', params
    list = JSON.parse(res.body)

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
    #/api/1.0/rest/events/guest_list?public_id=ExampleAPI&format=json
    params = {
      :public_id => event_id,
      :format => "json"
    }
    ans_map = { "Y" => :yes, "M" => :maybe, "N" => :no }
    res = @http.get '/api/1.0/rest/events/guest_list', params
    list = JSON.parse(res.body)

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
end


