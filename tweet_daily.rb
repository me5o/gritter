#!/opt/loacl/bin/ruby -Ku
$:.unshift(File.dirname(__FILE__))
require 'gritter'

gritter = Gritter.new($ARGV[0])

puts "start."

#tommorow schedule
tpl = "明日は『:title』があるぐりっ！ :date :where #gsojp :desc"
tomorrow = Date.today + 1
sec = 1/24/60/60
gritter.schedule("default", "start-min" => tomorrow, "start-max" => tomorrow + (1 - sec)).each do |event|
  gritter.talk event.to_message(tpl), 140
  sleep 1
end

#aniversary
tpl = "今日は:titleぐりっ (-人-) #bigband :desc"
gritter.schedule("aniversary", "start-min" => Date.today, "start-max" => Date.today + (1 - sec)).each do |event|
  gritter.talk event.to_message(tpl), 140
  sleep 1
end

#this week schedule (created after yestarday)
#nextsunday = Date.today - Date.today.wday + 7
#gritter.schedule("start-min" => Date.today, "start-max" => nextsunday + (1 - sec).each do |event|
#  gritter.talk event.to_message, 140
#  sleep 1
#end

#collect relative message
gritter.collect("gsob", Date.today - 1)

puts "end."
