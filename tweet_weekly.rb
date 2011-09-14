#!/opt/loacl/bin/ruby -Ku
$:.unshift(File.dirname(__FILE__))
require 'gritter'

puts "start."

gritter = Gritter.new($ARGV[0])

#this week schedule
tpl = "今週 :date は『:title』があるぐりっ！ :where #gsojp :desc".strip 
nextsunday = Date.today - Date.today.wday + 7
sec = 1/24/60/60
gritter.schedule("default", "start-min" => Date.today + 2, "start-max" => nextsunday + (1 - sec)).each do |event|
  gritter.talk event.to_message(tpl), 140
  sleep 1
end

puts "end."
