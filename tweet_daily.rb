#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-
$:.unshift(File.dirname(__FILE__))
require 'gritter'

def talk_event(me, event_date, tpl = nil, cal = "default", keyword = nil)
  day = 60 * 60 * 24
  tpl ||= "[イベント情報]『:title』:date :where #event :desc"
  dates = event_date.is_a?(Array) ? event_date : [event_date]
  dates.map! {|item| item.is_a?(Date) ? item.to_time : item}
  dates << dates[0] + (day - 1) if dates.size == 1
#  dates.collect! {|d| d.utc }
  opt = { "timeMin" => dates[0], "timeMax" => dates[1] }
  opt["q"] = keyword if keyword
  me.schedule(cal, opt).each do |event|
    me.talk me.event_to_message(event, tpl), 140
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
talk_event(bb2289, [Date.today + 20, Date.today + 21], tpl, "default", "#rsvp")
tpl = "[出欠]『:title』[:date]まで残り:remain日。回答確定期限ですので本日中にURLより回答確定して下さい([Maybe]不可) #2289bb :desc"
talk_event(bb2289, Date.today + 10, tpl, "default", "#rsvp")

admins = bb2289.members("admin")
members = bb2289.members("active-members")
bb2289.event_manager.events.each do |evt|
  diff = (evt[:start_date] - Date.today).to_i
  case diff
  when 11..20
    answerd = []
    bb2289.event_manager.event_guests(evt[:id]).each do |g|
      answerd << g[:display_name]
    end
    not_answerd = members.values - answerd

    if (not_answerd.size.to_f / members.values.size.to_f) < 0.9
      if diff == 20
        msg = "[出欠未回答]『#{evt[:name]}』一次回答、本日まで！不明な場合も[Maybe]で登録。回答用URLは #2289bb を参照。※このDMに返信しないで"
#        msg = "[出欠未回答]『#{evt[:name]}』一次回答、本日まで！不明な場合も[Maybe]で登録。#{evt[:url]} ※このDMに返信しないで"
        bb2289.talk_to not_answerd, msg, true, 140
      else
        msg = "[出欠未回答]『#{evt[:name]}』一次回答の期限を過ぎています。不明な場合も[Maybe]で登録。回答用URLは #2289bb を参照。※このDMに返信しないで"
#        msg = "[出欠未回答]『#{evt[:name]}』一次回答の期限を過ぎています。不明な場合も[Maybe]で登録。#{evt[:url]} ※このDMに返信しないで"
        bb2289.talk_to not_answerd, msg, true, 140

        msg = "[出欠未回答]『#{evt[:name]}』一次回答の期限を過ぎています→ #{evt[:url]} #2289bb 不明な場合も[Maybe]で登録"
#        msg = "[出欠未回答]『#{evt[:name]}』一次回答の期限を過ぎています→ #{evt[:url]} 不明な場合も[Maybe]で登録"
        bb2289.talk_to not_answerd, msg, false, 140, false
      end
    else
      msg = "[WARN]『#{evt[:name]}』未回答者90%を超えている為、投稿を保留しました"
      bb2289.talk_to admins.values, msg, true, 140
    end
  when 10
    bb2289.event_manager.event_guests(evt[:id]).each do |g|
      if members.values.include?(g[:display_name])
        msg = "[出欠確認]『#{evt[:name]}』のあなたの回答は[#{g[:rsvp]}]です。"
        if g[:rsvp] == :maybe
          msg << "本日中に回答を確定して下さい。(maybe不可) "
        else
          msg << "変更がある場合は本日中に！早退/遅刻は必ずコメント欄に！"
        end
        msg << "回答用URLは #2289bb を参照。※このDMに返信しないで"
  #      msg << " #{evt[:url]} ※このDMに返信しないで"
        bb2289.talk_to g[:display_name], msg, true, 140
        sleep 15
      end
    end
  when 9
    not_answerd = []
    bb2289.event_manager.event_guests(evt[:id], :maybe).each do |g|
      not_answerd << g[:display_name] if members.values.include?(g[:display_name])
    end
    msg = "『#{evt[:name]}』二次回答期限を過ぎています(Maybe不可)→ #{evt[:url]} #2289bb 確定できない場合はページに見通しをコメント"
#    msg = "『#{evt[:name]}』二次回答期限を過ぎています(Maybe不可)→ #{evt[:url]} 確定できない場合はページに見通しをコメント"
    bb2289.talk_to not_answerd, msg, false, 140, false
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
new_members = bb2289.members("twizz-members", true)
if new_members.size < 5
  new_members.each do |key, val|
    bb2289.talk "[メンバー情報] メンバーに @#{val} さんが加わりました！ http://bit.ly/Hw7U9V #2289bb", 140
    sleep 1
  end
else
  msg = "[WARN]メンバーに5件以上の追加があった為、投稿を保留しました : " + new_members.values.join(",")
  bb2289.talk_to admins.values, msg, true, 140
end

#check list consistency
all_members = bb2289.members("twizz-members")
not_exists = members.values - all_members.values
if not_exists.size > 0
  msg = "[WARN]active-membersにtwizz-membersにいないメンバーが存在します : " + not_exists.join(",")
  bb2289.talk_to admins.values, msg, true, 140
end
sections = ['rhythm', 'tb', 'sax', 'tp']
section_members = []
sections.each do |section|
  section_members += bb2289.members(section).values
end
section_members.uniq!
not_exists = members.values - section_members
if not_exists.size > 0
  msg = "[WARN]active-membersにどのセクション用リストにもいないメンバーが存在します : " + not_exists.join(",")
  bb2289.talk_to admins.values, msg, true, 140
end
not_exists = section_members - members.values
if not_exists.size > 0
  msg = "[WARN]セクション用リストにactive-membersにいないメンバーが存在します : " + not_exists.join(",")
  bb2289.talk_to admins.values, msg, true, 140
end

puts "end."

