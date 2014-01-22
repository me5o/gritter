#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-
$:.unshift(File.dirname(__FILE__))
require 'gritter'

def talk_event(me, event_date, tpl = nil, cal = "default", keyword = nil)
  tpl ||= "[イベント情報]『:title』:date :where #event :desc"
  dates = event_date.is_a?(Array) ? event_date : [event_date]
  dates << dates[0] if dates.size == 1
  sec = 1/24/60/60
  opt = { "start-min" => dates[0], "start-max" => dates[1] + (1 - sec) }
  opt["q"] = keyword if keyword
  me.schedule(cal, opt).each do |event|
    me.talk event.to_message(tpl), 140
    sleep 1
  end
end

Dir.chdir(File.dirname(__FILE__))

gritter = Gritter.new(ARGV[0], "./gritter.yml")

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

bb2289 = Gritter.new(ARGV[0], "./2289bb.yml")

#today schedule
tpl = "本日です！『:title』 :date :where #2289bb :desc"
talk_event(bb2289, Date.today, tpl)

#tommorow schedule
tpl = "明日は『:title』です。 :date :where #2289bb :desc"
talk_event(bb2289, Date.today + 1, tpl)

#rsvp schedule
tpl = "[出欠]『:title』[:date]まで残り:remain日。20日前までに以下URLより一次回答して下さい。未定の場合も[Maybe]で回答して下さい #2289bb :desc"
talk_event(bb2289, [Date.today + 20, Date.today + 23], tpl, "default", "#rsvp")
tpl = "[出欠]『:title』[:date]まで残り:remain日。10日前までに以下URLより回答して下さい。[Maybe]不可。Maybeの方は回答を確定して下さい #2289bb :desc"
talk_event(bb2289, [Date.today + 10, Date.today + 13], tpl, "default", "#rsvp")

members = bb2289.members("active-members")
bb2289.event_manager.events.each do |evt|
  diff = (evt[:start_date] - Date.today).to_i
  if diff < 20 && diff > 10
    answerd = []
    bb2289.event_manager.event_guests(evt[:id]).each do |g|
      answerd << g[:display_name]
    end
    not_answerd = members.values - answerd

    if (not_answerd.size.to_f / member.values.size.to_f) < 0.5
      msg = "[出欠未回答]『#{evt[:name]}』一次回答の期限を過ぎています。不明な場合も[Maybe]で登録。回答用URLは #2289bb を参照。※このDMに返信しないで"
      bb2289.talk_to not_answerd, msg, true, 140

      msg = "[出欠未回答]『#{evt[:name]}』一次回答の期限を過ぎています→ #{evt[:url]} #2289bb 不明な場合も[Maybe]で登録"
      bb2289.talk_to not_answerd, msg, false, 140, false
    else
      puts "[warning]『#{evt[:name]}』50%以上が未回答の為、投稿を保留しました"
    end
  end
end

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

