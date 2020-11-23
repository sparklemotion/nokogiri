require "helper"

module Nokogiri
  module XML
    class TestSchema < Nokogiri::TestCase
      def setup
        assert @xsd = Nokogiri::XML::Schema(File.read(PO_SCHEMA_FILE))
      end

      def test_issue_1985_segv_on_schema_parse
        skip("Pure Java version doesn't have this bug") unless Nokogiri.uses_libxml?

        # This is a test for a workaround for a bug in LibXML2.  The upstream
        # bug is here: https://gitlab.gnome.org/GNOME/libxml2/issues/148
        # Schema creation can result in dangling pointers.  If no nodes have
        # been exposed, then it should be fine to create a schema.  If nodes
        # have been exposed to Ruby, then we need to make sure they won't be
        # freed out from under us.
        doc = <<~EOF
          <?xml version="1.0" encoding="UTF-8" ?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:element name="foo" type="xs:string"/>
          </xs:schema>
        EOF

        # This is OK, no nodes have been exposed
        xsd_doc = Nokogiri::XML(doc)
        assert Nokogiri::XML::Schema.from_document(xsd_doc)

        # This is not OK, nodes have been exposed to Ruby
        xsd_doc = Nokogiri::XML(doc)
        xsd_doc.root.children.find(&:blank?) # Finds a node

        ex = assert_raise(ArgumentError) do
          Nokogiri::XML::Schema.from_document(xsd_doc)
        end
        assert_match(/blank nodes/, ex.message)
      end

      def test_schema_read_memory
        xsd = Nokogiri::XML::Schema.read_memory(File.read(PO_SCHEMA_FILE))
        assert_instance_of Nokogiri::XML::Schema, xsd
      end

      def test_schema_from_document
        doc = Nokogiri::XML(File.open(PO_SCHEMA_FILE))
        assert doc
        xsd = Nokogiri::XML::Schema.from_document doc
        assert_instance_of Nokogiri::XML::Schema, xsd
      end

      def test_invalid_schema_do_not_raise_exceptions
        xsd = Nokogiri::XML::Schema.new(<<~EOF)
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:group name="foo1">
              <xs:sequence>
                <xs:element name="bar" type="xs:boolean" />
              </xs:sequence>
            </xs:group>
            <xs:group name="foo2">
              <xs:sequence>
                <xs:element name="bar" type="xs:string" />
              </xs:sequence>
            </xs:group>
            <xs:element name="foo">
              <xs:complexType>
                <xs:choice>
                  <xs:group ref="foo1"/>
                  <xs:group ref="foo2"/>
                </xs:choice>
              </xs:complexType>
            </xs:element>
          </xs:schema>
        EOF

        assert_instance_of Nokogiri::XML::Schema, xsd

        if Nokogiri.jruby?
          assert xsd.errors.length > 0
          assert_equal 1, xsd.errors.map(&:to_s).grep(/cos-element-consistent/).length
          assert_equal 1, xsd.errors.map(&:to_s).grep(/cos-nonambig/).length
        end
      end

      def test_schema_from_document_node
        doc = Nokogiri::XML(File.open(PO_SCHEMA_FILE))
        assert doc
        xsd = Nokogiri::XML::Schema.from_document doc.root
        assert_instance_of Nokogiri::XML::Schema, xsd
      end

      def test_schema_validates_with_relative_paths
        xsd = File.join(ASSETS_DIR, "foo", "foo.xsd")
        xml = File.join(ASSETS_DIR, "valid_bar.xml")
        doc = Nokogiri::XML(File.open(xsd))
        xsd = Nokogiri::XML::Schema.from_document doc

        doc = Nokogiri::XML(File.open(xml))
        assert xsd.valid?(doc)
      end

      def test_parse_with_memory
        assert_instance_of Nokogiri::XML::Schema, @xsd
        assert_equal 0, @xsd.errors.length
      end

      def test_new
        assert xsd = Nokogiri::XML::Schema.new(File.read(PO_SCHEMA_FILE))
        assert_instance_of Nokogiri::XML::Schema, xsd
      end

      def test_schema_method_with_parse_options
        schema = Nokogiri::XML::Schema(File.read(PO_SCHEMA_FILE))
        assert_equal Nokogiri::XML::ParseOptions::DEFAULT_SCHEMA, schema.parse_options

        schema = Nokogiri::XML::Schema(File.read(PO_SCHEMA_FILE), Nokogiri::XML::ParseOptions.new.recover)
        assert_equal Nokogiri::XML::ParseOptions.new.recover, schema.parse_options
      end

      def test_schema_new_with_parse_options
        schema = Nokogiri::XML::Schema.new(File.read(PO_SCHEMA_FILE))
        assert_equal Nokogiri::XML::ParseOptions::DEFAULT_SCHEMA, schema.parse_options

        schema = Nokogiri::XML::Schema.new(File.read(PO_SCHEMA_FILE), Nokogiri::XML::ParseOptions.new.recover)
        assert_equal Nokogiri::XML::ParseOptions.new.recover, schema.parse_options
      end

      def test_schema_from_document_with_parse_options
        schema = Nokogiri::XML::Schema.from_document(Nokogiri::XML::Document.parse(File.read(PO_SCHEMA_FILE)))
        assert_equal Nokogiri::XML::ParseOptions::DEFAULT_SCHEMA, schema.parse_options

        schema = Nokogiri::XML::Schema.from_document(Nokogiri::XML::Document.parse(File.read(PO_SCHEMA_FILE)),
                                                     Nokogiri::XML::ParseOptions.new.recover)
        assert_equal Nokogiri::XML::ParseOptions.new.recover, schema.parse_options
      end

      def test_schema_read_memory_with_parse_options
        schema = Nokogiri::XML::Schema.read_memory(File.read(PO_SCHEMA_FILE))
        assert_equal Nokogiri::XML::ParseOptions::DEFAULT_SCHEMA, schema.parse_options

        schema = Nokogiri::XML::Schema.read_memory(File.read(PO_SCHEMA_FILE), Nokogiri::XML::ParseOptions.new.recover)
        assert_equal Nokogiri::XML::ParseOptions.new.recover, schema.parse_options
      end

      def test_parse_with_io
        xsd = nil
        File.open(PO_SCHEMA_FILE, "rb") { |f|
          assert xsd = Nokogiri::XML::Schema(f)
        }
        assert_equal 0, xsd.errors.length
      end

      def test_parse_with_errors
        xml = File.read(PO_SCHEMA_FILE).sub(/name="/, "name=")
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
        doc = Nokogiri::XML File.read(PO_XML_FILE)
        doc.css("city").unlink

        assert errors = @xsd.validate(doc)
        assert_equal 2, errors.length
      end

      def test_validate_invalid_file
        tempfile = Tempfile.new("xml")

        doc = Nokogiri::XML File.read(PO_XML_FILE)
        doc.css("city").unlink
        tempfile.write doc.to_xml
        tempfile.close

        assert errors = @xsd.validate(tempfile.path)
        assert_equal 2, errors.length
      end

      def test_validate_non_document
        string = File.read(PO_XML_FILE)
        assert_raise(ArgumentError) { @xsd.validate(string) }
      end

      def test_valid?
        valid_doc = Nokogiri::XML(File.read(PO_XML_FILE))

        invalid_doc = Nokogiri::XML(
          File.read(PO_XML_FILE).gsub(/<city>[^<]*<\/city>/, "")
        )

        assert(@xsd.valid?(valid_doc))
        assert(!@xsd.valid?(invalid_doc))
      end

      def test_xsd_with_dtd
        Dir.chdir(File.join(ASSETS_DIR, "saml")) do
          # works
          Nokogiri::XML::Schema(IO.read("xmldsig_schema.xsd"))
          # was not working
          Nokogiri::XML::Schema(IO.read("saml20protocol_schema.xsd"))
        end
      end
    end
  end
end
