#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-
$:.unshift(File.dirname(__FILE__))
require 'gritter'

def get_since_id(name)
  since_id = nil
  path = "data/#{name}/since_id"
  if File.exists?(path)
    since_id = File.read(path)
  end
  since_id
end

def set_since_id(name, id)
  path = "data/#{name}/since_id"
  File.write(path, id)
end

def talk_to_members(me, members, message)
  members.each do |id, name|
    me.talk_to name, message, true
    sleep 10
  end
end

Dir.chdir(File.dirname(__FILE__))
bb2289 = Gritter.new(ARGV[0], "./2289bb.yml")

#collect message
members = bb2289.members("active-members")
opt = { :filter => /^@2289bb /, :from => members }
bb2289.collect( "#2289bb", Time.now - 60 * 60, opt)

#send message for important tweet
since_id = get_since_id("2289bb")
opt = { :count => 50, :include_rts => false, :trim_user => true }
opt[:since_id] = since_id unless since_id.nil?
messages = bb2289.messages(opt)
if messages.size > 0
  set_since_id "2289bb", messages.first.id

  messages.each do |m|
    if m.text =~ /#2289bb/ && m.text =~ /#important/
      msg = "【同報】" + m.text.sub("#2289bb", "").sub("#important", "").gsub(/ +/, " ") + " ※このDMに返信しないで"
      talk_to_members bb2289, members, msg
    end
  end
end

