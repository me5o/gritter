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

#this week schedule
nextsunday = Date.today - Date.today.wday + 7
tpl = "今週 :date は『:title』があるぐりっ！ :where #gsojp :desc".strip
talk_event(gritter, [Date.today + 2, nextsunday], tpl)

puts "start 2289bb."

bb2289 = Gritter.new($ARGV[0], "./2289bb.yml")

#this week schedule
tpl = "今週は『:title』ですっ。 :date :where #2289bb :desc"
talk_event(bb2289, [Date.today + 2, nextsunday], tpl)

#member info
tpl = "[メンバー情報]『:title』是非！ :date :where #2289bb :desc"
talk_event(bb2289, [Date.today + 2, nextsunday], tpl, "members")

puts "end."

