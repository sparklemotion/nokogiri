# -*- coding: utf-8 -*-
# frozen_string_literal: true

require "helper"

module Nokogiri
  module XML
    class TestReaderEncoding < Nokogiri::TestCase
      def setup
        super
        @reader = Nokogiri::XML::Reader(
          File.read(XML_FILE),
          XML_FILE,
          "UTF-8",
        )
      end

      def test_detects_internal_encoding_correctly
        skip_unless_libxml2("Internal encoding detection isn't implemented yet for JRuby")

        reader = Nokogiri::XML::Reader(<<~XML)
          <?xml version="1.0" encoding="ISO-8859-1"?>
          <anotaci\xF3n>inspiraci\xF3n</anotaci\xF3n>
        XML

        assert_nil(reader.encoding)

        reader.each do
          assert_equal("ISO-8859-1", reader.encoding)
        end
      end

      def test_reader_defaults_internal_encoding_to_utf8
        skip_unless_libxml2("Internal encoding detection isn't implemented yet for JRuby")

        reader = Nokogiri::XML::Reader(<<~XML)
          <?xml version="1.0"?>
          <root attr="foo"><employee /></root>
        XML

        assert_nil(reader.encoding)

        reader.each do
          assert_equal("UTF-8", reader.encoding)
        end
      end

      def test_override_internal_encoding_when_specified
        if Nokogiri.uses_libxml? && !Nokogiri::VersionInfo.instance.libxml2_has_iconv?
          skip("iconv is not compiled into libxml2")
        end

        #
        #  note that libxml2 behavior around document encoding changed at least twice between 2.9
        #  and 2.12, so the testing here is superficial -- asserting on the reported encoding, but
        #  not asserting on the bytes in the document or the serialized nodes.
        #
        reader = Nokogiri::XML::Reader(<<~XML, encoding: "UTF-8")
          <?xml version="1.0" encoding="ISO-8859-1"?>
          <foo>asdf</foo>
        XML

        assert_equal("UTF-8", reader.encoding)

        reader.read

        if Nokogiri.jruby? || Nokogiri.uses_libxml?(">= 2.12.0")
          assert_equal("UTF-8", reader.encoding)
        else
          assert_equal("ISO-8859-1", reader.encoding)
        end

        reader = Nokogiri::XML::Reader(<<~XML, nil, "ISO-8859-1")
          <?xml version="1.0" encoding="UTF-8"?>
          <foo>asdf</foo>
        XML

        assert_equal("ISO-8859-1", reader.encoding)

        reader.read

        if Nokogiri.jruby? || Nokogiri.uses_libxml?(">= 2.12.0")
          assert_equal("ISO-8859-1", reader.encoding)
        else
          assert_equal("UTF-8", reader.encoding)
        end
      end

      def test_attribute_encoding_issue_2891_no_encoding_specified
        if Nokogiri.uses_libxml? && !Nokogiri::VersionInfo.instance.libxml2_has_iconv?
          skip("iconv is not compiled into libxml2")
        end

        # https://github.com/sparklemotion/nokogiri/issues/2891
        reader = Nokogiri::XML::Reader(<<~XML)
          <?xml version="1.0"?>
          <anotación tipo="inspiración">INSPIRACIÓN</anotación>
        XML

        assert_nil(reader.encoding)

        reader.read

        assert_equal("UTF-8", reader.encoding) unless Nokogiri.jruby? # JRuby doesn't support encoding detection
        assert_equal(
          "<anotación tipo=\"inspiración\">INSPIRACIÓN</anotación>",
          reader.outer_xml,
        )
      end

      def test_attribute_encoding_issue_2891_correct_encoding_specified
        if Nokogiri.uses_libxml? && !Nokogiri::VersionInfo.instance.libxml2_has_iconv?
          skip("iconv is not compiled into libxml2")
        end

        # https://github.com/sparklemotion/nokogiri/issues/2891
        reader = Nokogiri::XML::Reader(<<~XML, encoding: "UTF-8")
          <?xml version="1.0"?>
          <anotación tipo="inspiración">INSPIRACIÓN</anotación>
        XML

        assert_equal("UTF-8", reader.encoding)

        reader.read

        assert_equal("UTF-8", reader.encoding)
        assert_equal(
          "<anotación tipo=\"inspiración\">INSPIRACIÓN</anotación>",
          reader.outer_xml,
        )
      end

      def test_attribute_encoding_issue_2891_correct_encoding_specified_non_utf8
        xml = <<~XML
          <?xml version="1.0"?>
          <test>\u{82B1}\u{82F1}</test>
        XML
        reader = Nokogiri::XML::Reader(xml, encoding: "Shift_JIS")

        assert_equal("Shift_JIS", reader.encoding)

        reader.read

        assert_equal("Shift_JIS", reader.encoding)
      end

      def test_attribute_at
        @reader.each do |node|
          next unless (attribute = node.attribute_at(0))

          assert_equal(@reader.encoding, attribute.encoding.name)
        end
      end

      def test_attributes
        @reader.each do |node|
          node.attributes.each do |k, v|
            assert_equal(@reader.encoding, k.encoding.name)
            assert_equal(@reader.encoding, v.encoding.name)
          end
        end
      end

      def test_attribute
        xml = <<-eoxml
          <x xmlns:tenderlove='http://tenderlovemaking.com/'>
            <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
          </x>
        eoxml
        reader = Nokogiri::XML::Reader(xml, nil, "UTF-8")
        reader.each do |node|
          next unless (attribute = node.attribute("awesome"))

          assert_equal(reader.encoding, attribute.encoding.name)
        end
      end

      def test_xml_version
        @reader.each do |node|
          next unless (version = node.xml_version)

          assert_equal(@reader.encoding, version.encoding.name)
        end
      end

      def test_lang
        xml = <<-eoxml
          <awesome>
            <p xml:lang="en">The quick brown fox jumps over the lazy dog.</p>
            <p xml:lang="ja">日本語が上手です</p>
          </awesome>
        eoxml

        reader = Nokogiri::XML::Reader(xml, nil, "UTF-8")
        reader.each do |node|
          next unless (lang = node.lang)

          assert_equal(reader.encoding, lang.encoding.name)
        end
      end

      def test_value
        called = false
        @reader.each do |node|
          next unless (value = node.value)

          assert_equal(@reader.encoding, value.encoding.name)
          called = true
        end
        assert(called)
      end

      def test_prefix
        xml = <<-eoxml
          <x xmlns:edi='http://ecommerce.example.org/schema'>
            <edi:foo>hello</edi:foo>
          </x>
        eoxml
        reader = Nokogiri::XML::Reader(xml, encoding: "UTF-8")
        reader.each do |node|
          next unless (prefix = node.prefix)

          assert_equal(reader.encoding, prefix.encoding.name)
        end
      end

      def test_ns_uri
        xml = <<-eoxml
          <x xmlns:edi='http://ecommerce.example.org/schema'>
            <edi:foo>hello</edi:foo>
          </x>
        eoxml
        reader = Nokogiri::XML::Reader(xml, encoding: "UTF-8")
        reader.each do |node|
          next unless (uri = node.namespace_uri)

          assert_equal(reader.encoding, uri.encoding.name)
        end
      end

      def test_local_name
        xml = <<-eoxml
          <x xmlns:edi='http://ecommerce.example.org/schema'>
            <edi:foo>hello</edi:foo>
          </x>
        eoxml
        reader = Nokogiri::XML::Reader(xml, encoding: "UTF-8")
        reader.each do |node|
          next unless (lname = node.local_name)

          assert_equal(reader.encoding, lname.encoding.name)
        end
      end

      def test_name
        @reader.each do |node|
          next unless (name = node.name)

          assert_equal(@reader.encoding, name.encoding.name)
        end
      end
    end
  end
end
