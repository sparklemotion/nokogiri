require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestSchema < Nokogiri::TestCase
      def setup
        assert @xsd = Nokogiri::XML::Schema(File.read(PO_SCHEMA_FILE))
      end

      def test_parse_with_memory
        assert_instance_of Nokogiri::XML::Schema, @xsd
        assert_equal 0, @xsd.errors.length
      end

      def test_new
        assert xsd = Nokogiri::XML::Schema.new(File.read(PO_SCHEMA_FILE))
        assert_instance_of Nokogiri::XML::Schema, xsd
      end

      def test_parse_with_io
        xsd = nil
        File.open(PO_SCHEMA_FILE, 'rb') { |f|
          assert xsd = Nokogiri::XML::Schema(f)
        }
        assert_equal 0, xsd.errors.length
      end

      def test_parse_with_errors
        xml = File.read(PO_SCHEMA_FILE).sub(/name="/, 'name=')
        assert_raises(Nokogiri::XML::SyntaxError) {
          Nokogiri::XML::Schema(xml)
        }
      end

      def test_validate_document
        doc = Nokogiri::XML(File.read(PO_XML_FILE))
        assert errors = @xsd.validate(doc)
        assert_equal 0, errors.length
      end

      def test_validate_file
        assert errors = @xsd.validate(PO_XML_FILE)
        assert_equal 0, errors.length
      end

      def test_validate_invalid_document
        read_doc = File.read(PO_XML_FILE).gsub(/<city>[^<]*<\/city>/, '')

        assert errors = @xsd.validate(Nokogiri::XML(read_doc))
        assert_equal 2, errors.length
      end

      def test_valid?
        valid_doc = Nokogiri::XML(File.read(PO_XML_FILE))

        invalid_doc = Nokogiri::XML(
          File.read(PO_XML_FILE).gsub(/<city>[^<]*<\/city>/, '')
        )

        assert(@xsd.valid?(valid_doc))
        assert(!@xsd.valid?(invalid_doc))
      end
    end
  end
end
