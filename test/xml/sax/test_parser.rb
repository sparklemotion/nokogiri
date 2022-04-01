# frozen_string_literal: true

require "helper"

module Nokogiri
  module SAX
    class TestCase
      describe Nokogiri::XML::SAX::Parser do
        let(:parser) { Nokogiri::XML::SAX::Parser.new(Doc.new) }

        it :test_parser_context_yielded_io do
          doc = Doc.new
          parser = Nokogiri::XML::SAX::Parser.new(doc)
          xml = "<foo a='&amp;b'/>"

          block_called = false
          parser.parse(StringIO.new(xml)) do |ctx|
            block_called = true
            ctx.replace_entities = true
          end

          assert(block_called)

          assert_equal([["foo", [["a", "&b"]]]], doc.start_elements)
        end

        it :test_parser_context_yielded_in_memory do
          doc = Doc.new
          parser = Nokogiri::XML::SAX::Parser.new(doc)
          xml = "<foo a='&amp;b'/>"

          block_called = false
          parser.parse(xml) do |ctx|
            block_called = true
            ctx.replace_entities = true
          end

          assert(block_called)

          assert_equal([["foo", [["a", "&b"]]]], doc.start_elements)
        end

        it :test_empty_decl do
          parser = Nokogiri::XML::SAX::Parser.new(Doc.new)

          xml = "<root />"
          parser.parse(xml)
          assert(parser.document.start_document_called)
          assert_nil(parser.document.xmldecls)
        end

        it :test_xml_decl do
          [
            ['<?xml version="1.0" ?>', ["1.0"]],
            ['<?xml version="1.0" encoding="UTF-8" ?>', ["1.0", "UTF-8"]],
            ['<?xml version="1.0" standalone="yes"?>', ["1.0", "yes"]],
            ['<?xml version="1.0" standalone="no"?>', ["1.0", "no"]],
            ['<?xml version="1.0" encoding="UTF-8" standalone="no"?>', ["1.0", "UTF-8", "no"]],
            ['<?xml version="1.0" encoding="ISO-8859-1" standalone="yes"?>', ["1.0", "ISO-8859-1", "yes"]],
          ].each do |decl, value|
            parser = Nokogiri::XML::SAX::Parser.new(Doc.new)

            xml = "#{decl}\n<root />"
            parser.parse(xml)
            assert(parser.document.start_document_called)
            assert_equal(value, parser.document.xmldecls)
          end
        end

        it :test_parse_empty do
          assert_raises(RuntimeError) do
            parser.parse("")
          end
        end

        it :test_namespace_declaration_order_is_saved do
          parser.parse(<<~EOF)
            <root xmlns:foo='http://foo.example.com/' xmlns='http://example.com/'>
              <a foo:bar='hello' />
            </root>
          EOF
          assert_equal(2, parser.document.start_elements_namespace.length)
          el = parser.document.start_elements_namespace.first
          namespaces = el.last
          assert_equal(["foo", "http://foo.example.com/"], namespaces.first)
          assert_equal([nil, "http://example.com/"], namespaces.last)
        end

        it :test_bad_document_calls_error_handler do
          parser.parse("<foo><bar></foo>")
          assert(parser.document.errors)
          refute_empty(parser.document.errors)
        end

        it :test_namespace_are_super_fun_to_parse do
          parser.parse(<<~EOF)
            <root xmlns:foo='http://foo.example.com/'>
              <a foo:bar='hello' />
              <b xmlns:foo='http://bar.example.com/'>
                <a foo:bar='hello' />
              </b>
              <foo:bar>hello world</foo:bar>
            </root>
          EOF

          refute_empty(parser.document.start_elements_namespace)
          el = parser.document.start_elements_namespace[1]
          assert_equal("a", el.first)
          assert_equal(1, el[1].length)

          attribute = el[1].first
          assert_equal("bar", attribute.localname)
          assert_equal("foo", attribute.prefix)
          assert_equal("hello", attribute.value)
          assert_equal("http://foo.example.com/", attribute.uri)
        end

        it :test_sax_v1_namespace_attribute_declarations do
          parser.parse(<<~EOF)
            <root xmlns:foo='http://foo.example.com/' xmlns='http://example.com/'>
              <a foo:bar='hello' />
              <b xmlns:foo='http://bar.example.com/'>
                <a foo:bar='hello' />
              </b>
              <foo:bar>hello world</foo:bar>
            </root>
          EOF
          refute_empty(parser.document.start_elements)
          elm = parser.document.start_elements.first
          assert_equal("root", elm.first)
          assert_includes(elm[1], ["xmlns:foo", "http://foo.example.com/"])
          assert_includes(elm[1], ["xmlns", "http://example.com/"])
        end

        it :test_sax_v1_namespace_nodes do
          parser.parse(<<~EOF)
            <root xmlns:foo='http://foo.example.com/' xmlns='http://example.com/'>
              <a foo:bar='hello' />
              <b xmlns:foo='http://bar.example.com/'>
                <a foo:bar='hello' />
              </b>
              <foo:bar>hello world</foo:bar>
            </root>
          EOF
          assert_equal(5, parser.document.start_elements.length)
          assert_includes(parser.document.start_elements.map(&:first), "foo:bar")
          assert_includes(parser.document.end_elements.map(&:first), "foo:bar")
        end

        it :test_start_is_called_without_namespace do
          parser.parse(<<~EOF)
            <root xmlns:foo='http://foo.example.com/' xmlns='http://example.com/'>
            <foo:f><bar></foo:f>
            </root>
          EOF
          assert_equal(
            ["root", "foo:f", "bar"],
            parser.document.start_elements.map(&:first)
          )
        end

        it :test_parser_sets_encoding do
          parser = Nokogiri::XML::SAX::Parser.new(Doc.new, "UTF-8")
          assert_equal("UTF-8", parser.encoding)
        end

        it :test_errors_set_after_parsing_bad_dom do
          doc = Nokogiri::XML("<foo><bar></foo>")
          assert(doc.errors)

          parser.parse("<foo><bar></foo>")
          assert(parser.document.errors)
          refute_empty(parser.document.errors)

          doc.errors.each do |error|
            assert_equal("UTF-8", error.message.encoding.name)
          end

          # when using JRuby Nokogiri, more errors will be generated as the DOM
          # parser continue to parse an ill formed document, while the sax parser
          # will stop at the first error
          unless Nokogiri.jruby?
            assert_equal(doc.errors.length, parser.document.errors.length)
          end
        end

        it :test_parse_with_memory_argument do
          parser.parse(File.read(XML_FILE))
          refute_empty(parser.document.cdata_blocks)
        end

        it :test_parse_with_io_argument do
          File.open(XML_FILE, "rb") do |f|
            parser.parse(f)
          end
          refute_empty(parser.document.cdata_blocks)
        end

        it :test_parse_io do
          call_parse_io_with_encoding("UTF-8")
        end

        # issue #828
        it :test_parse_io_lower_case_encoding do
          call_parse_io_with_encoding("utf-8")
        end

        def call_parse_io_with_encoding(encoding)
          File.open(XML_FILE, "rb") do |f|
            parser.parse_io(f, encoding)
          end
          refute_empty(parser.document.cdata_blocks)

          called = false
          parser.document.start_elements.flatten.each do |thing|
            assert_equal("UTF-8", thing.encoding.name)
            called = true
          end
          assert(called)

          called = false
          parser.document.end_elements.flatten.each do |thing|
            assert_equal("UTF-8", thing.encoding.name)
            called = true
          end
          assert(called)

          called = false
          parser.document.data.each do |thing|
            assert_equal("UTF-8", thing.encoding.name)
            called = true
          end
          assert(called)

          called = false
          parser.document.comments.flatten.each do |thing|
            assert_equal("UTF-8", thing.encoding.name)
            called = true
          end
          assert(called)

          called = false
          parser.document.cdata_blocks.flatten.each do |thing|
            assert_equal("UTF-8", thing.encoding.name)
            called = true
          end
          assert(called)
        end

        it :test_parse_file do
          parser.parse_file(XML_FILE)

          assert_raises(ArgumentError) do
            parser.parse_file(nil)
          end

          assert_raises(Errno::ENOENT) do
            parser.parse_file("")
          end
          assert_raises(Errno::EISDIR) do
            parser.parse_file(File.expand_path(File.dirname(__FILE__)))
          end
        end

        it :test_render_parse_nil_param do
          assert_raises(ArgumentError) { parser.parse_memory(nil) }
        end

        it :test_bad_encoding_args do
          assert_raises(ArgumentError) { Nokogiri::XML::SAX::Parser.new(Doc.new, "not an encoding") }
          assert_raises(ArgumentError) { parser.parse_io(StringIO.new("<root/>"), "not an encoding") }
        end

        it :test_ctag do
          parser.parse_memory(<<~EOF)
            <p id="asdfasdf">
              <![CDATA[ This is a comment ]]>
              Paragraph 1
            </p>
          EOF
          assert_equal([" This is a comment "], parser.document.cdata_blocks)
        end

        it :test_comment do
          parser.parse_memory(<<~EOF)
            <p id="asdfasdf">
              <!-- This is a comment -->
              Paragraph 1
            </p>
          EOF
          assert_equal([" This is a comment "], parser.document.comments)
        end

        it :test_characters do
          parser.parse_memory(<<~EOF)
            <p id="asdfasdf">Paragraph 1</p>
          EOF
          assert_equal(["Paragraph 1"], parser.document.data)
        end

        it :test_end_document do
          parser.parse_memory(<<~EOF)
            <p id="asdfasdf">Paragraph 1</p>
          EOF
          assert(parser.document.end_document_called)
        end

        it :test_end_element do
          parser.parse_memory(<<~EOF)
            <p id="asdfasdf">Paragraph 1</p>
          EOF
          assert_equal([["p"]], parser.document.end_elements)
        end

        it :test_start_element_attrs do
          parser.parse_memory(<<~EOF)
            <p id="asdfasdf">Paragraph 1</p>
          EOF
          assert_equal([["p", [["id", "asdfasdf"]]]], parser.document.start_elements)
        end

        it :test_start_element_attrs_include_namespaces do
          parser.parse_memory(<<~EOF)
            <p xmlns:foo='http://foo.example.com/'>Paragraph 1</p>
          EOF
          assert_equal(
            [["p", [["xmlns:foo", "http://foo.example.com/"]]]],
            parser.document.start_elements
          )
        end

        it :test_processing_instruction do
          parser.parse_memory(<<~EOF)
            <?xml-stylesheet href="a.xsl" type="text/xsl"?>
            <?xml version="1.0"?>
          EOF
          assert_equal(
            [["xml-stylesheet", 'href="a.xsl" type="text/xsl"']],
            parser.document.processing_instructions
          )
        end

        it :test_parse_document do
          skip_unless_libxml2("JRuby SAXParser only parses well-formed XML documents")
          parser.parse_memory(<<~EOF)
            <p>Paragraph 1</p>
            <p>Paragraph 2</p>
          EOF
        end

        it :test_parser_attributes do
          xml = <<~EOF
            <?xml version="1.0" ?><root><foo a="&amp;b" c="&gt;d" /></root>
          EOF

          block_called = false
          parser.parse(xml) do |ctx|
            block_called = true
            ctx.replace_entities = true
          end

          assert(block_called)

          assert_equal(
            [["root", []], ["foo", [["a", "&b"], ["c", ">d"]]]], parser.document.start_elements
          )
        end

        it :test_recovery_from_incorrect_xml do
          xml = <<~EOF
            <?xml version="1.0" ?><Root><Data><?xml version='1.0'?><Item>hey</Item></Data><Data><Item>hey yourself</Item></Data></Root>
          EOF

          block_called = false
          parser.parse(xml) do |ctx|
            block_called = true
            ctx.recovery = true
          end

          assert(block_called)

          assert_equal(
            [["Root", []], ["Data", []], ["Item", []], ["Data", []], ["Item", []]],
            parser.document.start_elements
          )
        end

        it :test_square_bracket_in_text do
          # issue 1261
          xml = <<~EOF
            <tu tuid="87dea04cf60af103ff09d1dba36ae820" segtype="block">
              <prop type="x-smartling-string-variant">en:#:home_page:#:stories:#:[6]:#:name</prop>
              <tuv xml:lang="en-US"><seg>Sandy S.</seg></tuv>
            </tu>
          EOF
          parser.parse(xml)
          assert_includes(parser.document.data, "en:#:home_page:#:stories:#:[6]:#:name")
        end

        it :test_large_cdata_is_handled do
          skip("see #2132 and https://gitlab.gnome.org/GNOME/libxml2/-/issues/200") if Nokogiri.uses_libxml?("<=2.9.10")

          template = <<~EOF
            <?xml version="1.0" encoding="UTF-8"?>
            <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://example.com">
               <soapenv:Header>
                  <AuthHeader xsi:type="ns:vAuthHeader">
                  <userName xsi:type="xsd:string">gorilla</userName>
                  <password xsi:type="xsd:string">secret</password>
                </AuthHeader>
               </soapenv:Header>
              <soapenv:Body>
                <ns:checkToken soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                  <checkToken xsi:type="xsd:string"><![CDATA[%s]]></checkToken>
                </ns:checkToken>
               </soapenv:Body>
            </soapenv:Envelope>
          EOF

          factor = 10
          huge_data = "a" * (1024 * 1024 * factor)
          xml = StringIO.new(template % huge_data)

          handler = Nokogiri::SAX::TestCase::Doc.new
          parser = Nokogiri::XML::SAX::Parser.new(handler)
          parser.parse(xml)

          assert_predicate(handler.errors, :empty?)
        end

        it "does not resolve entities by default" do
          xml = <<~EOF
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE doc [
              <!ENTITY local SYSTEM "file:///#{File.expand_path(__FILE__)}">
              <!ENTITY custom "resolved>
            ]>
            <doc><foo>&local;</foo><foo>&custom;</foo></doc>
          EOF

          doc = Doc.new
          parser = Nokogiri::XML::SAX::Parser.new(doc)
          parser.parse(xml)

          assert_nil(doc.data)
        end

        it "does not resolve network external entities by default" do
          xml = <<~EOF
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE doc [
              <!ENTITY remote SYSTEM "http://0.0.0.0:8080/evil.dtd">
            ]>
            <doc><foo>&remote;</foo></doc>
          EOF

          doc = Doc.new
          parser = Nokogiri::XML::SAX::Parser.new(doc)
          parser.parse(xml)

          assert_nil(doc.data)
        end

        it "handles parser warnings" do
          skip_unless_libxml2("this is testing error message formatting in the C extension")
          xml = <<~XML
            <?xml version="1.0" encoding="UTF-8"?>
            <doc xmlns="x">
              this element's ns definition is crafted to raise a warning
              from libxml2's SAX2.c:xmlSAX2AttributeInternal()
            </doc>
          XML
          parser.parse(xml)
          refute_empty(parser.document.warnings)
          assert_match(/URI .* is not absolute/, parser.document.warnings.first)
        end
      end
    end
  end
end
