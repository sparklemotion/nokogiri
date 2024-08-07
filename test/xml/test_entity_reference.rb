# frozen_string_literal: true

require "helper"

module Nokogiri
  module XML
    class TestEntityReference < Nokogiri::TestCase
      def setup
        super
        @xml = Nokogiri::XML(File.open(XML_FILE), XML_FILE)
      end

      def test_new
        assert(ref = EntityReference.new(@xml, "ent4"))
        assert_instance_of(EntityReference, ref)
      end

      def test_newline_node
        # issue 719
        xml = <<~EOF
          <?xml version="1.0" ?>
          <item></item>
        EOF
        doc = Nokogiri::XML(xml)
        lf_node = Nokogiri::XML::EntityReference.new(doc, "#xa")
        doc.xpath("/item").first.add_child(lf_node)

        assert_match(/&#xa;/, doc.to_xml)
      end

      def test_children_should_always_be_empty
        # https://github.com/sparklemotion/nokogiri/issues/1238
        #
        # libxml2 will create a malformed child node for predefined
        # entities. because any use of that child is likely to cause a
        # segfault, we shall pretend that it doesn't exist.
        entity = Nokogiri::XML::EntityReference.new(@xml, "amp")

        assert_equal(0, entity.children.length)

        entity.inspect # should not segfault
      end

      def test_serialization_of_local_entities_without_noent
        xml = <<~XML
          <?xml version="1.0" encoding="UTF-8" ?>
          <!DOCTYPE test [ <!ENTITY quux "expansion"> ]>
          <test>&quux;</test>
        XML

        doc = Nokogiri::XML(xml)
        assert_equal("<test>&quux;</test>", doc.root.to_xml)
      end

      def test_serialization_of_local_entities_with_noent
        xml = <<~XML
          <?xml version="1.0" encoding="UTF-8" ?>
          <!DOCTYPE test [ <!ENTITY quux "expansion"> ]>
          <test>&quux;</test>
        XML

        doc = Nokogiri::XML(xml) { |cfg| cfg.noent }
        assert_equal("<test>expansion</test>", doc.root.to_xml)
      end

      def test_serialization_of_undeclared_entities_without_noent
        if Nokogiri.uses_libxml?("< 2.13.0") # gnome/libxml2@45fe9924
          skip("libxml2 version under test is inconsistent in handling undeclared entities")
        end

        xml = <<~XML
          <?xml version="1.0" encoding="UTF-8" ?>
          <test>&quux;</test>
        XML

        doc = Nokogiri::XML(xml)
        assert_equal("<test>&quux;</test>", doc.root.to_xml)
      end

      def test_serialization_of_undeclared_entities_with_noent
        xml = <<~XML
          <?xml version="1.0" encoding="UTF-8" ?>
          <test>&quux;</test>
        XML

        doc = Nokogiri::XML(xml) { |cfg| cfg.noent }
        assert_equal("<test/>", doc.root.to_xml)
      end

      def test_serialization_of_unresolved_entities_without_noent
        xml = <<~XML
          <?xml version="1.0" encoding="UTF-8" ?>
          <!DOCTYPE test [
            <!ENTITY quux SYSTEM "http://0.0.0.0:8080/not-resolved.dtd">
          ]>
          <test>&quux;</test>
        XML

        doc = Nokogiri::XML(xml)
        assert_equal("<test>&quux;</test>", doc.root.to_xml)
      end

      def test_serialization_of_unresolved_entities_with_noent
        xml = <<~XML
          <?xml version="1.0" encoding="UTF-8" ?>
          <!DOCTYPE test [
            <!ENTITY quux SYSTEM "http://0.0.0.0:8080/not-resolved.dtd">
          ]>
          <test>&quux;</test>
        XML

        doc = Nokogiri::XML(xml) { |cfg| cfg.noent }
        assert_equal("<test/>", doc.root.to_xml)
      end
    end

    module Common
      PATH = "test/files/test_document_url/"

      attr_accessor :path, :parser

      def xml_document
        File.join(path, "document.xml")
      end

      class << self
        def included(base)
          def base.test_relative_and_absolute_path(method_name, &block)
            test_relative_path(method_name, &block)
            test_absolute_path(method_name, &block)
          end

          def base.test_absolute_path(method_name, &block)
            define_method("#{method_name}_with_absolute_path") do
              self.path = "#{File.expand_path(PATH)}/"
              instance_eval(&block)
            end
          end

          def base.test_relative_path(method_name, &block)
            define_method(method_name) do
              self.path = PATH
              instance_eval(&block)
            end
          end
        end
      end
    end

    class TestDOMEntityReference < Nokogiri::TestCase
      include Common

      def setup
        super
        @parser = Nokogiri::XML::Document
      end

      test_relative_and_absolute_path :test_dom_entity_reference_with_dtdload do
        # Make sure that we can parse entity references and include them in the document
        xml = File.read(xml_document)
        doc = @parser.parse(xml, path) do |cfg|
          cfg.default_xml
          cfg.dtdload
          cfg.noent
        end

        assert_empty doc.errors
        assert_equal "foobar", doc.xpath("//blah").text
      end

      test_relative_and_absolute_path :test_dom_entity_reference_with_dtdvalid do
        # Make sure that we can parse entity references and include them in the document
        xml = File.read(xml_document)
        doc = @parser.parse(xml, path) do |cfg|
          cfg.default_xml
          cfg.dtdvalid
          cfg.noent
        end

        assert_empty doc.errors
        assert_equal "foobar", doc.xpath("//blah").text
      end

      test_absolute_path :test_dom_dtd_loading_with_absolute_path do
        # Make sure that we can parse entity references and include them in the document
        xml = <<~XML
          <?xml version="1.0" encoding="UTF-8" ?>
          <!DOCTYPE document SYSTEM "#{path}/document.dtd">
          <document>
            <body>&bar;</body>
          </document>
        XML
        doc = @parser.parse(xml, xml_document) do |cfg|
          cfg.default_xml
          cfg.dtdvalid
          cfg.noent
        end

        assert_empty doc.errors
        assert_equal "foobar", doc.xpath("//blah").text
      end

      test_relative_and_absolute_path :test_dom_entity_reference_with_io do
        # Make sure that we can parse entity references and include them in the document
        xml = File.open(xml_document)
        doc = @parser.parse(xml, nil) do |cfg|
          cfg.default_xml
          cfg.dtdload
          cfg.noent
        end

        assert_empty doc.errors
        assert_equal "foobar", doc.xpath("//blah").text
      end

      test_relative_and_absolute_path :test_dom_entity_reference_without_noent do
        # Make sure that we don't include entity references unless NOENT is set to true
        xml = File.read(xml_document)
        doc = @parser.parse(xml, path) do |cfg|
          cfg.default_xml
          cfg.dtdload
        end

        assert_empty doc.errors
        assert_kind_of Nokogiri::XML::EntityReference, doc.xpath("//body").first.children.first
      end

      test_relative_and_absolute_path :test_dom_entity_reference_without_dtdload do
        # Make sure that we don't include entity references unless NOENT is set to true
        xml = File.read(xml_document)
        doc = @parser.parse(xml, path, &:default_xml)

        assert_kind_of Nokogiri::XML::EntityReference, doc.xpath("//body").first.children.first
        if Nokogiri.uses_libxml?(">= 2.13.0") # gnome/libxml2@b717abdd
          assert_equal ["5:14: WARNING: Entity 'bar' not defined"], doc.errors.map(&:to_s)
        elsif Nokogiri.uses_libxml?
          assert_equal ["5:14: ERROR: Entity 'bar' not defined"], doc.errors.map(&:to_s)
        end
      end

      test_relative_and_absolute_path :test_document_dtd_loading_with_nonet do
        # Make sure that we don't include remote entities unless NOENT is set to true
        xml = <<~XML
          <?xml version="1.0" encoding="UTF-8" ?>
          <!DOCTYPE document SYSTEM "http://foo.bar.com/">
          <document>
            <body>&bar;</body>
          </document>
        XML
        doc = @parser.parse(xml, path) do |cfg|
          cfg.default_xml
          cfg.dtdload
        end

        assert_kind_of Nokogiri::XML::EntityReference, doc.xpath("//body").first.children.first

        expected = if Nokogiri.uses_libxml?("~> 2.14")
          [
            "2:49: ERROR: failed to load \"http://foo.bar.com/\": Attempt to load network entity",
            # "attempt to load network entity" removed in gnome/libxml2@1b1e8b3c
            "4:14: ERROR: Entity 'bar' not defined",
          ]
        elsif Nokogiri.uses_libxml?("~> 2.13.0")
          [
            "2:49: WARNING: failed to load \"http://foo.bar.com/\": Attempt to load network entity",
            "ERROR: Attempt to load network entity: http://foo.bar.com/",
            "4:14: ERROR: Entity 'bar' not defined",
          ]
        elsif Nokogiri.uses_libxml?
          [
            "ERROR: Attempt to load network entity http://foo.bar.com/",
            "4:14: ERROR: Entity 'bar' not defined",
          ]
        else # jruby
          ["Attempt to load network entity http://foo.bar.com/"]
        end
        assert_equal(expected, doc.errors.map(&:to_s))
      end
      # TODO: can we retrieve a resource pointing to localhost when NONET is set to true ?
    end

    class TestSaxEntityReference < Nokogiri::SAX::TestCase
      include Common

      def setup
        super
        @parser = XML::SAX::Parser.new(Doc.new) do |ctx|
          ctx.replace_entities = true
        end
      end

      test_relative_and_absolute_path :test_sax_entity_reference do
        # Make sure that we can parse entity references and include them in the document
        xml = File.read(xml_document)
        @parser.parse(xml)

        actual = if Nokogiri.uses_libxml?(">= 2.13.0") # gnome/libxml2@b717abdd
          @parser.document.warnings
        else
          @parser.document.errors
        end

        actual = actual.map { |e| e.to_s.strip }
        expected = if truffleruby_system_libraries?
          ["error_func: %s"]
        else
          ["Entity 'bar' not defined"]
        end

        assert_equal(expected, actual)
      end

      test_relative_and_absolute_path :test_more_sax_entity_reference do
        # Make sure that we don't include entity references unless NOENT is set to true
        xml = <<~XML
          <?xml version="1.0" encoding="UTF-8" ?>
          <!DOCTYPE document SYSTEM "http://foo.bar.com/">
          <document>
            <body>&bar;</body>
          </document>
        XML
        @parser.parse(xml)

        actual = if Nokogiri.uses_libxml?(">= 2.13.0") # gnome/libxml2@b717abdd
          @parser.document.warnings
        else
          @parser.document.errors
        end

        refute_nil(actual)
        refute_empty(actual)

        actual = actual.map { |e| e.to_s.strip }
        expected = if truffleruby_system_libraries?
          ["error_func: %s"]
        else
          ["Entity 'bar' not defined"]
        end

        assert_equal(expected, actual)
      end
    end

    class TestReaderEntityReference < Nokogiri::TestCase
      include Common

      def setup
        super
      end

      test_relative_and_absolute_path :test_reader_entity_reference do
        # Make sure that we can parse entity references and include them in the document
        xml = File.read(xml_document)
        reader = Nokogiri::XML::Reader(xml, path) do |cfg|
          cfg.default_xml
          cfg.dtdload
          cfg.noent
        end
        nodes = reader.map(&:value)

        assert_equal ["foobar"], nodes.compact.map(&:strip).reject(&:empty?)
      end

      test_relative_and_absolute_path :test_reader_entity_reference_without_noent do
        # Make sure that we can parse entity references and include them in the document
        xml = File.read(xml_document)
        reader = Nokogiri::XML::Reader(xml, path) do |cfg|
          cfg.default_xml
          cfg.dtdload
        end
        nodes = reader.map(&:value)

        assert_empty nodes.compact.map(&:strip).reject(&:empty?)
      end

      test_relative_and_absolute_path :test_reader_entity_reference_without_dtdload do
        xml = File.read(xml_document)
        reader = Nokogiri::XML::Reader(xml, path, &:default_xml)

        if Nokogiri.uses_libxml?
          assert_equal(8, reader.count)
        else
          assert_raises(Nokogiri::XML::SyntaxError) do
            reader.count
          end
        end
        assert_operator(reader.errors.size, :>, 0)
      end
    end
  end
end
