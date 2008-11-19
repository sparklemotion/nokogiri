require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestComment < Nokogiri::TestCase
      def setup
        @xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
      end

      def test_new
        comment = Nokogiri::XML::Comment.new(@xml, 'hello world')
        assert_equal('<!--hello world-->', comment.to_s)
      end
    end
  end
end
