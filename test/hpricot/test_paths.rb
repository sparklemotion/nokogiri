#!/usr/bin/env ruby

require 'test/unit'
require "nokogiri/hpricot"
require File.join(File.dirname(__FILE__),"load_files")

class TestParser < Test::Unit::TestCase
  include Nokogiri

  def test_roundtrip
    @basic = Hpricot.parse(TestFiles::BASIC)
    %w[link link[2] body #link1 a p.ohmy].each do |css_sel|
      ele = @basic.at(css_sel)
      assert_equal ele, @basic.at(ele.css_path)
      assert_equal ele, @basic.at(ele.xpath)
    end
  end
end
