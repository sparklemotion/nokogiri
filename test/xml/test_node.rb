# frozen_string_literal: true

require "helper"

require "stringio"

module Nokogiri
  module XML
    class TestNode < Nokogiri::TestCase
      describe Nokogiri::XML::Node do
        let(:xml) { Nokogiri::XML(File.read(XML_FILE), XML_FILE) }

        def test_first_element_child
          node = xml.root.first_element_child
          assert_equal("employee", node.name)
          assert_predicate(node, :element?, "node is an element")
        end

        def test_first_element_child_with_no_match
          doc = Nokogiri::XML::Document.parse("<root>asdf</root>")
          assert_nil(doc.root.first_element_child)
        end

        def test_element_children
          nodes = xml.root.element_children
          assert_equal(xml.root.first_element_child, nodes.first)
          assert(nodes.all?(&:element?), "all nodes are elements")
        end

        def test_last_element_child
          nodes = xml.root.element_children
          assert_equal(nodes.last, xml.root.element_children.last)
        end

        def test_last_element_child_with_no_match
          doc = Nokogiri::XML::Document.parse("<root>asdf</root>")
          assert_nil(doc.root.last_element_child)
        end

        def test_bad_xpath
          bad_xpath = "//foo["

          e = assert_raises(Nokogiri::XML::XPath::SyntaxError) do
            xml.xpath(bad_xpath)
          end
          assert_match(bad_xpath, e.to_s)
        end

        def test_namespace_type_error
          assert_raises(TypeError) do
            xml.root.namespace = Object.new
          end
        end

        def test_remove_namespace
          xml = Nokogiri::XML('<r xmlns="v"><s /></r>')
          tag = xml.at("s")
          assert(tag.namespace)
          tag.namespace = nil
          assert_nil(tag.namespace)
        end

        def test_parse_needs_doc
          list = xml.root.parse("fooooooo <hello />")
          assert_equal(1, list.css("hello").length)
        end

        def test_parse
          list = xml.root.parse("fooooooo <hello />")
          assert_equal(2, list.length)
        end

        def test_parse_with_block
          called = false
          list = xml.root.parse("<hello />") do |cfg|
            called = true
            assert_instance_of(Nokogiri::XML::ParseOptions, cfg)
          end
          assert(called, "config block called")
          assert_equal(1, list.length)
        end

        def test_parse_with_io
          list = xml.root.parse(StringIO.new("<hello />"))
          assert_equal(1, list.length)
          assert_equal("hello", list.first.name)
        end

        def test_parse_with_empty_string
          list = xml.root.parse("")
          assert_equal(0, list.length)
        end

        def test_parse_config_option
          node = xml.root
          options = nil
          node.parse("<item></item>") do |config|
            options = config
          end
          assert_equal(Nokogiri::XML::ParseOptions::DEFAULT_XML, options.to_i)
        end

        def test_node_context_parsing_of_malformed_html_fragment
          doc = HTML4.parse("<html><body><div></div></body></html>")
          context_node = doc.at_css("div")
          nodeset = context_node.parse("<div </div>")

          if Nokogiri.uses_libxml?(">= 2.14.0")
            assert_empty(doc.errors)
            assert_pattern do
              nodeset => [
                { name: "div", attributes: [{name: "<", value: ""}, { name: "div", value: ""}] },
              ]
            end
          else
            assert_equal(1, doc.errors.length)
            assert_equal(1, nodeset.length)
            assert_equal("<div></div>", nodeset.to_s)
          end

          assert_instance_of(Nokogiri::HTML4::Document, nodeset.document)
          assert_instance_of(Nokogiri::HTML4::Document, nodeset.first.document)
        end

        def test_node_context_parsing_of_malformed_html_fragment_with_recover_is_corrected
          doc = HTML4.parse("<html><body><div></div></body></html>")
          context_node = doc.at_css("div")
          nodeset = context_node.parse("<div </div>", &:recover)

          if Nokogiri.uses_libxml?(">= 2.14.0")
            assert_empty(doc.errors)
            assert_pattern do
              nodeset => [
                { name: "div", attributes: [{name: "<", value: ""}, { name: "div", value: ""}] },
              ]
            end
          else
            assert_equal(1, doc.errors.length)
            assert_equal(1, nodeset.length)
            assert_equal("<div></div>", nodeset.to_s)
          end
          assert_instance_of(Nokogiri::HTML4::Document, nodeset.document)
          assert_instance_of(Nokogiri::HTML4::Document, nodeset.first.document)
        end

        def test_node_context_parsing_of_malformed_html_fragment_without_recover_is_not_corrected
          skip("libxml2 2.14.0 no longer raises this error") if Nokogiri.uses_libxml?(">= 2.14.0")

          doc = HTML4.parse("<html><body><div></div></body></html>")
          context_node = doc.at_css("div")
          assert_raises(Nokogiri::XML::SyntaxError) do
            context_node.parse("<div </div>", &:strict)
          end
        end

        def test_node_context_parsing_of_malformed_xml_fragment_uses_the_right_class_to_recover
          doc = XML.parse("<root><body><div></div></body></root>")
          context_node = doc.at_css("div")
          nodeset = context_node.parse("<div </div") # causes an error and recovers
          assert_instance_of(Nokogiri::XML::Document, nodeset.document)
          assert_instance_of(Nokogiri::XML::Document, nodeset.first.document)
        end

        def test_parse_error_list
          error_count = xml.errors.length
          xml.root.parse("<hello>")
          assert_operator(error_count, :<, xml.errors.length, "errors should have increased")
        end

        def test_parse_error_on_fragment_with_empty_document
          doc = Document.new
          fragment = DocumentFragment.new(doc, "<foo><bar/></foo>")
          node = fragment.at_css("bar")

          assert_empty(doc.errors)

          node.parse("<baz><</baz>")

          refute_empty(doc.errors)
        end

        def test_parse_with_unparented_text_context_node
          doc = XML::Document.new
          elem = XML::Text.new("foo", doc)
          x = elem.parse("<bar/>") # should not raise an exception
          assert_equal("bar", x.first.name)
        end

        def test_parse_with_unparented_html_text_context_node
          doc = Nokogiri::HTML4::Document.new
          elem = XML::Text.new("div", doc)
          x = elem.parse("<div/>") # should not raise an exception
          assert_equal("div", x.first.name)
        end

        def test_parse_with_unparented_fragment_text_context_node
          doc = XML::DocumentFragment.parse("<div><span>foo</span></div>")
          elem = doc.at_css("span")
          x = elem.parse("<span/>") # should not raise an exception
          assert_equal("span", x.first.name)
        end

        def test_parse_with_unparented_html_fragment_text_context_node
          doc = Nokogiri::HTML4::DocumentFragment.parse("<div><span>foo</span></div>")
          elem = doc.at_css("span")
          x = elem.parse("<span/>") # should not raise an exception
          assert_equal("span", x.first.name)
        end

        def test_dup_is_deep_copy_by_default
          doc = XML::Document.parse("<root><div><p>hello</p></div></root>")
          div = doc.at_css("div")
          node = div.dup
          assert_equal(1, node.children.length)
          assert_equal("<p>hello</p>", node.children.first.to_html)
        end

        def test_dup_deep_copy
          doc = XML::Document.parse("<root><div><p>hello</p></div></root>")
          div = doc.at_css("div")
          node = div.dup(1)
          assert_equal(1, node.children.length)
          assert_equal("<p>hello</p>", node.children.first.to_html)
        end

        def test_dup_shallow_copy
          doc = XML::Document.parse("<root><div><p>hello</p></div></root>")
          div = doc.at_css("div")
          node = div.dup(0)
          assert_equal(0, node.children.length)
        end

        def test_dup_same_parent_document_is_default
          doc = XML::Document.parse("<root><div><p>hello</p></div></root>")
          div = doc.at_css("div")
          node = div.dup
          assert_same(div.document, node.document)
        end

        def test_dup_different_parent_document
          doc1 = XML::Document.parse("<root><div><p>hello</p></div></root>")
          doc2 = XML::Document.parse("<div></div>")

          x = Module.new { def awesome!; end }
          doc2.decorators(XML::Node) << x
          doc2.decorate!

          div = doc1.at_css("div")
          copy = div.dup(1, doc2)

          assert_same(doc2, copy.document)
          assert_equal(1, copy.children.length, "expected a deep copy")
          assert_respond_to(copy, :awesome!, "expected decorators to be copied")

          copy = div.dup(0, doc2)

          assert_equal(0, copy.children.length, "expected a shallow copy")
        end

        def test_subclass_dup
          subclass = Class.new(Nokogiri::XML::Node)
          node = subclass.new("foo", xml).dup
          assert_instance_of(subclass, node)
        end

        def test_search_direct_children_of_node
          xml = <<~XML
            <root>
              <div class="section header" id="1">
                <div class="subsection header">sub 1</div>
                <div class="subsection header">sub 2</div>
              </div>
              <div class="section header" id="2">
                <div class="subsection header">sub 3</div>
                <div class="subsection header">sub 4</div>
              </div>
            </root>
          XML
          node = Nokogiri::XML::Document.parse(xml).root
          result = (node > "div.header")
          assert_equal(2, result.length)
          assert_equal(["1", "2"], result.map { |n| n["id"] })

          assert_empty(node > ".no-such-match")
        end

        def test_search_direct_children_of_node_provides_root_namespaces_implicitly
          xml = <<~XML
            <root xmlns:foo="http://nokogiri.org/ns/foo">
              <foo:div class="section header" id="1">
                <foo:div class="subsection header">sub 1</foo:div>
                <foo:div class="subsection header">sub 2</foo:div>
              </foo:div>
              <foo:div class="section header" id="2">
                <foo:div class="subsection header">sub 3</foo:div>
                <foo:div class="subsection header">sub 4</foo:div>
              </foo:div>
            </root>
          XML
          node = Nokogiri::XML::Document.parse(xml).root
          result = (node > "foo|div.header")
          assert_equal(2, result.length)
          assert_equal(["1", "2"], result.map { |n| n["id"] })

          assert_empty(node > ".no-such-match")
        end

        def test_next_element_when_next_sibling_is_element_should_return_next_sibling
          doc = Nokogiri::XML("<root><foo /><quux /></root>")
          node         = doc.at_css("foo")
          next_element = node.next_element
          assert_predicate(next_element, :element?)
          assert_equal(doc.at_css("quux"), next_element)
        end

        def test_next_element_when_there_is_no_next_sibling_should_return_nil
          doc = Nokogiri::XML("<root><foo /><quux /></root>")
          assert_nil(doc.at_css("quux").next_element)
        end

        def test_next_element_when_next_sibling_is_not_an_element_should_return_closest_next_element_sibling
          doc = Nokogiri::XML("<root><foo />bar<quux /></root>")
          node         = doc.at_css("foo")
          next_element = node.next_element
          assert_predicate(next_element, :element?)
          assert_equal(doc.at_css("quux"), next_element)
        end

        def test_next_element_when_next_sibling_is_not_an_element_and_no_following_element_should_return_nil
          doc = Nokogiri::XML("<root><foo />bar</root>")
          node         = doc.at_css("foo")
          next_element = node.next_element
          assert_nil(next_element)
        end

        def test_previous_element_when_previous_sibling_is_element_should_return_previous_sibling
          doc = Nokogiri::XML("<root><foo /><quux /></root>")
          node             = doc.at_css("quux")
          previous_element = node.previous_element
          assert_predicate(previous_element, :element?)
          assert_equal(doc.at_css("foo"), previous_element)
        end

        def test_previous_element_when_there_is_no_previous_sibling_should_return_nil
          doc = Nokogiri::XML("<root><foo /><quux /></root>")
          assert_nil(doc.at_css("foo").previous_element)
        end

        def test_previous_element_when_previous_sibling_is_not_an_element_should_return_closest_previous_element_sibling
          doc = Nokogiri::XML("<root><foo />bar<quux /></root>")
          node             = doc.at_css("quux")
          previous_element = node.previous_element
          assert_predicate(previous_element, :element?)
          assert_equal(doc.at_css("foo"), previous_element)
        end

        def test_previous_element_when_previous_sibling_is_not_an_element_and_no_following_element_should_return_nil
          doc = Nokogiri::XML("<root>foo<bar /></root>")
          node             = doc.at_css("bar")
          previous_element = node.previous_element
          assert_nil(previous_element)
        end

        def test_element?
          assert_predicate(xml.root, :element?, "is an element")
        end

        def test_slash_search
          assert_equal("EMP0001", (xml / :staff / :employee / :employeeId).first.text)
        end

        def test_append_with_document
          assert_raises(ArgumentError) do
            xml.root << Nokogiri::XML::Document.new
          end
        end

        def test_append_with_attr
          r = Nokogiri.XML('<r a="1" />').root
          assert_raises(ArgumentError) do
            r << r.at_xpath("@a")
          end
        end

        def test_inspect_ns
          xml = Nokogiri::XML(<<~XML, &:noblanks)
            <root xmlns="http://tenderlovemaking.com/" xmlns:foo="bar">
              <awesome/>
            </root>
          XML
          ins = xml.inspect

          xml.traverse do |node|
            assert_match(node.class.name, ins)
            if node.respond_to?(:attributes)
              node.attributes.each do |k, v|
                assert_match(k, ins)
                assert_match(v, ins)
              end
            end

            if node.respond_to?(:namespace) && node.namespace
              assert_match(node.namespace.class.name, ins)
              assert_match(node.namespace.href, ins)
            end
          end
        end

        def test_namespace_definitions_when_some_exist
          xml = Nokogiri::XML(<<~XML)
            <root xmlns="http://tenderlovemaking.com/" xmlns:foo="bar">
              <awesome/>
            </root>
          XML
          namespace_definitions = xml.root.namespace_definitions
          assert_equal(2, namespace_definitions.length)
        end

        def test_namespace_definitions_when_no_exist
          xml = Nokogiri::XML(<<~XML)
            <root xmlns="http://tenderlovemaking.com/" xmlns:foo="bar">
              <awesome/>
            </root>
          XML
          namespace_definitions = xml.at_xpath("//xmlns:awesome").namespace_definitions
          assert_equal(0, namespace_definitions.length)
        end

        def test_default_namespace_goes_to_children
          fruits = Nokogiri::XML(<<~XML)
            <Fruit xmlns='www.fruits.org'>
            </Fruit>
          XML
          apple = Nokogiri::XML::Node.new("Apple", fruits)
          orange = Nokogiri::XML::Node.new("Orange", fruits)
          apple << orange
          fruits.root << apple
          assert(fruits.at("//fruit:Orange", { "fruit" => "www.fruits.org" }))
          assert(fruits.at("//fruit:Apple", { "fruit" => "www.fruits.org" }))
        end

        def test_parent_namespace_is_not_inherited
          fruits = Nokogiri::XML(<<-XML)
            <fruit xmlns:fruit="http://fruits.org">
              <fruit:apple />
            </fruit>
          XML

          apple = fruits.at_xpath("//fruit:apple", { "fruit" => "http://fruits.org" })
          assert(apple)

          orange = Nokogiri::XML::Node.new("orange", fruits)
          apple.add_child(orange)

          assert_equal(orange, fruits.at_xpath("//orange"))
        end

        def test_description
          assert_nil(xml.at("employee").description)
        end

        def test_spaceship
          nodes = xml.xpath("//employee")
          assert_equal(-1, (nodes.first <=> nodes.last))
          list = [nodes.first, nodes.last].sort
          assert_equal(nodes.first, list.first)
          assert_equal(nodes.last, list.last)
        end

        def test_incorrect_spaceship
          nodes = xml.xpath("//employee")
          assert_nil(nodes.first <=> "asdf")
        end

        def test_document_compare
          nodes = xml.xpath("//employee")
          result = (nodes.first <=> xml)

          # Note that this behavior was changed in libxml@a005199 starting in v2.9.5.
          #
          # But that fix was backported by debian (and other distros?) into their v2.9.4 fork so we
          # can't use version to detect what's going on here. Instead just shrug if we're using system
          # libraries and the result is -1.
          if Nokogiri::VersionInfo.instance.libxml2_using_system?
            assert(result == 1 || result == -1)
          else
            assert_equal(1, result)
          end
        end

        def test_different_document_compare
          nodes = xml.xpath("//employee")
          doc = Nokogiri::XML("<a><b/></a>")
          b = doc.at("b")
          assert_nil(nodes.first <=> b)
        end

        def test_duplicate_node_removes_namespace
          fruits = Nokogiri::XML(<<~XML)
            <Fruit xmlns='www.fruits.org'>
            <Apple></Apple>
            </Fruit>
          XML
          apple = fruits.root.xpath("fruit:Apple", { "fruit" => "www.fruits.org" })[0]
          new_apple = apple.dup
          fruits.root << new_apple
          assert_equal(2, fruits.xpath("//xmlns:Apple").length)
          assert_equal(1, fruits.to_xml.scan("www.fruits.org").length)
        end

        [:clone, :dup].each do |symbol|
          define_method "test_#{symbol}" do
            node = xml.at("//employee")
            other = node.send(symbol)
            assert_equal "employee", other.name
            assert_nil other.parent
          end
        end

        def test_dup_should_not_copy_singleton_class
          # https://github.com/sparklemotion/nokogiri/issues/316
          m = Module.new do
            def foo; end
          end

          node = Nokogiri::XML::Document.parse("<root/>").root
          node.extend(m)

          assert_respond_to(node, :foo)
          refute_respond_to(node.dup, :foo)
        end

        def test_clone_should_copy_singleton_class
          # https://github.com/sparklemotion/nokogiri/issues/316
          m = Module.new do
            def foo; end
          end

          node = Nokogiri::XML::Document.parse("<root/>").root
          node.extend(m)

          assert_respond_to(node, :foo)
          assert_respond_to(node.clone, :foo)
        end

        def test_inspect_object_with_no_data_ptr
          # test for the edge case when an exception is thrown during object construction/copy
          node = Nokogiri::XML("<root>").root
          refute_includes(node.inspect, "(no data)")

          if node.respond_to?(:data_ptr?)
            node.stub(:data_ptr?, false) do
              assert_includes(node.inspect, "(no data)")
            end
          end
        end

        def test_fragment_creates_appropriate_class
          frag = Nokogiri.XML("<root><child/></root>").at_css("child").fragment("<thing/>")
          assert_instance_of(Nokogiri::XML::DocumentFragment, frag)

          frag = Nokogiri.HTML4("<root><child/></root>").at_css("child").fragment("<thing/>")
          assert_instance_of(Nokogiri::HTML4::DocumentFragment, frag)
        end

        def test_fragment_creates_elements
          apple = xml.fragment("<Apple/>")
          apple.children.each do |child|
            assert_equal(Nokogiri::XML::Node::ELEMENT_NODE, child.type)
            assert_instance_of(Nokogiri::XML::Element, child)
          end
        end

        def test_node_added_to_root_should_get_namespace
          fruits = Nokogiri::XML(<<~XML)
            <Fruit xmlns='http://www.fruits.org'>
            </Fruit>
          XML
          apple = fruits.fragment("<Apple/>")
          fruits.root << apple
          assert_equal(1, fruits.xpath("//xmlns:Apple").length)
        end

        def test_new_node_can_have_ancestors
          xml = Nokogiri::XML("<root>text</root>")
          item = Nokogiri::XML::Element.new("item", xml)
          assert_equal(0, item.ancestors.length)
        end

        def test_children
          doc = Nokogiri::XML(<<~XML)
            <root>#{"<a/>" * 9}</root>
          XML
          assert_equal(9, doc.root.children.length)
          assert_equal(9, doc.root.children.to_a.length)

          doc = Nokogiri::XML(<<~XML)
            <root>#{"<a/>" * 15}</root>
          XML
          assert_equal(15, doc.root.children.length)
          assert_equal(15, doc.root.children.to_a.length)
        end

        def test_add_namespace
          node = xml.at("address")
          node.add_namespace("foo", "http://tenderlovemaking.com")
          assert_equal("http://tenderlovemaking.com", node.namespaces["xmlns:foo"])
        end

        def test_add_namespace_twice
          node = xml.at("address")
          ns = node.add_namespace("foo", "http://tenderlovemaking.com")
          ns2 = node.add_namespace("foo", "http://tenderlovemaking.com")
          assert_equal(ns, ns2)
        end

        def test_add_default_namespace
          node = xml.at("address")
          node.add_namespace(nil, "http://tenderlovemaking.com")
          assert_equal("http://tenderlovemaking.com", node.namespaces["xmlns"])
        end

        def test_add_default_namespace_twice
          node = xml.at("address")
          ns = node.add_namespace(nil, "http://tenderlovemaking.com")
          ns2 = node.add_namespace(nil, "http://tenderlovemaking.com")
          assert_same(ns, ns2)
        end

        def test_add_multiple_namespaces
          node = xml.at("address")

          node.add_namespace(nil, "http://tenderlovemaking.com")
          assert_equal("http://tenderlovemaking.com", node.namespaces["xmlns"])

          node.add_namespace("foo", "http://tenderlovemaking.com")
          assert_equal("http://tenderlovemaking.com", node.namespaces["xmlns:foo"])
        end

        def test_default_namespace=
          node = xml.at("address")
          node.default_namespace = "http://tenderlovemaking.com"
          assert_equal("http://tenderlovemaking.com", node.namespaces["xmlns"])
        end

        def test_namespace=
          node = xml.at("address")
          assert_nil(node.namespace)
          definition = node.add_namespace_definition("bar", "http://tlm.com/")

          node.namespace = definition

          assert_equal(definition, node.namespace)

          assert_equal(node, xml.at("//foo:address", {
            "foo" => "http://tlm.com/",
          }))
        end

        def test_add_namespace_with_nil_associates_node
          node = xml.at("address")
          assert_nil(node.namespace)
          definition = node.add_namespace_definition(nil, "http://tlm.com/")
          assert_equal(definition, node.namespace)
        end

        def test_add_namespace_does_not_associate_node
          node = xml.at("address")
          assert_nil(node.namespace)
          assert(node.add_namespace_definition("foo", "http://tlm.com/"))
          assert_nil(node.namespace)
        end

        def test_set_namespace_from_different_doc
          node = xml.at("address")
          doc = Nokogiri::XML(File.read(XML_FILE), XML_FILE)
          decl = doc.root.add_namespace_definition("foo", "bar")

          assert_raises(ArgumentError) do
            node.namespace = decl
          end
        end

        def test_set_namespace_must_only_take_a_namespace
          node = xml.at("address")
          assert_raises(TypeError) do
            node.namespace = node
          end
        end

        def test_at
          node = xml.at("address")
          assert_equal(node, xml.xpath("//address").first)
        end

        def test_at_self
          node = xml.at("address")
          assert_equal(node, node.at("."))
        end

        def test_at_xpath
          node = xml.at_xpath("//address")
          nodes = xml.xpath("//address")
          assert_equal(5, nodes.size)
          assert_equal(node, nodes.first)
        end

        def test_at_css
          node = xml.at_css("address")
          nodes = xml.css("address")
          assert_equal(5, nodes.size)
          assert_equal(node, nodes.first)
        end

        def test_percent
          node = xml % "address"
          assert_equal(node, xml.xpath("//address").first)
        end

        def test_accept
          visitor = Class.new do
            attr_accessor :visited

            def accept(target)
              target.accept(self)
            end

            def visit(node)
              node.children.each { |c| c.accept(self) }
              @visited = true
            end
          end.new
          visitor.accept(xml.root)
          assert(visitor.visited)
        end

        def test_write_to
          io = StringIO.new
          xml.write_to(io)
          io.rewind
          assert_equal(xml.to_xml, io.read)
        end

        def test_write_to_with_block
          called = false
          io = StringIO.new
          conf = nil
          xml.write_to(io) do |config|
            called = true
            conf = config
            config.format.as_html.no_empty_tags
          end
          io.rewind
          assert(called)
          string = io.read
          assert_equal(xml.serialize(nil, conf.options), string)
          assert_equal(xml.serialize(nil, conf), string)
        end

        ["xml", "html", "xhtml"].each do |type|
          define_method(:"test_write_#{type}_to") do
            io = StringIO.new
            assert xml.send(:"write_#{type}_to", io)
            io.rewind
            assert_match xml.send(:"to_#{type}"), io.read
          end
        end

        def test_write_to_file_without_encoding
          Tempfile.create do |io|
            xml.write_to(io)
            io.rewind
            assert_equal(xml.to_xml, io.read)
          end
        end

        def test_serialize_with_block
          called = false
          conf = nil
          string = xml.serialize do |config|
            called = true
            conf = config
            config.format.as_html.no_empty_tags
          end
          assert(called)
          assert_equal(xml.serialize(nil, conf.options), string)
          assert_equal(xml.serialize(nil, conf), string)
        end

        def test_hold_reference_to_subnode
          doc = Nokogiri::XML(<<~XML)
            <root>
              <a>
                <b />
              </a>
            </root>
          XML
          assert(node_a = doc.css("a").first)
          assert(node_b = node_a.css("b").first)
          node_a.unlink
          assert_equal("b", node_b.name)
        end

        def test_xml_node_new
          assert(node = Nokogiri::XML::Node.new("input", xml))
          assert_equal(Nokogiri::XML::Node::ELEMENT_NODE, node.node_type)
          assert_instance_of(Nokogiri::XML::Element, node)
          assert_equal("input", node.name)
          assert_equal(xml, node.document)
        end

        def test_xml_node_new_with_block
          block_param = nil
          block_called = false
          node = Nokogiri::XML::Node.new("input", xml) do |node_param|
            block_called = true
            block_param = node_param
          end
          assert(node)
          assert(block_called, "Node.new block should be called")
          assert_equal(node, block_param, "Node.new block should be passed the new node")
        end

        def test_xml_node_new_must_take_document_type
          assert_raises(ArgumentError) do
            Nokogiri::XML::Node.new("input", "not-a-document")
          end

          assert_output(nil, /deprecated/) do
            Nokogiri::XML::Node.new("input", xml.root.children.first)
          end
        end

        def test_to_str
          name = xml.xpath("//name").first
          assert_match(/Margaret/, "" + name)
          assert_equal("Margaret Martin", "" + name.children.first)
        end

        def test_ancestors
          address = xml.xpath("//address").first
          assert_equal(3, address.ancestors.length)
          assert_equal(
            ["employee", "staff", "document"],
            address.ancestors.map(&:name),
          )
        end

        def test_read_only?
          assert(entity_decl = xml.internal_subset.children.find do |x|
            x.type == Node::ENTITY_DECL
          end)
          assert_predicate(entity_decl, :read_only?)
        end

        def test_set_content_with_symbol
          node = xml.at("//name")
          node.content = :foo
          assert_equal("foo", node.content)
        end

        def test_set_native_content_is_unescaped
          comment = Nokogiri.XML("<r><!-- foo --></r>").at("//comment()")

          comment.native_content = " < " # content= will escape this string
          assert_equal("<!-- < -->", comment.to_xml)
        end

        def test_find_by_css_class_with_nonstandard_whitespace
          doc = Nokogiri::HTML("<div class='a\nb'></div>")
          refute_nil(doc.at_css(".b"))
        end

        def test_find_by_css_with_tilde_eql
          xml = Nokogiri::XML.parse(<<~XML)
            <root>
              <a>Hello world</a>
              <a class='foo bar'>Bar</a>
              <a class='bar foo'>Bar</a>
              <a class='bar'>Bar</a>
              <a class='baz bar foo'>Bar</a>
              <a class='bazbarfoo'>Awesome</a>
              <a class='bazbar'>Awesome</a>
            </root>
          XML
          set = xml.css('a[@class~="bar"]')
          assert_equal(4, set.length)
          assert_equal(["Bar"], set.map(&:content).uniq)
        end

        def test_unlink
          xml = Nokogiri::XML.parse(<<~XML)
            <root>
              <a class='foo bar'>Bar</a>
              <a class='bar foo'>Bar</a>
              <a class='bar'>Bar</a>
              <a>Hello world</a>
              <a class='baz bar foo'>Bar</a>
              <a class='bazbarfoo'>Awesome</a>
              <a class='bazbar'>Awesome</a>
            </root>
          XML
          node = xml.xpath("//a")[3]
          assert_equal("Hello world", node.text)
          assert_match(/Hello world/, xml.to_s)
          assert(node.parent)
          assert(node.document)
          assert(node.previous_sibling)
          assert(node.next_sibling)
          node.unlink
          refute(node.parent)
          # assert !node.document
          refute(node.previous_sibling)
          refute(node.next_sibling)
          refute_match(/Hello world/, xml.to_s)
        end

        def test_next_sibling
          assert(node = xml.root)
          assert(sibling = node.child.next_sibling)
          assert_equal("employee", sibling.name)
        end

        def test_previous_sibling
          assert(node = xml.root)
          assert(sibling = node.child.next_sibling)
          assert_equal("employee", sibling.name)
          assert_equal(sibling.previous_sibling, node.child)
        end

        def test_name=
          assert(node = xml.root)
          node.name = "awesome"
          assert_equal("awesome", node.name)
        end

        def test_child
          assert(node = xml.root)
          assert(child = node.child)
          assert_equal("text", child.name)
        end

        def test_key?
          assert(node = xml.search("//address").first)
          refute(node.key?("asdfasdf"))
        end

        def test_set_property
          assert(node = xml.search("//address").first)
          node["foo"] = "bar"
          assert_equal("bar", node["foo"])
        end

        def test_set_property_non_string
          assert(node = xml.search("//address").first)
          node["foo"] = 1
          assert_equal("1", node["foo"])
          node["foo"] = false
          assert_equal("false", node["foo"])
        end

        def test_path
          assert(set = xml.search("//employee"))
          assert(node = set.first)
          assert_equal("/staff/employee[1]", node.path)
        end

        def test_parent_xpath
          assert(set = xml.search("//employee"))
          assert(node = set.first)
          assert(parent_set = node.search(".."))
          assert(parent_node = parent_set.first)
          assert_equal("/staff", parent_node.path)
          assert_equal(node.parent, parent_node)
        end

        def test_search_self
          node = xml.at("//employee")
          assert_equal(node.search(".").to_a, [node])
        end

        def test_search_by_symbol
          assert(set = xml.search(:employee))
          assert_equal(5, set.length)

          assert(node = xml.at(:employee))
          assert_match(/EMP0001/, node.text)
        end

        def test_encode_special_chars
          foo = xml.css("employee").first.encode_special_chars("&")
          assert_equal("&amp;", foo)
        end

        def test_content_equals
          node = Nokogiri::XML::Node.new("form", xml)
          assert_equal("", node.content)

          node.content = "hello world!"
          assert_equal("hello world!", node.content)

          node.content = "& <foo> &amp;"
          assert_equal("& <foo> &amp;", node.content)
          assert_equal("<form>&amp; &lt;foo&gt; &amp;amp;</form>", node.to_xml)

          node.content = "1234 <-> 1234"
          assert_equal("1234 <-> 1234", node.content)
          assert_equal("<form>1234 &lt;-&gt; 1234</form>", node.to_xml)

          node.content = "1234"
          node.add_child("<foo>5678</foo>")
          assert_equal("12345678", node.content)
        end

        # issue #839
        def test_encoding_of_copied_nodes
          d1 = Nokogiri::XML("<r><a>&amp;</a></r>")
          d2 = Nokogiri::XML("<r></r>")
          ne = d1.root.xpath("//a").first.dup(1)
          ne.content += "& < & > \" &"
          d2.root << ne
          assert_match(%r{<a>&amp;&amp; &lt; &amp; &gt; \" &amp;</a>}, d2.to_s)
        end

        def test_content_after_appending_text
          doc = Nokogiri::XML("<foo />")
          node = doc.children.first
          node.content = "bar"
          node << "baz"
          assert_equal("barbaz", node.content)
        end

        def test_content_depth_first
          node = Nokogiri::XML("<foo>first<baz>second</baz>third</foo>")
          assert_equal("firstsecondthird", node.content)
        end

        def test_set_content_should_unlink_existing_content
          node     = xml.at_css("employee")
          children = node.children
          node.content = "hello"
          children.each { |child| assert_nil(child.parent) }
        end

        def test_whitespace_nodes
          doc = Nokogiri::XML.parse("<root><b>Foo</b>\n<i>Bar</i> <p>Bazz</p></root>")
          children = doc.at("//root").children.collect(&:to_s)
          assert_equal("\n", children[1])
          assert_equal(" ", children[3])
        end

        def test_node_equality
          doc1 = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
          doc2 = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)

          address1_1 = doc1.xpath("//address").first
          address1_2 = doc1.xpath("//address").first

          address2 = doc2.xpath("//address").first

          refute_equal(address1_1, address2) # two references to very, very similar nodes
          assert_equal(address1_1, address1_2) # two references to the exact same node
        end

        def test_namespace_search_with_xpath_and_hash
          xml = Nokogiri::XML.parse(<<~XML)
            <root>
              <car xmlns:part="http://general-motors.com/">
                <part:tire>Michelin Model XGV</part:tire>
              </car>
              <bicycle xmlns:part="http://schwinn.com/">
                <part:tire>I'm a bicycle tire!</part:tire>
              </bicycle>
            </root>
          XML

          tires = xml.xpath("//bike:tire", { "bike" => "http://schwinn.com/" })
          assert_equal(1, tires.length)
        end

        def test_namespace_search_with_xpath_and_hash_with_symbol_keys
          xml = Nokogiri::XML.parse(<<~XML)
            <root>
              <car xmlns:part="http://general-motors.com/">
                <part:tire>Michelin Model XGV</part:tire>
              </car>
              <bicycle xmlns:part="http://schwinn.com/">
                <part:tire>I'm a bicycle tire!</part:tire>
              </bicycle>
            </root>
          XML

          tires = xml.xpath("//bike:tire", bike: "http://schwinn.com/")
          assert_equal(1, tires.length)
        end

        def test_namespace_search_with_css
          xml = Nokogiri::XML.parse(<<~XML)
            <root>
              <car xmlns:part="http://general-motors.com/">
                <part:tire>Michelin Model XGV</part:tire>
              </car>
              <bicycle xmlns:part="http://schwinn.com/">
                <part:tire>I'm a bicycle tire!</part:tire>
              </bicycle>
            </root>
          XML

          tires = xml.css("bike|tire", "bike" => "http://schwinn.com/")
          assert_equal(1, tires.length)
        end

        def test_namespaced_attribute_search_with_xpath
          # from #593
          xml_content = <<~XML
            <?xml version="1.0"?>
            <ns1:el1 xmlns:ns1="http://blabla.com" >
              <ns1:el2 ns1:att="123">with namespace</ns1:el2 >
              <ns1:el2 att="noNameSpace">no namespace</ns1:el2 >
            </ns1:el1>
          XML
          xml_doc = Nokogiri::XML(xml_content)

          no_ns = xml_doc.xpath("//*[@att]")
          assert_equal(1, no_ns.length)
          assert_equal("no namespace", no_ns.first.content)

          with_ns = xml_doc.xpath("//*[@ns1:att]")
          assert_equal(1, with_ns.length)
          assert_equal("with namespace", with_ns.first.content)
        end

        def test_namespaced_attribute_search_with_css
          # from #593
          xml_content = <<~XML
            <?xml version="1.0"?>
            <ns1:el1 xmlns:ns1="http://blabla.com" >
              <ns1:el2 ns1:att="123">with namespace</ns1:el2 >
              <ns1:el2 att="noNameSpace">no namespace</ns1:el2 >
            </ns1:el1>
          XML
          xml_doc = Nokogiri::XML(xml_content)

          no_ns = xml_doc.css("*[att]")
          assert_equal(1, no_ns.length)
          assert_equal("no namespace", no_ns.first.content)

          with_ns = xml_doc.css("*[ns1|att]")
          assert_equal(1, with_ns.length)
          assert_equal("with namespace", with_ns.first.content)
        end

        def test_namespaces_should_include_all_namespace_definitions
          xml = Nokogiri::XML.parse(<<~XML)
            <x xmlns="http://quux.com/" xmlns:a="http://foo.com/" xmlns:b="http://bar.com/">
              <y xmlns:c="http://bazz.com/">
                <z>hello</z>
                <a xmlns:c="http://newc.com/" />
              </y>
            </x>
          XML

          namespaces = xml.namespaces # Document#namespace
          assert_equal(
            {
              "xmlns" => "http://quux.com/",
              "xmlns:a" => "http://foo.com/",
              "xmlns:b" => "http://bar.com/",
            },
            namespaces,
          )

          namespaces = xml.root.namespaces
          assert_equal(
            {
              "xmlns" => "http://quux.com/",
              "xmlns:a" => "http://foo.com/",
              "xmlns:b" => "http://bar.com/",
            },
            namespaces,
          )

          namespaces = xml.at_xpath("//xmlns:y").namespaces
          assert_equal(
            {
              "xmlns" => "http://quux.com/",
              "xmlns:a" => "http://foo.com/",
              "xmlns:b" => "http://bar.com/",
              "xmlns:c" => "http://bazz.com/",
            },
            namespaces,
          )

          namespaces = xml.at_xpath("//xmlns:z").namespaces
          assert_equal(
            {
              "xmlns" => "http://quux.com/",
              "xmlns:a" => "http://foo.com/",
              "xmlns:b" => "http://bar.com/",
              "xmlns:c" => "http://bazz.com/",
            },
            namespaces,
          )

          namespaces = xml.at_xpath("//xmlns:a").namespaces
          assert_equal(
            {
              "xmlns" => "http://quux.com/",
              "xmlns:a" => "http://foo.com/",
              "xmlns:b" => "http://bar.com/",
              "xmlns:c" => "http://newc.com/",
            },
            namespaces,
          )
        end

        def test_namespace
          xml = Nokogiri::XML.parse(<<~XML)
            <x xmlns:a='http://foo.com/' xmlns:b='http://bar.com/'>
              <y xmlns:c='http://bazz.com/'>
                <a:div>hello a</a:div>
                <b:div>hello b</b:div>
                <c:div x="1" b:y="2">hello c</c:div>
                <div x="1" xmlns="http://ns.example.com/d"/>
                <div x="1">hello moon</div>
              </y>
            </x>
          XML
          set = xml.search("//y/*")
          assert_equal("a", set[0].namespace.prefix)
          assert_equal("http://foo.com/", set[0].namespace.href)
          assert_equal("b", set[1].namespace.prefix)
          assert_equal("http://bar.com/", set[1].namespace.href)
          assert_equal("c", set[2].namespace.prefix)
          assert_equal("http://bazz.com/", set[2].namespace.href)
          assert_nil(set[3].namespace.prefix) # default namespace
          assert_equal("http://ns.example.com/d", set[3].namespace.href)
          assert_nil(set[4].namespace) # no namespace

          assert_equal("b", set[2].attributes["y"].namespace.prefix)
          assert_equal("http://bar.com/", set[2].attributes["y"].namespace.href)
          assert_nil(set[2].attributes["x"].namespace)
          assert_nil(set[3].attributes["x"].namespace)
          assert_nil(set[4].attributes["x"].namespace)
        end

        def test_namespace_without_an_href_on_html_node
          #
          #  describe how we handle microsoft word's HTML formatting.
          #  this test is descriptive, not prescriptive.
          #
          html = Nokogiri::HTML4.parse(<<~XML)
            <div><o:p>foo</o:p></div>
          XML
          node = html.at("div").children.first
          refute_nil(node)

          if Nokogiri.uses_libxml?(">= 2.10.4") || Nokogiri.jruby?
            assert_empty(node.namespaces.keys)
            assert_equal("<o:p>foo</o:p>", node.to_html)
          elsif Nokogiri.uses_libxml?(">= 2.9.12")
            assert_empty(node.namespaces.keys)
            assert_equal("<p>foo</p>", node.to_html)
          elsif Nokogiri.uses_libxml?
            assert_equal(1, node.namespaces.keys.size)
            assert(node.namespaces.key?("xmlns:o"))
            assert_nil(node.namespaces["xmlns:o"])
            assert_equal("<p>foo</p>", node.to_html)
          end
        end

        def test_xpath_results_have_document_and_are_decorated
          x = Module.new do
            def awesome!; end
          end
          util_decorate(xml, x)
          node_set = xml.xpath("//employee")
          assert_equal(xml, node_set.document)
          assert_respond_to(node_set, :awesome!)
        end

        def test_css_results_have_document_and_are_decorated
          x = Module.new do
            def awesome!; end
          end
          util_decorate(xml, x)
          node_set = xml.css("employee")
          assert_equal(xml, node_set.document)
          assert_respond_to(node_set, :awesome!)
        end

        def test_blank_eh
          refute_predicate(Nokogiri(""), :blank?)
          refute_predicate(Nokogiri("<root><child/></root>").root.child, :blank?)
          assert_predicate(Nokogiri("<root>\t \n</root>").root.child, :blank?)
          assert_predicate(Nokogiri("<root><![CDATA[\t \n]]></root>").root.child, :blank?)
          assert_predicate(Nokogiri("<root>not-blank</root>").root.child.tap { |n| n.content = "" }, :blank?)
        end

        def test_to_xml_allows_to_serialize_with_as_xml_save_option
          xml = Nokogiri::XML("<root><ul><li>Hello world</li></ul></root>")
          set = xml.search("//ul")
          node = set.first

          refute_match("<ul>\n  <li>", xml.to_xml(save_with: XML::Node::SaveOptions::AS_XML))
          refute_match("<ul>\n  <li>", node.to_xml(save_with: XML::Node::SaveOptions::AS_XML))
        end

        # issue 647
        def test_default_namespace_should_be_created
          subject = Nokogiri::XML.parse('<foo xml:bar="http://bar.com"/>').root
          ns = subject.attributes["bar"].namespace
          refute_nil(ns)
          assert_equal(ns.class, Nokogiri::XML::Namespace)
          assert_equal("xml", ns.prefix)
          assert_equal("http://www.w3.org/XML/1998/namespace", ns.href)
        end

        # issue 648
        def test_namespace_without_prefix_should_be_set
          node = Nokogiri::XML.parse('<foo xmlns="http://bar.com"/>').root
          subject = Nokogiri::XML::Node.new("foo", node.document)
          subject.namespace = node.namespace
          ns = subject.namespace
          assert_equal(ns.class, Nokogiri::XML::Namespace)
          assert_nil(ns.prefix)
          assert_equal("http://bar.com", ns.href)
        end

        # issue 695
        def test_namespace_in_rendered_xml
          document = Nokogiri::XML::Document.new
          subject = Nokogiri::XML::Node.new("foo", document)
          ns = subject.add_namespace(nil, "bar")
          subject.namespace = ns
          assert_match(/xmlns="bar"/, subject.to_xml)
        end

        # issue 771
        def test_format_noblank
          content = <<~XML
            <foo>
              <bar>hello</bar>
            </foo>
          XML
          subject = Nokogiri::XML(content) do |conf|
            conf.default_xml.noblanks
          end

          assert_match(%r{<bar>hello</bar>}, subject.to_xml(indent: 2))
        end

        def test_text_node_colon
          document = Nokogiri::XML::Document.new
          root = Nokogiri::XML::Node.new("foo", document)
          document.root = root
          root << "<a>hello:with_colon</a>"
          assert_match(/hello:with_colon/, document.to_xml)
        end

        def test_document_eh
          html_doc = Nokogiri::HTML("<div>foo</div>")
          xml_doc = Nokogiri::XML("<div>foo</div>")
          html_node = html_doc.at_css("div")
          xml_node = xml_doc.at_css("div")

          assert_predicate(html_doc, :document?)
          assert_predicate(xml_doc, :document?)
          refute_predicate(html_node, :document?)
          refute_predicate(xml_node, :document?)
        end

        def test_processing_instruction_eh
          xml_doc = Nokogiri::XML(%{<?xml version="1.0"?>\n<?xml-stylesheet type="text/xsl" href="foo.xsl"?>\n<?xml-stylesheet type="text/xsl" href="foo2.xsl"?>\n<root><div>foo</div></root>})
          pi_node = xml_doc.children.first
          div_node = xml_doc.at_css("div")
          assert_predicate(pi_node, :processing_instruction?)
          refute_predicate(div_node, :processing_instruction?)
        end

        def test_node_lang
          document = Nokogiri::XML(<<~XML)
            <root>
              <div class='english'  xml:lang='en'>
                <div class='english_child'>foo</div>
              </div>
              <div class='japanese' xml:lang='jp'>bar</div>
              <div class='unspecified'>bar</div>
            </root>
          XML
          assert_equal("en", document.at_css(".english").lang)
          assert_equal("en", document.at_css(".english_child").lang)
          assert_equal("jp", document.at_css(".japanese").lang)
          assert_nil(document.at_css(".unspecified").lang)
        end

        def test_set_node_lang
          document = Nokogiri::XML("<root><div class='subject'>foo</div></root>")
          subject = document.at_css(".subject")

          subject.lang = "de"
          assert_equal("de", subject.lang)

          subject.lang = "fr"
          assert_equal("fr", subject.lang)
        end

        # issue 2559
        def test_serialize_unparented_node
          assert_equal("asdf", Nokogiri::HTML4::Document.parse("<div></div>").create_text_node("asdf").to_s)
        end

        describe "#wrap" do
          let(:xml) { "<root><thing><div>important thing</div></thing></root>" }
          let(:doc) { Nokogiri::XML(xml) }

          describe "string markup argument" do
            it "parses and wraps" do
              thing = doc.at_css("thing")
              rval = thing.wrap("<wrapper/>")
              wrapper = doc.at_css("wrapper")

              assert_equal(rval, thing)
              assert_equal(wrapper, thing.parent)
              assert_equal("root", wrapper.parent.name)
              assert_equal(1, wrapper.children.length)
              assert_equal("thing", wrapper.children.first.name)
            end

            it "wraps unparented nodes" do
              thing = doc.create_element("thing")
              thing.wrap("<wrapper/>")

              assert_equal("wrapper", thing.parent.name)
              assert_nil(thing.parent.parent)
            end
          end

          describe "Node argument" do
            it "wraps using a dup of the node" do
              thing = doc.at_css("thing")
              wrapper_template = doc.create_element("wrapper")
              rval = thing.wrap(wrapper_template)
              wrapper = doc.at_css("wrapper")

              assert_equal(rval, thing)
              refute_equal(wrapper, wrapper_template)
              assert_equal(wrapper, thing.parent)
              assert_equal("root", wrapper.parent.name)
              assert_equal(1, wrapper.children.length)
              assert_equal("thing", wrapper.children.first.name)
            end

            it "wraps unparented nodes" do
              thing = doc.create_element("thing")
              wrapper_template = doc.create_element("wrapper")
              thing.wrap(wrapper_template)

              refute_equal(wrapper_template, thing.parent)
              assert_equal("wrapper", thing.parent.name)
              assert_nil(thing.parent.parent)
            end
          end

          it "raises an error if the input is not parseable" do
            thing = doc.at_css("thing")

            e = assert_raises(RuntimeError) do
              thing.wrap("<<")
            end
            assert_includes(e.message, "Failed to parse '<<' in the context of a 'root' element")
          end

          it "raises an ArgumentError on other types" do
            thing = doc.at_css("thing")

            e = assert_raises(ArgumentError) do
              thing.wrap(1)
            end
            assert_includes(e.message, "Requires a String or Node argument, and cannot accept a Integer")
          end
        end

        describe "#line" do
          it "counts lines" do
            xml = Nokogiri::XML(<<~XML)
              <a>
                <b>Test</b>
              </a>
            XML

            if Nokogiri.jruby?
              # in the output
              assert_equal(3, xml.at_css("b").line)
            else
              # in the input
              assert_equal(2, xml.at_css("b").line)
            end
          end

          it "properly numbers lines with documents containing XML prolog" do
            xml = Nokogiri::XML(<<~XML)
              <?xml version="1.0" ?>
              <a>
                <b>Test</b>
              </a>
            XML

            assert_equal(3, xml.at_css("b").line)
          end

          it "properly numbers lines with documents containing XML comments" do
            xml = Nokogiri::XML(<<~XML)
              <a>
                <b>
                  <!-- This is a comment -->
                  <c>Test</c>
                </b>
              </a>
            XML

            if Nokogiri.jruby?
              assert_equal(5, xml.at_css("c").line)
            else
              assert_equal(4, xml.at_css("c").line)
            end
          end

          it "properly numbers lines with documents containing XML multiline comments" do
            xml = Nokogiri::XML(<<~XML)
              <a>
                <b>
                  <!--
                    This is a comment
                  -->
                  <c>
                    Test
                  </c>
                </b>
              </a>
            XML

            if Nokogiri.jruby?
              assert_equal(7, xml.at_css("c").line)
            else
              assert_equal(6, xml.at_css("c").line)
            end
          end

          it "returns a sensible line number for each node" do
            xml = Nokogiri::XML(<<~XML)
              <a>
                <b>
                  Hello world
                </b>
                <b>
                  Goodbye world
                </b>
              </root>
            XML

            set = xml.css("b")
            if Nokogiri.jruby?
              assert_equal(3, set[0].line)
              assert_equal(6, set[1].line)
            else
              assert_equal(2, set[0].line)
              assert_equal(5, set[1].line)
            end
          end

          it "supports a line number greater than a short int" do
            max_short_int = (1 << 16) - 1
            xml = StringIO.new.tap do |io|
              io << "<root>"
              max_short_int.times do |j|
                io << "<a>#{j}</a>\n"
                io << "<b>#{j}</b>\n"
              end
              io << "<x/>\n"
              io << "</root>"
            end.string

            if Nokogiri.uses_libxml?
              doc = Nokogiri::XML(xml, &:nobig_lines)
              node = doc.at_css("x")
              assert_equal(node.line, max_short_int)
            end

            doc = Nokogiri::XML(xml)
            node = doc.at_css("x")
            assert_operator(node.line, :>, max_short_int)
          end
        end

        describe "#line=" do
          it "overrides the line number of a node" do
            skip_unless_libxml2("Xerces does not have line numbers for nodes")
            document = Nokogiri::XML::Document.new
            node = document.create_element("a")
            node.line = 54321
            assert_equal(54321, node.line)
          end

          it "supports a line number greater than a short int for text nodes" do
            skip_unless_libxml2("Xerces does not have line numbers for nodes")

            max_short_int = (1 << 16) - 1
            line_number = max_short_int + 100

            document = Nokogiri::XML::Document.parse("<root><a>text node</a></root>")
            node = document.at_css("a").children.first
            node.line = line_number
            assert_equal(line_number, node.line)
          end
        end
      end
    end
  end
end
