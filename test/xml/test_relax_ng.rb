# frozen_string_literal: true

require "helper"

module Nokogiri
  module XML
    class TestRelaxNG < Nokogiri::TestCase
      def setup
        super
        assert(@schema = Nokogiri::XML::RelaxNG(File.read(ADDRESS_SCHEMA_FILE)))
      end

      def test_parse_with_memory
        schema = Nokogiri::XML::RelaxNG.read_memory(File.read(ADDRESS_SCHEMA_FILE))
        assert_instance_of(Nokogiri::XML::RelaxNG, schema)
        assert_equal(0, schema.errors.length)
      end

      def test_new_with_string
        schema = Nokogiri::XML::RelaxNG.new(File.read(ADDRESS_SCHEMA_FILE))
        assert_instance_of(Nokogiri::XML::RelaxNG, schema)
        assert_equal(0, schema.errors.length)

        doc = Nokogiri::XML(File.read(ADDRESS_XML_FILE))
        assert(schema.valid?(doc))
      end

      def test_new_with_io
        schema = nil
        File.open(ADDRESS_SCHEMA_FILE, "rb") do |f|
          schema = Nokogiri::XML::RelaxNG.new(f)
        end
        assert_instance_of(Nokogiri::XML::RelaxNG, schema)
        assert_equal(0, schema.errors.length)

        doc = Nokogiri::XML(File.read(ADDRESS_XML_FILE))
        assert(schema.valid?(doc))
      end

      def test_constructor_method_with_parse_options
        schema = Nokogiri::XML::RelaxNG(File.read(ADDRESS_SCHEMA_FILE))
        assert_equal(Nokogiri::XML::ParseOptions::DEFAULT_SCHEMA, schema.parse_options)

        schema = Nokogiri::XML::RelaxNG(File.read(ADDRESS_SCHEMA_FILE), Nokogiri::XML::ParseOptions.new.recover)
        assert_equal(Nokogiri::XML::ParseOptions.new.recover, schema.parse_options)
      end

      def test_new_with_parse_options
        schema = Nokogiri::XML::RelaxNG.new(File.read(ADDRESS_SCHEMA_FILE))
        assert_equal(Nokogiri::XML::ParseOptions::DEFAULT_SCHEMA, schema.parse_options)

        schema = Nokogiri::XML::RelaxNG.new(File.read(ADDRESS_SCHEMA_FILE), Nokogiri::XML::ParseOptions.new.recover)
        assert_equal(Nokogiri::XML::ParseOptions.new.recover, schema.parse_options)
      end

      def test_from_document_with_parse_options
        schema = Nokogiri::XML::RelaxNG.from_document(Nokogiri::XML::Document.parse(File.read(ADDRESS_SCHEMA_FILE)))
        assert_equal(Nokogiri::XML::ParseOptions::DEFAULT_SCHEMA, schema.parse_options)

        schema = Nokogiri::XML::RelaxNG.from_document(
          Nokogiri::XML::Document.parse(File.read(ADDRESS_SCHEMA_FILE)),
          Nokogiri::XML::ParseOptions.new.recover,
        )
        assert_equal(Nokogiri::XML::ParseOptions.new.recover, schema.parse_options)
      end

      def test_read_memory_with_parse_options
        # https://github.com/sparklemotion/nokogiri/issues/2115
        skip_unless_libxml2

        schema = Nokogiri::XML::RelaxNG.read_memory(File.read(ADDRESS_SCHEMA_FILE))
        assert_equal(Nokogiri::XML::ParseOptions::DEFAULT_SCHEMA, schema.parse_options)

        schema = Nokogiri::XML::RelaxNG.read_memory(
          File.read(ADDRESS_SCHEMA_FILE),
          Nokogiri::XML::ParseOptions.new.recover,
        )
        assert_equal(Nokogiri::XML::ParseOptions.new.recover, schema.parse_options)
      end

      def test_parse_with_errors
        xml = File.read(ADDRESS_SCHEMA_FILE).sub('name="', "name=")
        assert_raises(Nokogiri::XML::SyntaxError) do
          Nokogiri::XML::RelaxNG(xml)
        end
      end

      def test_validate_document
        doc = Nokogiri::XML(File.read(ADDRESS_XML_FILE))
        assert(errors = @schema.validate(doc))
        assert_equal(0, errors.length)
      end

      def test_validate_invalid_document
        # Empty address book is not allowed
        read_doc = "<addressBook></addressBook>"

        assert(errors = @schema.validate(Nokogiri::XML(read_doc)))
        assert_equal(1, errors.length)
      end

      def test_valid?
        valid_doc = Nokogiri::XML(File.read(ADDRESS_XML_FILE))

        invalid_doc = Nokogiri::XML("<addressBook></addressBook>")

        assert(@schema.valid?(valid_doc))
        refute(@schema.valid?(invalid_doc))
      end
    end
  end
end
