require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

require 'rubygems'
require 'mocha'

class TestCssCache < Nokogiri::TestCase

  def setup
    @css = "a1 > b2 > c3"
    @parse_result = Nokogiri::CSS.parse(@css)
    @to_xpath_result = @parse_result.map {|ast| ast.to_xpath}
  end

  def teardown
    Nokogiri::CSS::Parser.clear_cache
    Nokogiri::CSS::Parser.set_cache true
  end

  [ false, true ].each do |cache_setting|
    define_method "test_css_cache_#{cache_setting ? "true" : "false"}" do
      times = cache_setting ? 1 : 6
      Nokogiri::CSS::Parser.set_cache cache_setting
      
      Nokogiri::CSS::Parser.any_instance.expects(:parse).with(@css).returns(@parse_result).times(times)
      Nokogiri::CSS::Node.any_instance.expects(:to_xpath).returns(@to_xpath_result).times(times)
      
      Nokogiri::CSS.xpath_for(@css)
      Nokogiri::CSS.xpath_for(@css)
      Nokogiri::CSS::Parser.xpath_for(@css)
      Nokogiri::CSS::Parser.xpath_for(@css)
      Nokogiri::CSS::Parser.new.xpath_for(@css)
      Nokogiri::CSS::Parser.new.xpath_for(@css)
    end

    define_method "test_hpricot_cache_#{cache_setting ? "true" : "false"}" do
      times = cache_setting ? 1 : 2
      Nokogiri::CSS::Parser.set_cache cache_setting

      nh = Nokogiri.Hpricot("<html></html>")
      Nokogiri::CSS::Parser.any_instance.expects(:parse).with(@css).returns(@parse_result).times(times)
      Nokogiri::CSS::Node.any_instance.expects(:to_xpath).returns(@to_xpath_result).times(times)

      nh.convert_to_xpath(@css)
      nh.convert_to_xpath(@css)
    end
  end


end
