#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-
$:.unshift(File.dirname(__FILE__))
require 'gritter'

Dir.chdir(File.dirname(__FILE__))
bb2289 = Gritter.new(ARGV[0], "./2289bb.yml")

#collect message
members = bb2289.members("active-members")
opt = { :filter => /^@2289bb /, :from => members }
bb2289.collect( "#2289bb", Time.now - 60 * 60, opt)
