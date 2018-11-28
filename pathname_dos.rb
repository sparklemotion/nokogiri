#!/usr/bin/env ruby

require 'nokogiri'
require 'pathname'
f = 'pathname_dos.xml'
pathname = Pathname.new(f)
doc = Nokogiri.parse(pathname)
puts doc.to_s
