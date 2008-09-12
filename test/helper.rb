require 'test/unit'

%w(../lib ../ext).each do |path|
  $LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), path)))
end

require 'nokogiri'

module Nokogiri
  class TestCase < Test::Unit::TestCase
    ASSETS_DIR = File.join(File.dirname(__FILE__), 'files')
    XML_FILE = File.join(ASSETS_DIR, 'staff.xml')
    XSLT_FILE = File.join(ASSETS_DIR, 'staff.xslt')
    HTML_FILE = File.join(ASSETS_DIR, 'tlm.html')

    undef :default_test
  end
end
