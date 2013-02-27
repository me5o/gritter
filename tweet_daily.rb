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
tpl = "本日ぐりっ！『:title』 :date :where #gsojp :desc"
talk_event(gritter, Date.today, tpl)

#tommorow schedule
tpl = "明日は『:title』があるぐりっ！ :date :where #gsojp :desc"
talk_event(gritter, Date.today + 1, tpl)

#countdown event
tpl = "『:title』[:date]まで残り:remain日！ #gsojp :desc"
talk_event(gritter, [Date.today + 1, Date.today + 365], tpl, "countdown")

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
gritter.collect("#gsob", Date.today - 1)

puts "start 2289bb."

bb2289 = Gritter.new($ARGV[0], "./2289bb.yml")

#today schedule
tpl = "本日です！『:title』 :date :where #2289bb :desc"
talk_event(bb2289, Date.today, tpl)

#tommorow schedule
tpl = "明日は『:title』です。 :date :where #2289bb :desc"
talk_event(bb2289, Date.today + 1, tpl)

#sipmle tweet
tpl = ":desc #2289bb"
talk_event(bb2289, Date.today, tpl, "simple")

#member info
tpl = "[メンバー情報]『:title』明日です！ :date :where #2289bb :desc"
talk_event(bb2289, Date.today + 1, tpl, "members")

#countdown event
tpl = "『:title』[:date]まで残り:remain日！ #2289bb :desc"
talk_event(bb2289, [Date.today + 1, Date.today + 365], tpl, "countdown")

#new commer
members = bb2289.members("twizz-members", true)
if members.size < 5
  members.each do |key, val|
    bb2289.talk "[メンバー情報] メンバーに @#{val} さんが加わりました！ http://bit.ly/Hw7U9V #2289bb", 140
    sleep 1
  end
else
  puts "[warning] メンバーに5件以上の追加がありました。投稿を保留しました : " + members.values.join(", ")
end

puts "end."

