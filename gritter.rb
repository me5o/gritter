#!/opt/local/bin/ruby -Ku
require 'rubygems'
require 'twitter'
require 'gcalapi'
require 'yaml'
require 'uri'
require 'json'

class Gritter
  def initialize(env = "development")
    @conf = YAML.load_file(File.dirname(__FILE__) + "/gritter.yml")
    @conf = @conf[env]
    if @conf["twitter"]
#      oauth = Twitter::OAuth.new(
#        @conf["twitter"]["consumer_key"],@conf["twitter"]["consumer_secret"])
#      oauth.authorize_from_access(
#        @conf["twitter"]["access_token"],@conf["twitter"]["access_secret"])
#      @twitter = Twitter::Base.new(oauth)

      Twitter.configure do |config|
        config.consumer_key = @conf["twitter"]["consumer_key"]
        config.consumer_secret = @conf["twitter"]["consumer_secret"]
        config.oauth_token = @conf["twitter"]["access_token"]
        config.oauth_token_secret = @conf["twitter"]["access_secret"]
      end
      @twitter = Twitter::Client.new
    end
    
    @google = GoogleCalendar::Service.new(
      @conf["google"]["id"],@conf["google"]["password"])
    @feed = @conf["google"]["calendar_feed"]
  end

  def schedule(index = "default", option = {})
    option.merge!({ "max-results" => 999, "orderby" => "starttime", "sortorder" => "ascending" })
    cal = GoogleCalendar::Calendar.new(@google, @feed[index])
    cal.events(option)
  end

  def talk(message, limit = 1024, shrink = true)
    message = shrink_url(message) if shrink
    if message.split(//u).size > limit
      message = message.split(//u)[0..limit - 2].join + "…"
    end
    puts message
    @twitter.update(message) if @twitter
  end

  def collect(keyword, since = nil)
    since ||= Date.today - 1
    since = since.strftime("%Y-%m-%d")
    if @twitter
      rts = []
      @twitter.retweeted_by_me(:trim_user => true).each do |item|
        rts << item["retweeted_status"]["id"]
      end

      Twitter::Search.new.language("ja").hashtag(keyword).not_from("GSOOBOG").since_date(since).per_page(100).to_a.reverse.each do |item|
        if rts.include?(item["id"])
          puts "[ALEADY EXISTS]#{item["id"]} @#{item["created_at"]} #{item["text"]}"
        else
          puts "[RT]#{item["id"]} @#{item["created_at"]} #{item["text"]}"
          @twitter.retweet(item["id"])
          sleep 1
        end
      end
    end
  end

  private
  def shrink_url(src)
    ret = src.clone
    URI.extract(src, %w[http https]) do |url|
      conf = @conf['bitly']
      query = "version=#{conf['version']}&longUrl=#{url}&login=#{conf['id']}&apiKey=#{conf['api_key']}"
      result = JSON.parse(Net::HTTP.get("api.bit.ly", "/shorten?#{query}"))
      result['results'].each_pair do |long_url, value|
        ret.gsub! long_url, value['shortUrl']
      end 
    end
    ret
  end
end

class GoogleCalendar::Event
  def to_message(format = ":date : :title :where (:desc)")
    val = {"title" => "", "where" => "", "desc" => "", "date" => ""}

    val["title"] = self.title
    val["where"] = "at " + self.where unless self.where.empty?
    val["desc"] = self.desc.split("\n").first unless self.desc.nil?
    if self.allday
      val["date"] = self.st.getlocal.strftime("%m/%d(%a)")
    else
      date_from = self.st.getlocal.strftime("%m/%d(%a) %H:%M")
      date_to =  self.en.getlocal.strftime("%H:%M")
      val["date"] = "#{date_from}-#{date_to}"
    end

    ret = format.clone
    val.each_pair do |key, val|
      ret.gsub! ":#{key}", val 
    end
    ret.strip
  end
end

if $0 == __FILE__
  gritter = Gritter.new
  gritter.schedule("default", "start-min" => Date.today + 0,"start-max" => Date.today + (2 - 1/24/60/60)).each do |event|
    gritter.talk event.to_message, 140
    sleep 1
  end
end
