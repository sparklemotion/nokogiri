require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestBuilder < Nokogiri::TestCase
      def test_cdata
        builder = Nokogiri::XML::Builder.new do
          root {
            cdata "hello world"
          }
        end
        assert_equal("<?xml version=\"1.0\"?><root><![CDATA[hello world]]></root>", builder.to_xml.gsub(/\n/, ''))
      end

      def test_builder_no_block
        string = "hello world"
        builder = Nokogiri::XML::Builder.new
        builder.root {
          cdata string
        }
        assert_equal("<?xml version=\"1.0\"?><root><![CDATA[hello world]]></root>", builder.to_xml.gsub(/\n/, ''))
      end
    end
  end
end
