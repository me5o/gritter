#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-
require 'rubygems'
require 'twitter'
require 'google/api_client'
require 'yaml'
require 'uri'
require 'cgi'
require 'json'
require 'pp'
require 'lib/event_manager'

class Gritter
  attr_reader :twitter, :event_manager

  def initialize(env = "development", yml = nil)
    yml ||= File.dirname(__FILE__) + "/gritter.yml"
    @conf = YAML.load_file(yml)
    @conf = @conf[env]
    if @conf["twitter"]
#      Twitter.configure do |config|
#        config.consumer_key = @conf["twitter"]["consumer_key"]
#        config.consumer_secret = @conf["twitter"]["consumer_secret"]
#        config.oauth_token = @conf["twitter"]["access_token"]
#        config.oauth_token_secret = @conf["twitter"]["access_secret"]
#      end

      @twitter = Twitter::Client.new(
        :consumer_key => @conf["twitter"]["consumer_key"],
        :consumer_secret => @conf["twitter"]["consumer_secret"],
        :oauth_token => @conf["twitter"]["access_token"],
        :oauth_token_secret => @conf["twitter"]["access_secret"]
      )
    end

    @google = Google::APIClient.new(:application_name => 'Gritter')
    key = Google::APIClient::KeyUtils.load_from_pkcs12(@conf["google"]["key"], @conf["google"]["password"])
    @google.authorization = Signet::OAuth2::Client.new(
      :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
      :audience => 'https://accounts.google.com/o/oauth2/token',
      :scope => 'https://www.googleapis.com/auth/calendar.readonly',
      :issuer => @conf["google"]["mail"],
      :signing_key => key
    )
    @google.authorization.fetch_access_token!
    @feed = @conf["google"]["calendar_feed"]

    if @conf["tweetvite"]
      @event_manager = EventManager.new(@conf["tweetvite"]["id"])
    end
  end

  def schedule(index = "default", option = {})
    option.merge!({
      "calendarId" => @feed[index],
      "maxResults" => 999,
      "orderBy" => "startTime",
      "singleEvents" => "True"
    })
    option["timeMax"] = option["timeMax"].iso8601 if option["timeMax"]
    option["timeMin"] = option["timeMin"].iso8601 if option["timeMin"]

    cal = @google.discovered_api('calendar', 'v3')
    result = @google.execute(:api_method => cal.events.list, :parameters => option)
#    result.data.items
#    全日イベントのみUTC基準で検索されるので範囲外のイベントは手動で除外
    items = []
    result.data.items.each do |item|
#        if item.start.respond_to?(:dateTime)
        if item.start.date.nil?
            items << item
        else
            date_from = DateTime.parse(item.start.date) - Rational(9, 24)
            date_to = DateTime.parse(item.end.date) - Rational(9, 24) - Rational(1, 3600)
            date_min = DateTime.parse(option["timeMin"])
            date_max = DateTime.parse(option["timeMax"])
            if date_from.between?(date_min, date_max) || date_to.between?(date_min, date_max)
                item.start.date = date_from.to_time.getlocal.strftime("%Y-%m-%d")
                item.end.date = date_to.to_time.getlocal.strftime("%Y-%m-%d")
                items << item
            end
        end
    end
    items
  end

  def talk(message, limit = 140, shrink = true)
    message = truncate_message(message, limit, shrink)
    puts message
    @twitter.update(message) if @twitter
  end

  def talk_to(user, message, is_private = true, limit = 138, shrink = true)
    users = user.kind_of?(Array) ? user : [ user ]
    if is_private # direct message
      users.each_with_index do |u, idx|
        sleep 10 if idx > 0
        message = truncate_message(message, limit, shrink)
        puts "[To : #{u}] #{message}"
        @twitter.direct_message_create(u, message) if @twitter
      end
    else # public mention
      messages = []
      user_str = ""
      buff = message
      users.each do |u|
        user_str = "@#{u} "
        if (user_str + buff).size > limit
          if buff == message
            messages << user_str + buff
          else
            messages << buff
            buff = user_str + message
          end
        else
          buff = user_str + buff
        end
      end
      messages << buff if buff != message

      messages.each_with_index do |msg, idx|
        sleep 10 if idx > 0
        talk msg, limit, shrink
      end
    end
  end

  def members(group_name, new = false)
    ids = {}
    if @twitter
      i = -1
      until i == 0
        list_members = @twitter.list_members(group_name, :cursor => i)
        list_members.users.each do |member|
          ids[member["id"]] = member["screen_name"]
        end
        i = list_members.next_cursor
        sleep(1)
      end

      if new
        id = @twitter.user.screen_name
        data_dir = File.dirname(__FILE__) + "/data/#{id}/"
        path = data_dir + "#{group_name}.yml"
        old_ids = File.exists?(path) ? YAML.load_file(path) : ids
        Dir.mkdir(data_dir) unless File.exists?(data_dir)
        open( path, "w" ) do |f|
          f.write ids.to_yaml
        end

        ids.delete_if do |key, val|
          old_ids.key?(key)
        end
      end
    end
    ids
  end

  def messages(option = {})
    if @twitter
      @twitter.user_timeline(@twitter.user.id, option)
    end
  end

  def collect(keyword, since = nil, option = {})
    since ||= Date.today - 1
    since = since.strftime("%Y-%m-%d")
    if @twitter
      me = @twitter.user.screen_name
      rts = []
      @twitter.retweeted_by_me(:trim_user => true).each do |item|
        rts << item["retweeted_status"]["id"]
      end

#      Twitter::Search.new.language("ja").hashtag(keyword).not_from("GSOOBOG").since_date(since).per_page(100).to_a.reverse.each do |item|
      @twitter.search("#{keyword} -rt -from:#{me} since:#{since}", :result_type => 'recent', :lang => "ja", :count => 100).results.reverse_each do |item|
        if rts.include?(item.id)
#          puts "[ALEADY EXISTS]#{item.id} at #{item.created_at} #{item.user.screen_name} : #{item.text}"
        else
#          puts "#{item.id} at #{item.created_at} #{item.user.screen_name} : #{item.text}"
          is_collect = true
          if option[:filter]
            is_collect = is_collect && ( item.text =~ option[:filter] )
          end
          if option[:from]
            is_collect = is_collect && option[:from].include?(item.user.id)
          end

          if is_collect
            puts "[RT]#{item.id} at #{item.created_at} #{item.user.screen_name} : #{item.text}"
            @twitter.retweet(item.id)
            sleep 1
          end
        end
      end
    end
  end

  def event_to_message(event, format = ":date : :title :where (:desc)")
    val = {"title" => "", "where" => "", "desc" => "", "date" => "", "remain" => ""}
    st = nil

    val["title"] = event.summary
    val["where"] = "at " + event.location unless event.location.nil?
    val["desc"] = event.description.split("\n").first unless event.description.nil?
    unless event.start.date.nil?
      st = Date.strptime(event.start.date, "%Y-%m-%d")
      val["date"] = st.strftime("%m/%d(#{%w(日 月 火 水 木 金 土)[st.wday]})")
    else
      st = event.start.dateTime.getlocal
      date_from = st.strftime("%m/%d(#{%w(日 月 火 水 木 金 土)[st.wday]}) %H:%M")
      date_to =  event.end.dateTime.getlocal.strftime("%H:%M")
      val["date"] = "#{date_from}-#{date_to}"
    end
    val["remain"] = (Date.new(st.year, st.month, st.day) - Date.today).truncate.to_s

    ret = format.clone
    val.each_pair do |key, val|
      ret.gsub! ":#{key}", val
    end
    ret.strip
  end

  private
  def shrink_url(src)
    ret = src.clone
    URI.extract(src, %w[http https]) do |url|
      if URI.parse(url).host != "bit.ly" && url.length > 20
        conf = @conf['bitly']
        query = "version=#{conf['version']}&longUrl=#{CGI.escape(url)}&login=#{conf['id']}&apiKey=#{conf['api_key']}"
        result = JSON.parse(Net::HTTP.get("api.bit.ly", "/shorten?#{query}"))
        unless result['results'].nil?
          result['results'].each_pair do |long_url, value|
            ret.gsub! long_url, value['shortUrl']
          end
        end
      end
    end
    ret
  end

  def truncate_message(message, limit, shrink)
    message = shrink_url(message) if shrink
    if message.split(//u).size > limit
      message = message.split(//u)[0..limit - 2].join + "…"
    end
    message
  end
end

#class Google::APIClient::Schema::Calendar::V3::Event
#  def to_message(format = ":date : :title :where (:desc)")
#    val = {"title" => "", "where" => "", "desc" => "", "date" => "", "remain" => ""}
#
#    val["title"] = self.summary
#    val["where"] = "at " + self.location unless self.location.nil?
#    val["desc"] = self.description.split("\n").first unless self.description.nil?
#    st = self.start.dateTime.getlocal
#    val["remain"] = (Date.new(st.year, st.month, st.day) - Date.today).truncate.to_s
#    unless self.start.date.nil?
#      val["date"] = st.strftime("%m/%d(#{%w(日 月 火 水 木 金 土)[st.wday]})")
#    else
#      date_from = st.getlocal.strftime("%m/%d(#{%w(日 月 火 水 木 金 土)[st.wday]}) %H:%M")
#      date_to =  self.end.dateTime.getlocal.strftime("%H:%M")
#      val["date"] = "#{date_from}-#{date_to}"
#    end
#
#    ret = format.clone
#    val.each_pair do |key, val|
#      ret.gsub! ":#{key}", val
#    end
#    ret.strip
#  end
#end

if $0 == __FILE__
  gritter = Gritter.new
  gritter.schedule("default", "start-min" => Date.today + 0,"start-max" => Date.today + (2 - 1/24/60/60)).each do |event|
    gritter.talk event.to_message, 140
    sleep 1
  end
end
