# frozen_string_literal: true

require "helper"

class TestNokogiriXMLSchema < Nokogiri::TestCase
  describe Nokogiri::XML::Schema do
    let(:xsd) { Nokogiri::XML::Schema(File.read(PO_SCHEMA_FILE)) }

    describe "construction" do
      it ".new" do
        assert(xsd = Nokogiri::XML::Schema.new(File.read(PO_SCHEMA_FILE)))
        assert_instance_of(Nokogiri::XML::Schema, xsd)
      end

      it ".read_memory" do
        xsd = Nokogiri::XML::Schema.read_memory(File.read(PO_SCHEMA_FILE))
        assert_instance_of(Nokogiri::XML::Schema, xsd)
      end

      it ".from_document" do
        doc = Nokogiri::XML(File.open(PO_SCHEMA_FILE))
        assert(doc)
        xsd = Nokogiri::XML::Schema.from_document(doc)
        assert_instance_of(Nokogiri::XML::Schema, xsd)
      end

      it "invalid_schema_do_not_raise_exceptions" do
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

        assert_instance_of(Nokogiri::XML::Schema, xsd)

        if Nokogiri.jruby?
          refute_empty(xsd.errors)
          assert_equal(1, xsd.errors.map(&:to_s).grep(/cos-element-consistent/).length)
          assert_equal(1, xsd.errors.map(&:to_s).grep(/cos-nonambig/).length)
        end
      end

      it ".from_document accepts a node, but warns about it" do
        doc = Nokogiri::XML(File.open(PO_SCHEMA_FILE))
        assert(doc)
        xsd = nil

        assert_output(nil, /Passing a Node as the first parameter to Schema.from_document is deprecated/) do
          xsd = Nokogiri::XML::Schema.from_document(doc.root)
        end
        assert_instance_of(Nokogiri::XML::Schema, xsd)
      end

      it ".from_document not accept anything other than Node or Document" do
        assert_raises(TypeError) { Nokogiri::XML::Schema.from_document(1234) }
        assert_raises(TypeError) { Nokogiri::XML::Schema.from_document("asdf") }
        assert_raises(TypeError) { Nokogiri::XML::Schema.from_document({}) }
        assert_raises(TypeError) { Nokogiri::XML::Schema.from_document(nil) }
      end

      it "schema_validates_with_relative_paths" do
        xsd = File.join(ASSETS_DIR, "foo", "foo.xsd")
        xml = File.join(ASSETS_DIR, "valid_bar.xml")
        doc = Nokogiri::XML(File.open(xsd))
        xsd = Nokogiri::XML::Schema.from_document(doc)

        doc = Nokogiri::XML(File.open(xml))
        assert(xsd.valid?(doc))
      end

      it "parse_with_memory" do
        assert_instance_of(Nokogiri::XML::Schema, xsd)
        assert_equal(0, xsd.errors.length)
      end

      it "schema_method_with_parse_options" do
        schema = Nokogiri::XML::Schema(File.read(PO_SCHEMA_FILE))
        assert_equal(Nokogiri::XML::ParseOptions::DEFAULT_SCHEMA, schema.parse_options)

        schema = Nokogiri::XML::Schema(File.read(PO_SCHEMA_FILE), Nokogiri::XML::ParseOptions.new.recover)
        assert_equal(Nokogiri::XML::ParseOptions.new.recover, schema.parse_options)
      end

      it "schema_new_with_parse_options" do
        schema = Nokogiri::XML::Schema.new(File.read(PO_SCHEMA_FILE))
        assert_equal(Nokogiri::XML::ParseOptions::DEFAULT_SCHEMA, schema.parse_options)

        schema = Nokogiri::XML::Schema.new(File.read(PO_SCHEMA_FILE), Nokogiri::XML::ParseOptions.new.recover)
        assert_equal(Nokogiri::XML::ParseOptions.new.recover, schema.parse_options)
      end

      it "schema_from_document_with_parse_options" do
        schema = Nokogiri::XML::Schema.from_document(Nokogiri::XML::Document.parse(File.read(PO_SCHEMA_FILE)))
        assert_equal(Nokogiri::XML::ParseOptions::DEFAULT_SCHEMA, schema.parse_options)

        schema = Nokogiri::XML::Schema.from_document(
          Nokogiri::XML::Document.parse(File.read(PO_SCHEMA_FILE)),
          Nokogiri::XML::ParseOptions.new.recover,
        )
        assert_equal(Nokogiri::XML::ParseOptions.new.recover, schema.parse_options)
      end

      it "schema_read_memory_with_parse_options" do
        schema = Nokogiri::XML::Schema.read_memory(File.read(PO_SCHEMA_FILE))
        assert_equal(Nokogiri::XML::ParseOptions::DEFAULT_SCHEMA, schema.parse_options)

        schema = Nokogiri::XML::Schema.read_memory(File.read(PO_SCHEMA_FILE), Nokogiri::XML::ParseOptions.new.recover)
        assert_equal(Nokogiri::XML::ParseOptions.new.recover, schema.parse_options)
      end

      it "parse_with_io" do
        xsd = nil
        File.open(PO_SCHEMA_FILE, "rb") do |f|
          assert(xsd = Nokogiri::XML::Schema(f))
        end
        assert_equal(0, xsd.errors.length)
      end

      it "parse_with_errors" do
        xml = File.read(PO_SCHEMA_FILE).sub('name="', "name=")
        assert_raises(Nokogiri::XML::SyntaxError) do
          Nokogiri::XML::Schema(xml)
        end
      end
    end

    describe "validation" do
      it "validate_document" do
        doc = Nokogiri::XML(File.read(PO_XML_FILE))
        assert(errors = xsd.validate(doc))
        assert_equal(0, errors.length)
      end

      it "validate_file" do
        assert(errors = xsd.validate(PO_XML_FILE))
        assert_equal(0, errors.length)
      end

      it "validate_invalid_document" do
        doc = Nokogiri::XML(File.read(PO_XML_FILE))
        doc.css("city").unlink

        assert(errors = xsd.validate(doc))
        assert_equal(2, errors.length)
      end

      it "validate_invalid_file" do
        tempfile = Tempfile.new("xml")

        doc = Nokogiri::XML(File.read(PO_XML_FILE))
        doc.css("city").unlink
        tempfile.write(doc.to_xml)
        tempfile.close

        assert(errors = xsd.validate(tempfile.path))
        assert_equal(2, errors.length)
      end

      it "validate_non_document" do
        string = File.read(PO_XML_FILE)
        assert_raises(ArgumentError) { xsd.validate(string) }
      end

      it "validate_empty_document" do
        doc = Nokogiri::XML("")
        assert(errors = xsd.validate(doc))

        pending_if("https://github.com/sparklemotion/nokogiri/issues/783", Nokogiri.jruby?) do
          assert_equal(1, errors.length)
        end
      end

      it "valid?" do
        valid_doc = Nokogiri::XML(File.read(PO_XML_FILE))

        invalid_doc = Nokogiri::XML(
          File.read(PO_XML_FILE).gsub(%r{<city>[^<]*</city>}, ""),
        )

        assert(xsd.valid?(valid_doc))
        refute(xsd.valid?(invalid_doc))
      end
    end

    it "xsd_with_dtd" do
      Dir.chdir(File.join(ASSETS_DIR, "saml")) do
        # works
        Nokogiri::XML::Schema(File.read("xmldsig_schema.xsd"))
        # was not working
        Nokogiri::XML::Schema(File.read("saml20protocol_schema.xsd"))
      end
    end

    it "xsd_import_with_no_systemid" do
      # https://github.com/sparklemotion/nokogiri/pull/2296
      xsd = <<~EOF
        <?xml version="1.0" encoding="UTF-8"?>
        <xs:schema
          xmlns:xs="http://www.w3.org/2001/XMLSchema"
          xmlns="http://www.w3.org/1998/Math/MathML"
          targetNamespace="http://www.w3.org/1998/Math/MathML"
        >
        <xs:import/>
        </xs:schema>
      EOF
      Nokogiri::XML::Schema(xsd) # assert_nothing_raised
    end

    it "issue_1985_schema_parse_modifying_underlying_document" do
      skip_unless_libxml2("Pure Java version doesn't have this bug")

      # This is a test for a workaround for a bug in LibXML2:
      #
      #   https://gitlab.gnome.org/GNOME/libxml2/issues/148
      #
      # Schema creation can modify the original document -- removal of blank text nodes -- which
      # results in dangling pointers.
      #
      # If no nodes have been exposed, then it should be fine to create a schema. If nodes have
      # been exposed to Ruby, then we need to make sure they won't be freed out from under us.
      doc = <<~EOF
        <?xml version="1.0" encoding="UTF-8" ?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
          <xs:element name="foo" type="xs:string"/>
        </xs:schema>
      EOF

      # This is OK, no nodes have been exposed
      xsd_doc = Nokogiri::XML(doc)
      assert(Nokogiri::XML::Schema.from_document(xsd_doc))

      # This is not OK, nodes have been exposed to Ruby
      xsd_doc = Nokogiri::XML(doc)
      child = xsd_doc.root.children.find(&:blank?) # Find a blank node that would be freed without the fix

      Nokogiri::XML::Schema.from_document(xsd_doc)
      assert(child.to_s) # This will raise a valgrind error if the node was freed
    end

    describe "CVE-2020-26247" do
      # https://github.com/sparklemotion/nokogiri/security/advisories/GHSA-vr8q-g5c7-m54m
      let(:schema) do
        <<~EOSCHEMA
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:import namespace="test" schemaLocation="http://localhost:8000/making-a-request"/>
          </xs:schema>
        EOSCHEMA
      end

      if Nokogiri.uses_libxml?
        describe "with default parse options" do
          it "XML::Schema parsing does not attempt to access external DTDs" do
            doc = Nokogiri::XML::Schema.new(schema)
            errors = doc.errors.map(&:to_s)
            assert_equal(
              1,
              errors.grep(/ERROR: Attempt to load network entity/).length,
              "Should see xmlIO.c:xmlNoNetExternalEntityLoader() raising XML_IO_NETWORK_ATTEMPT",
            )
            assert_empty(
              errors.grep(/WARNING: failed to load HTTP resource/),
              "Should not see xmlIO.c:xmlCheckHTTPInput() raising 'failed to load HTTP resource'",
            )
            assert_empty(
              errors.grep(/WARNING: failed to load external entity/),
              "Should not see xmlIO.c:xmlDefaultExternalEntityLoader() raising 'failed to load external entity'",
            )
          end

          it "XML::Schema parsing of memory does not attempt to access external DTDs" do
            doc = Nokogiri::XML::Schema.read_memory(schema)
            errors = doc.errors.map(&:to_s)
            assert_equal(
              1,
              errors.grep(/ERROR: Attempt to load network entity/).length,
              "Should see xmlIO.c:xmlNoNetExternalEntityLoader() raising XML_IO_NETWORK_ATTEMPT",
            )
            assert_empty(
              errors.grep(/WARNING: failed to load HTTP resource/),
              "Should not see xmlIO.c:xmlCheckHTTPInput() raising 'failed to load HTTP resource'",
            )
            assert_empty(
              errors.grep(/WARNING: failed to load external entity/),
              "Should not see xmlIO.c:xmlDefaultExternalEntityLoader() raising 'failed to load external entity'",
            )
          end
        end

        describe "with NONET turned off" do
          it "XML::Schema parsing attempts to access external DTDs" do
            doc = Nokogiri::XML::Schema.new(schema, Nokogiri::XML::ParseOptions.new.nononet)
            errors = doc.errors.map(&:to_s)
            assert_equal(
              0,
              errors.grep(/ERROR: Attempt to load network entity/).length,
              "Should not see xmlIO.c:xmlNoNetExternalEntityLoader() raising XML_IO_NETWORK_ATTEMPT",
            )
            assert_equal(1, errors.grep(/WARNING: failed to load HTTP resource|WARNING: failed to load external entity/).length)
          end

          it "XML::Schema parsing of memory attempts to access external DTDs" do
            doc = Nokogiri::XML::Schema.read_memory(schema, Nokogiri::XML::ParseOptions.new.nononet)
            errors = doc.errors.map(&:to_s)
            assert_equal(
              0,
              errors.grep(/ERROR: Attempt to load network entity/).length,
              "Should not see xmlIO.c:xmlNoNetExternalEntityLoader() raising XML_IO_NETWORK_ATTEMPT",
            )
            assert_equal(1, errors.grep(/WARNING: failed to load HTTP resource|WARNING: failed to load external entity/).length)
          end
        end
      end

      if Nokogiri.jruby?
        describe "with default parse options" do
          it "XML::Schema parsing does not attempt to access external DTDs" do
            doc = Nokogiri::XML::Schema.new(schema)
            assert_equal 1, doc.errors.map(&:to_s).grep(/WARNING: Attempt to load network entity/).length
          end

          it "XML::Schema parsing of memory does not attempt to access external DTDs" do
            doc = Nokogiri::XML::Schema.read_memory(schema)
            assert_equal 1, doc.errors.map(&:to_s).grep(/WARNING: Attempt to load network entity/).length
          end
        end

        describe "with NONET turned off" do
          it "XML::Schema parsing attempts to access external DTDs" do
            doc = Nokogiri::XML::Schema.new(schema, Nokogiri::XML::ParseOptions.new.nononet)
            assert_equal 0, doc.errors.map(&:to_s).grep(/WARNING: Attempt to load network entity/).length
          end

          it "XML::Schema parsing of memory attempts to access external DTDs" do
            doc = Nokogiri::XML::Schema.read_memory(schema, Nokogiri::XML::ParseOptions.new.nononet)
            assert_equal 0, doc.errors.map(&:to_s).grep(/WARNING: Attempt to load network entity/).length
          end
        end
      end
    end
  end
end
