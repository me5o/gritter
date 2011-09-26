#!/opt/loacl/bin/ruby -Ku
$:.unshift(File.dirname(__FILE__))
require 'gritter'

def talk_event(me, event_date, tpl = nil, cal = "default")
  tpl ||= "[イベント情報]『:title』:date :where #event :desc"
  dates = event_date.is_a?(Array) ? event_date : [event_date]
  dates << dates[0] if dates.size == 1
  sec = 1/24/60/60
  me.schedule(cal, "start-min" => dates[0], "start-max" => dates[1] + (1 - sec)).each do |event|
    me.talk event.to_message(tpl), 140
    sleep 1
  end
end

Dir.chdir(File.dirname(__FILE__))

gritter = Gritter.new($ARGV[0], "./gritter.yml")

puts "start gritter."

#tommorow schedule
tpl = "明日は『:title』があるぐりっ！ :date :where #gsojp :desc"
talk_event(gritter, Date.today + 1, tpl)

#aniversary
tpl = "今日は:titleぐりっ (-人-) #bigband :desc"
talk_event(gritter, Date.today, tpl, "aniversary")

#this week schedule (created after yestarday)
#nextsunday = Date.today - Date.today.wday + 7
#gritter.schedule("start-min" => Date.today, "start-max" => nextsunday + (1 - sec).each do |event|
#  gritter.talk event.to_message, 140
#  sleep 1
#end

#collect relative message
gritter.collect("gsob", Date.today - 1)

puts "start 2289bb."

bb2289 = Gritter.new($ARGV[0], "./2289bb.yml")

#tommorow schedule
tpl = "明日は『:title』ですっ。 :date :where #2289bb :desc"
talk_event(bb2289, Date.today + 1, tpl)

#member info
tpl = "[メンバー情報]『:title』明日です！ :date :where #2289bb :desc"
talk_event(bb2289, Date.today + 1, tpl, "members")

#countdown event
tpl = "『:title』[:date]まで残り:remain日！ #2289bb :desc"
talk_event(bb2289, [Date.today + 1, Date.today + 365], tpl, "countdown")

puts "end."

