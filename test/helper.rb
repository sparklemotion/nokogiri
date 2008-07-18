require 'test/unit'
require 'nokogiri'

module Nokogiri
  class TestCase < Test::Unit::TestCase
    ASSETS_DIR = File.join(File.dirname(__FILE__), 'files')
    XML_FILE = File.join(ASSETS_DIR, 'staff.xml')
    HTML_FILE = File.join(ASSETS_DIR, 'tlm.html')

    undef :default_test
  end
end
