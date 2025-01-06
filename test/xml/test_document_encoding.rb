# frozen_string_literal: true

require "helper"

module Nokogiri
  module XML
    class TestDocumentEncoding < Nokogiri::TestCase
      describe "Nokogiri::XML::Document encoding" do
        let(:shift_jis_document) { Nokogiri::XML(File.read(SHIFT_JIS_XML), SHIFT_JIS_XML) }
        let(:ascii_document) { Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE) }
        let(:utf16_document) do
          # the document needs to be large enough to trigger a libxml2 buffer flush. the buffer size
          # is determined by MINLEN in xmlIO.c, which is hardcoded to 4000 code points.
          size = 8000
          <<~XML.encode(Encoding::UTF_16)
            <?xml version="1.0" encoding="UTF-16"?>
            <root>
              <bar>#{"A" * size}</bar>
            </root>
          XML
        end

        describe "#encoding" do
          it "describes the document's encoding correctly" do
            assert_equal("Shift_JIS", shift_jis_document.encoding)
          end

          it "applies the specified encoding even if on empty documents" do
            encoding = "Shift_JIS"
            assert_equal(encoding, Nokogiri::XML(nil, nil, encoding).encoding)
          end

          it "applies the specified kwargs encoding even if on empty documents" do
            encoding = "Shift_JIS"
            assert_equal(encoding, Nokogiri::XML(nil, encoding: encoding).encoding)
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
          assert_equal(Encoding::UTF_8, shift_jis_document.url.encoding)
        end

        it "encodes the encoding name as UTF-8" do
          assert_equal(Encoding::UTF_8, shift_jis_document.encoding.encoding)
        end

        it "encodes the library versions as UTF-8" do
          skip_unless_libxml2

          assert_equal(Encoding::UTF_8, Nokogiri::LIBXML_COMPILED_VERSION.encoding)
          assert_equal(Encoding::UTF_8, Nokogiri::LIBXSLT_COMPILED_VERSION.encoding)
        end

        it "parses and serializes UTF-16 correctly" do
          xml = <<~XML.encode(Encoding::UTF_16)
            <?xml version="1.0" encoding="UTF-16"?>
            <root><bar>A</bar></root>
          XML
          output = Nokogiri::XML(xml).to_xml
          output_doc = Nokogiri::XML(output)

          # these are descriptive, not prescriptive. the difference is whitespace. this may change
          # as implementations change. the intention is to verify that they're _roughly_ the right
          # length, they're not zero or half-width or double-width.
          expected_bytesize = Nokogiri.jruby? ? 132 : 142

          assert_equal(Encoding::UTF_16, output.encoding)
          assert_equal("UTF-16", output_doc.encoding)
          assert_equal(expected_bytesize, output.bytesize)
          output_doc.at_xpath("/root/bar/text()").tap do |node|
            assert(node, "unexpected DOM structure in #{output.inspect}")
            assert_equal("A", node.content)
          end
        end

        it "serializes UTF-16 correctly across libxml2 buffer flushes" do
          # https://github.com/sparklemotion/nokogiri/issues/752
          skip_unless_libxml2

          output = Nokogiri::XML(utf16_document).to_xml

          assert_equal(Encoding::UTF_16, output.encoding)
          assert_equal(utf16_document.bytesize, output.bytesize)
        end

        describe "pseudo-IO" do
          it "serializes correctly with Zip::OutputStream objects" do
            # https://github.com/sparklemotion/nokogiri/issues/2773
            begin
              require "zip"
            rescue LoadError
              skip("rubyzip is not installed")
            end

            xml = <<~XML
              <?xml version="1.0" encoding="UTF-8"?>
              <root>
                <bar>A</bar>
              </root>
            XML

            Dir.mktmpdir do |tmpdir|
              zipfile_path = File.join(tmpdir, "test.zip")

              Zip::OutputStream.open(zipfile_path) do |io|
                io.put_next_entry("test-utf8.xml")
                Nokogiri::XML(xml).write_to(io, encoding: "UTF-8")
              end

              Zip::InputStream.open(zipfile_path) do |io|
                entry = io.get_next_entry
                assert_equal("test-utf8.xml", entry.name)
                output = io.read

                # no final newline on jruby. descriptive, not prescriptive.
                expected_length = Nokogiri.jruby? ? xml.bytesize - 1 : xml.bytesize
                assert_equal(expected_length, output.bytesize)

                # Note: I dropped the assertion on the encoding of the string return from io.read
                # because this behavior has changed back and forth in rubyzip versions 2.4.1 and
                # 3.0.0.dev, and it's not relevant to the original bug report which was about an
                # exception during writing.
              end
            end
          end
        end
      end
    end
  end
end
