require "helper"

module Nokogiri
  module XML
    class TestXInclude < Nokogiri::TestCase
      def setup
        super
        @xml = Nokogiri::XML.parse(File.read(XML_XINCLUDE_FILE), XML_XINCLUDE_FILE)
        @included = "this snippet is to be included from xinclude.xml"
      end

      def test_xinclude_on_document_parse
        # first test that xinclude works when requested
        xml_doc = nil

        File.open(XML_XINCLUDE_FILE) do |fp|
          xml_doc = Nokogiri::XML(fp) do |conf|
            conf.strict.dtdload.noent.nocdata.xinclude
          end
        end

        assert_not_nil xml_doc
        assert_not_nil included = xml_doc.at_xpath('//included')
        assert_equal @included, included.content

        # no xinclude should happen when not requested
        xml_doc = nil

        File.open(XML_XINCLUDE_FILE) do |fp|
          xml_doc = Nokogiri::XML(fp) do |conf|
            conf.strict.dtdload.noent.nocdata
          end
        end

        assert_not_nil xml_doc
        assert_nil xml_doc.at_xpath('//included')
      end

      def test_xinclude_on_document_node
        assert_nil @xml.at_xpath('//included')
        @xml.do_xinclude
        assert_not_nil included = @xml.at_xpath('//included')
        assert_equal @included, included.content
      end

      def test_xinclude_on_element_subtree
        assert_nil @xml.at_xpath('//included')
        @xml.root.do_xinclude
        assert_not_nil included = @xml.at_xpath('//included')
        assert_equal @included, included.content
      end

      def test_do_xinclude_accepts_block
        non_default_options = Nokogiri::XML::ParseOptions::NOBLANKS | \
          Nokogiri::XML::ParseOptions::XINCLUDE

        @xml.do_xinclude(non_default_options) do |options|
          assert_equal non_default_options, options.to_i
        end
      end

      def test_include_nonexistent_throws_exception
        # break inclusion deliberately
        @xml.at_xpath('//xi:include')['href'] = "nonexistent.xml"

        exception_raised = false
        begin
          @xml.do_xinclude { |opts| opts.nowarning }
        rescue Exception => e
          assert_equal Nokogiri::XML::SyntaxError, e.class
          exception_raised = true
        end

        assert exception_raised
      end

    end
  end
end
