# frozen_string_literal: true

require "helper"

module Nokogiri
  module SAX
    class TestCase
      describe Nokogiri::XML::SAX::Parser do
        let(:parser) { Nokogiri::XML::SAX::Parser.new(Doc.new) }

        describe ".parse" do
          describe "passed IO (parse_io)" do
            it "parses an IO" do
              File.open(XML_FILE, "rb") do |f|
                parser.parse(f)
              end

              refute_empty(parser.document.cdata_blocks)
            end

            it "yields the parser context" do
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
          end

          describe "passed String (parse_memory)" do
            it "parses a String" do
              parser.parse(File.read(XML_FILE))

              refute_empty(parser.document.cdata_blocks)
            end

            it "yields the parser context" do
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
          end
        end

        describe ".parse_file" do
          it "parses a file" do
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

          it "parses a compressed file" do
            skip("libxml2 legacy support") unless Nokogiri.uses_libxml? && Nokogiri::LIBXML_ZLIB_ENABLED

            filename = XML_FILE + ".gz"
            parser.parse_file(filename)

            refute_nil(parser.document.start_elements)
            assert_operator(parser.document.start_elements.count, :>, 30)
          end
        end

        it "handles documents without an xml decl" do
          parser = Nokogiri::XML::SAX::Parser.new(Doc.new)

          xml = "<root />"
          parser.parse(xml)
          assert(parser.document.start_document_called)
          assert_nil(parser.document.xmldecls)
        end

        [
          ['<?xml version="1.0" ?>', ["1.0"]],
          ['<?xml version="1.0" encoding="UTF-8" ?>', ["1.0", "UTF-8"]],
          ['<?xml version="1.0" standalone="yes"?>', ["1.0", "yes"]],
          ['<?xml version="1.0" standalone="no"?>', ["1.0", "no"]],
          ['<?xml version="1.0" encoding="UTF-8" standalone="no"?>', ["1.0", "UTF-8", "no"]],
          ['<?xml version="1.0" encoding="ISO-8859-1" standalone="yes"?>', ["1.0", "ISO-8859-1", "yes"]],
        ].each do |decl, value|
          it "parses xml decl '#{decl}'" do
            parser = Nokogiri::XML::SAX::Parser.new(Doc.new)

            xml = "#{decl}\n<root />"
            parser.parse(xml)
            assert(parser.document.start_document_called)
            assert_equal(value, parser.document.xmldecls)
          end
        end

        it "raises an error on empty content" do
          e = assert_raises(RuntimeError) { parser.parse("") }
          assert_equal("input string cannot be empty", e.message)
        end

        it "handles invalid types gracefully" do
          e = assert_raises(TypeError) { parser.parse(nil) }
          assert_equal("wrong argument type nil (expected String)", e.message)

          e = assert_raises(TypeError) { parser.parse_memory(nil) }
          assert_equal("wrong argument type nil (expected String)", e.message)

          e = assert_raises(TypeError) { Nokogiri::XML::SAX::Parser.new.parse(0xcafecafe) }
          assert_equal("wrong argument type Integer (expected String)", e.message)

          e = assert_raises(TypeError) { Nokogiri::XML::SAX::Parser.new.parse_memory(0xcafecafe) }
          assert_equal("wrong argument type Integer (expected String)", e.message)

          e = assert_raises(TypeError) { Nokogiri::XML::SAX::Parser.new.parse_io(0xcafecafe) }
          assert_equal("argument expected to respond to :read", e.message)
        end

        it "preserves the order of namespace decls" do
          parser.parse(<<~XML)
            <root xmlns:foo='http://foo.example.com/' xmlns='http://example.com/'>
              <a foo:bar='hello' />
            </root>
          XML

          assert_equal(2, parser.document.start_elements_namespace.length)

          el = parser.document.start_elements_namespace.first
          namespaces = el.last

          assert_equal(["foo", "http://foo.example.com/"], namespaces.first)
          assert_equal([nil, "http://example.com/"], namespaces.last)
        end

        it "calls the error handler when there are parse errors" do
          parser.parse("<foo><bar></foo>")
          assert(parser.document.errors)
          refute_empty(parser.document.errors)
        end

        it "start_elements_namespace is called with namespaced attributes" do
          parser.parse(<<~XML)
            <root xmlns:foo='http://foo.example.com/'>
              <foo:a foo:bar='hello' />
            </root>
          XML

          assert_pattern do
            parser.document.start_elements_namespace => [
              [
                "root",
                [],
                nil, nil,
                [["foo", "http://foo.example.com/"]], # namespace declarations
              ], [
                "a",
                [Nokogiri::XML::SAX::Parser::Attribute(localname: "bar", prefix: "foo", uri: "http://foo.example.com/", value: "hello")], # prefixed attribute
                "foo", "http://foo.example.com/", # prefix and uri for the "a" element
                [],
              ]
            ]
          end
        end

        it "start_element is called with namespace declarations" do
          parser.parse(<<~XML)
            <root xmlns:foo='http://foo.example.com/' xmlns='http://example.com/'>
            </root>
          XML

          refute_empty(parser.document.start_elements)

          elm = parser.document.start_elements.first

          assert_equal("root", elm.first)
          assert_includes(elm[1], ["xmlns:foo", "http://foo.example.com/"])
          assert_includes(elm[1], ["xmlns", "http://example.com/"])
        end

        it "start_element and end_element are called without namespaces" do
          parser.parse(<<~XML)
            <root xmlns:foo='http://foo.example.com/' xmlns='http://example.com/'>
              <foo:bar foo:quux="xxx">hello world</foo:bar>
            </root>
          XML

          assert_pattern do
            parser.document.start_elements => [
              ["root", [["xmlns:foo", "http://foo.example.com/"], ["xmlns", "http://example.com/"]]],
              ["foo:bar", [["foo:quux", "xxx"]]],
            ]
          end

          assert_pattern do
            parser.document.end_elements => [["foo:bar"], ["root"]]
          end
        end

        describe "encoding" do
          # proper ISO-8859-1 encoding
          let(:xml_encoding_iso8859) { "<?xml version='1.0' encoding='ISO-8859-1'?>\n<content>B\xF6hnhardt</content>" }
          # this input string is really UTF-8 but is marked as ISO-8859-1
          let(:xml_encoding_broken) { "<?xml version='1.0' encoding='ISO-8859-1'?>\n<content>Böhnhardt</content>" }
          # this input string is really ISO-8859-1 but is marked as UTF-8
          let(:xml_encoding_broken2) { "<?xml version='1.0' encoding='UTF-8'?>\n<content>B\xF6hnhardt</content>" }

          it "is nil by default to indicate encoding should be autodetected" do
            parser = Nokogiri::XML::SAX::Parser.new(Doc.new)
            assert_nil(parser.encoding)
          end

          it "can be set in the initializer" do
            assert_equal("UTF-8", Nokogiri::XML::SAX::Parser.new(Doc.new, "UTF-8").encoding)
            assert_equal("ISO-2022-JP", Nokogiri::XML::SAX::Parser.new(Doc.new, "ISO-2022-JP").encoding)
          end

          it "raises when given an invalid encoding name" do
            assert_raises(ArgumentError) do
              Nokogiri::XML::SAX::Parser.new(Doc.new, "not an encoding").parse_io(StringIO.new("<root/>"))
            end
            assert_raises(ArgumentError) do
              Nokogiri::XML::SAX::Parser.new(Doc.new, "not an encoding").parse_memory("<root/>")
            end
            assert_raises(ArgumentError) { parser.parse_io(StringIO.new("<root/>"), "not an encoding") }
            assert_raises(ArgumentError) { parser.parse_memory("<root/>", "not an encoding") }
          end

          it "autodetects the encoding if not overridden" do
            parser = Nokogiri::XML::SAX::Parser.new(Doc.new)
            parser.parse(xml_encoding_iso8859)

            # correctly converted the input ISO-8859-1 to UTF-8 for the callback
            assert_equal("Böhnhardt", parser.document.data.join)
          end

          it "overrides the ISO-8859-1 document's encoding when set via initializer" do
            if Nokogiri.uses_libxml?("< 2.12.0") # gnome/libxml2@ec7be506
              skip("older libxml2 encoding detection is sus")
            end

            # broken encoding!
            parser = Nokogiri::XML::SAX::Parser.new(Doc.new)
            parser.parse(xml_encoding_broken)

            assert_equal("BÃ¶hnhardt", parser.document.data.join)

            # override the encoding
            parser = Nokogiri::XML::SAX::Parser.new(Doc.new, "UTF-8")
            parser.parse(xml_encoding_broken)

            assert_equal("Böhnhardt", parser.document.data.join)
          end

          it "overrides the UTF-8 document's encoding when set via initializer" do
            if Nokogiri.uses_libxml?(">= 2.13.0")
              # broken encoding!
              parser = Nokogiri::XML::SAX::Parser.new(Doc.new)
              parser.parse(xml_encoding_broken2)

              assert(parser.document.errors.any? { |e| e.match(/Invalid byte/) })
            end

            # override the encoding
            parser = Nokogiri::XML::SAX::Parser.new(Doc.new, "ISO-8859-1")
            parser.parse(xml_encoding_broken2)

            assert_equal("Böhnhardt", parser.document.data.join)
            refute(parser.document.errors.any? { |e| e.match(/Invalid byte/) })
          end

          it "can be set via parse_io" do
            if Nokogiri.uses_libxml?("< 2.13.0")
              skip("older libxml2 encoding detection is sus")
            end

            parser = Nokogiri::XML::SAX::Parser.new(Doc.new)
            parser.parse_io(StringIO.new(xml_encoding_broken), "UTF-8")

            assert_equal("Böhnhardt", parser.document.data.join)

            parser = Nokogiri::XML::SAX::Parser.new(Doc.new)
            parser.parse_io(StringIO.new(xml_encoding_broken2), "ISO-8859-1")

            assert_equal("Böhnhardt", parser.document.data.join)
          end

          it "can be set via parse_memory" do
            if Nokogiri.uses_libxml?("< 2.12.0") # gnome/libxml2@ec7be506
              skip("older libxml2 encoding detection is sus")
            end

            parser = Nokogiri::XML::SAX::Parser.new(Doc.new)
            parser.parse_memory(xml_encoding_broken, "UTF-8")

            assert_equal("Böhnhardt", parser.document.data.join) # here

            parser = Nokogiri::XML::SAX::Parser.new(Doc.new)
            parser.parse_memory(xml_encoding_broken2, "ISO-8859-1")

            assert_equal("Böhnhardt", parser.document.data.join)
          end
        end

        it "error strings are UTF-8" do
          doc = Nokogiri::XML("<foo><bar></foo>")

          assert(doc.errors) # assert on setup

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

        it "parse_io with encoding" do
          # https://github.com/sparklemotion/nokogiri/pull/1942
          parser = XML::SAX::Parser.new(Doc.new, "UTF-8")
          parser.parse_io(StringIO.new("<root/>"), "ASCII")

          assert_equal "UTF-8", parser.encoding
        end

        ["UTF-8", "utf-8"].each do |encoding|
          it "parses with encoding #{encoding.inspect}" do
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
        end

        it "cdata_block is called when CDATA is parsed" do
          parser.parse_memory(<<~XML)
            <p id="asdfasdf">
              <![CDATA[ This is a comment ]]>
              Paragraph 1
            </p>
          XML

          assert_equal([" This is a comment "], parser.document.cdata_blocks)
        end

        it "comment is called when a comment is parsed" do
          parser.parse_memory(<<~XML)
            <p id="asdfasdf">
              <!-- This is a comment -->
              Paragraph 1
            </p>
          XML

          assert_equal([" This is a comment "], parser.document.comments)
        end

        it "characters is called when text is parsed" do
          parser.parse_memory(<<~XML)
            <p id="asdfasdf">Paragraph 1</p>
          XML

          assert_equal(["Paragraph 1"], parser.document.data)
        end

        it "end_document is called when parsing is complete" do
          refute(parser.document.end_document_called)

          parser.parse_memory(<<~XML)
            <p id="asdfasdf">Paragraph 1</p>
          XML

          assert(parser.document.end_document_called)
        end

        it "end_element is called when an element is closed" do
          parser.parse_memory(<<~XML)
            <p id="asdfasdf">Paragraph 1</p>
          XML

          assert_equal([["p"]], parser.document.end_elements)
        end

        it "start_element is called when an element is opened" do
          parser.parse_memory(<<~XML)
            <p id="asdfasdf">Paragraph 1</p>
          XML

          assert_equal([["p", [["id", "asdfasdf"]]]], parser.document.start_elements)
        end

        it "start_element is called with namespace declarations" do
          parser.parse_memory(<<~XML)
            <p xmlns:foo='http://foo.example.com/'>Paragraph 1</p>
          XML

          assert_equal(
            [["p", [["xmlns:foo", "http://foo.example.com/"]]]],
            parser.document.start_elements,
          )
        end

        it "processing_instruction is called when a processing instruction is parsed" do
          parser.parse_memory(<<~XML)
            <?xml-stylesheet href="a.xsl" type="text/xsl"?>
            <?xml version="1.0"?>
          XML

          assert_equal(
            [["xml-stylesheet", 'href="a.xsl" type="text/xsl"']],
            parser.document.processing_instructions,
          )
        end

        it "start_element is called with attributes" do
          xml = <<~XML
            <?xml version="1.0" ?><root><foo a="&amp;b" c="&gt;d" /></root>
          XML

          parser.parse(xml) do |ctx|
            ctx.replace_entities = true
          end

          assert_equal(
            [["root", []], ["foo", [["a", "&b"], ["c", ">d"]]]], parser.document.start_elements
          )
        end

        describe "error handling" do
          let(:invalid_xml) { <<~XML }
            <?xml version="1.0" ?>
            <Root>
              <Data>
                <?xml version='1.0'?>
                <Item>hey</Item>
                </Data><Data>
                <Item>hey yourself</Item>
              </Data>
            </Root>
          XML

          it "does not recover by default" do
            parser.parse(invalid_xml)

            assert_equal(
              [["Root", []], ["Data", []]],
              parser.document.start_elements,
            )
          end

          it "recovers when `recovery` is true" do
            parser.parse(invalid_xml) do |ctx|
              ctx.recovery = true
            end

            assert_equal(
              [["Root", []], ["Data", []], ["Item", []], ["Data", []], ["Item", []]],
              parser.document.start_elements,
            )
          end
        end

        it "parses square brackets properly" do
          # https://github.com/sparklemotion/nokogiri/issues/1261
          xml = <<~XML
            <tu tuid="87dea04cf60af103ff09d1dba36ae820" segtype="block">
              <prop type="x-smartling-string-variant">en:#:home_page:#:stories:#:[6]:#:name</prop>
              <tuv xml:lang="en-US"><seg>Sandy S.</seg></tuv>
            </tu>
          XML
          parser.parse(xml)

          assert_includes(parser.document.data, "en:#:home_page:#:stories:#:[6]:#:name")
        end

        it "handles large CDATA" do
          skip("see #2132 and https://gitlab.gnome.org/GNOME/libxml2/-/issues/200") if Nokogiri::VersionInfo.instance.libxml2_using_system?

          template = <<~XML
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
          XML

          factor = 10
          huge_data = "a" * (1024 * 1024 * factor)
          xml = StringIO.new(template % huge_data)

          handler = Nokogiri::SAX::TestCase::Doc.new
          parser = Nokogiri::XML::SAX::Parser.new(handler)
          parser.parse(xml)

          if Nokogiri.uses_libxml?(">=2.10.3")
            # CVE-2022-40303 https://gitlab.gnome.org/GNOME/libxml2/-/commit/c846986
            assert_match(/CData section too big/, handler.errors.first)
          else
            assert_predicate(handler.errors, :empty?)
          end
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
          if truffleruby_system_libraries?
            assert_equal("warning_func: %s", parser.document.warnings.first)
          else
            assert_match(/URI .* is not absolute/, parser.document.warnings.first)
          end
        end

        describe "entities" do
          it "does not replace entities by default" do
            parser_context = nil
            parser.parse("<root></root>") do |ctx|
              parser_context = ctx
            end

            refute(parser_context.replace_entities)
          end

          describe "character references" do
            let(:xml) { <<~XML }
              <?xml version="1.0" encoding="UTF-8"?>
              <root><foo>&#146;</foo><foo>&#146;</foo></root>
            XML

            [true, false].each do |replace_entities|
              it "always replace when replace_entities=#{replace_entities}" do
                parser.parse(xml) { |pc| pc.replace_entities = replace_entities }

                assert_equal(["\u0092", "\u0092"], parser.document.data)
              end

              it "never call #references when replace_entities=#{replace_entities}" do
                parser.parse(xml) { |pc| pc.replace_entities = replace_entities }

                assert_nil(parser.document.references)
              end
            end
          end

          describe "predefined entities" do
            let(:xml) { <<~XML }
              <?xml version="1.0" encoding="UTF-8"?>
              <root><foo>&amp;</foo><foo>&amp;</foo></root>
            XML

            [true, false].each do |replace_entities|
              it "always replace when replace_entities=#{replace_entities}" do
                parser.parse(xml) { |pc| pc.replace_entities = replace_entities }

                assert_equal(["&", "&"], parser.document.data)
              end

              it "never call #references when replace_entities=#{replace_entities}" do
                parser.parse(xml) { |pc| pc.replace_entities = replace_entities }

                assert_nil(parser.document.references)
              end
            end
          end

          describe "internal entities" do
            let(:xml) { <<~XML }
              <?xml version="1.0" encoding="UTF-8"?>
              <!DOCTYPE root [ <!ENTITY bar "quux"> ]>
              <root><foo>&bar;</foo><foo>&bar;</foo></root>
            XML

            [true, false].each do |replace_entities|
              it "always replaces when replace_entities=#{replace_entities}" do
                parser.parse(xml) { |pc| pc.replace_entities = replace_entities }

                assert_equal(["quux", "quux"], parser.document.data)
              end
            end

            it "does not call #references when replace_entities=true" do
              parser.parse(xml) { |pc| pc.replace_entities = true }

              assert_nil(parser.document.references)
            end

            it "calls #references when replace_entities=false" do
              parser.parse(xml) { |pc| pc.replace_entities = false }

              assert_equal([["bar", "quux"], ["bar", "quux"]], parser.document.references)
            end
          end

          describe "undeclared entities" do
            let(:xml) { <<~XML }
              <?xml version="1.0" encoding="UTF-8"?>
              <root><foo>&bar;</foo><foo>&bar;</foo></root>
            XML

            [true, false].each do |replace_entities|
              it "does not replace undeclared entities when replace_entities is #{replace_entities}" do
                parser.parse(xml) do |pc|
                  pc.replace_entities = replace_entities
                  pc.recovery = true # because an undeclared entity is an error
                end

                assert_nil(parser.document.data)
              end
            end

            it "does not call #references when replace_entities=true" do
              parser.parse(xml) do |pc|
                pc.replace_entities = true
                pc.recovery = true # because an undeclared entity is an error
              end

              assert_nil(parser.document.references)
            end

            it "calls #references when replace_entities=false" do
              skip if Nokogiri.uses_libxml?("< 2.13.0") # gnome/libxml2@b717abdd

              parser.parse(xml) do |pc|
                pc.replace_entities = false
                pc.recovery = true # because an undeclared entity is an error
              end

              assert_equal([["bar", nil], ["bar", nil]], parser.document.references)
            end
          end

          describe "local external entities" do
            it "does not resolve local external entities when replace_entities is false" do
              Tempfile.create do |io|
                io.write("local-contents")
                io.close
                xml = <<~XML
                  <?xml version="1.0" encoding="UTF-8"?>
                  <!DOCTYPE doc [
                    <!ENTITY local SYSTEM "file:///#{io.path}">
                  ]>
                  <doc><foo>&local;</foo><foo>&local;</foo></doc>
                XML
                parser.parse(xml) { |pc| pc.replace_entities = false }
              end

              assert_empty(parser.document.errors)
              assert_nil(parser.document.data)
              assert_equal([["local", nil], ["local", nil]], parser.document.references)
            end

            it "resolves local external entities when replace_entities is true" do
              skip if Nokogiri.uses_libxml?("< 2.9.11") # gnome/libxml2@eddfbc38

              Tempfile.create do |io|
                io.write("local-contents")
                io.close
                xml = <<~XML
                  <?xml version="1.0" encoding="UTF-8"?>
                  <!DOCTYPE doc [
                    <!ENTITY local SYSTEM "#{io.path}">
                  ]>
                  <doc><foo>&local;</foo><foo>&local;</foo></doc>
                XML
                parser.parse(xml) { |pc| pc.replace_entities = true }
              end

              assert_empty(parser.document.errors)
              assert_equal(["local-contents", "local-contents"], parser.document.data)
              assert_nil(parser.document.references)
            end
          end

          it "does not resolve network external entities when replace_entities is false" do
            xml = <<~XML
              <?xml version="1.0" encoding="UTF-8"?>
              <!DOCTYPE doc [
                <!ENTITY remote SYSTEM "http://0.0.0.0:8080/evil.dtd">
              ]>
              <doc><foo>&remote;</foo><foo>&remote;</foo></doc>
            XML
            parser.parse(xml) { |pc| pc.replace_entities = false }

            assert_empty(parser.document.errors)
            assert_nil(parser.document.data)
            assert_equal([["remote", nil], ["remote", nil]], parser.document.references)
          end

          # # commented out because xmlIO uses the generic error handler for the network error.  I
          # # just didn't have time to go deal with that, and didn't want the error message coming out
          # # in my test output.
          # it "does not resolve network external entities when replace_entities is true" do
          #   xml = <<~XML
          #     <?xml version="1.0" encoding="UTF-8"?>
          #     <!DOCTYPE doc [
          #       <!ENTITY remote SYSTEM "http://0.0.0.0:8080/evil.dtd">
          #     ]>
          #     <doc><foo>&remote;</foo><foo>&remote;</foo></doc>
          #   XML
          #   parser.parse(xml) { |pc| pc.replace_entities = true }

          #   assert_empty(parser.document.errors)
          #   assert_nil(parser.document.data)
          #   assert_nil(parser.document.references)
          # end
        end
      end
    end
  end
end
