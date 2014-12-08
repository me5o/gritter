#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-
$:.unshift(File.dirname(__FILE__))
require 'gritter'

def talk_event(me, event_date, tpl = nil, cal = "default", keyword = nil)
  tpl ||= "[イベント情報]『:title』:date :where #event :desc"
  dates = event_date.is_a?(Array) ? event_date : [event_date]
  dates << dates[0] if dates.size == 1
  dates.map! {|item| item.is_a?(Date) ? item.to_time : item}
  day = 60 * 60 * 24
  opt = { "timeMin" => dates[0], "timeMax" => dates[1] + (day - 1) }
  opt["q"] = keyword if keyword
  me.schedule(cal, opt).each do |event|
    me.talk me.event_to_message(event, tpl), 140
    sleep 1
  end
end

Dir.chdir(File.dirname(__FILE__))

gritter = Gritter.new(ARGV[0], "./gritter.yml")

puts "start gritter."

#this week schedule
nextsunday = Date.today - Date.today.wday + 7
tpl = "今週 :date は『:title』があるぐりっ！ :where #gsojp :desc".strip
talk_event(gritter, [Date.today + 2, nextsunday], tpl)

puts "start 2289bb."

bb2289 = Gritter.new(ARGV[0], "./2289bb.yml")

#this week schedule
tpl = "今週は『:title』です。 :date :where #2289bb :desc"
talk_event(bb2289, [Date.today + 2, nextsunday], tpl)

#member info
tpl = "[メンバー情報]『:title』是非！ :date :where #2289bb :desc"
talk_event(bb2289, [Date.today + 2, nextsunday], tpl, "members")

puts "end."

