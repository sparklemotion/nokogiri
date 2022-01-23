# frozen_string_literal: true

require "helper"

module Nokogiri
  module XML
    class TestDocumentEncoding < Nokogiri::TestCase
      describe "Nokogiri::XML::Document encoding" do
        let(:shift_jis_document) { Nokogiri::XML(File.read(SHIFT_JIS_XML), SHIFT_JIS_XML) }
        let(:ascii_document) { Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE) }

        describe "#encoding" do
          it "describes the document's encoding correctly" do
            assert_equal("Shift_JIS", shift_jis_document.encoding)
          end

          it "applies the specified encoding even if on empty documents" do
            encoding = "Shift_JIS"
            assert_equal(encoding, Nokogiri::XML(nil, nil, encoding).encoding)
          end
        end

        describe "#encoding=" do
          it "determines the document's encoding when serialized" do
            ascii_document.encoding = "UTF-8"
            assert_match("encoding=\"UTF-8\"", ascii_document.to_xml)

            ascii_document.encoding = "EUC-JP"
            assert_match("encoding=\"EUC-JP\"", ascii_document.to_xml)
          end
        end

        it "encodes the URL as UTF-8" do
          assert_equal("UTF-8", shift_jis_document.url.encoding.name)
        end

        it "encodes the encoding name as UTF-8" do
          assert_equal("UTF-8", shift_jis_document.encoding.encoding.name)
        end

        it "encodes the library versions as UTF-8" do
          skip_unless_libxml2
          assert_equal("UTF-8", Nokogiri::LIBXML_COMPILED_VERSION.encoding.name)
          assert_equal("UTF-8", Nokogiri::LIBXSLT_COMPILED_VERSION.encoding.name)
        end
      end
    end
  end
end
