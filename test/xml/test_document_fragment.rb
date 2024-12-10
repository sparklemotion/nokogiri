# frozen_string_literal: true

require "helper"

module Nokogiri
  module XML
    class TestDocumentFragment < Nokogiri::TestCase
      describe Nokogiri::XML::DocumentFragment do
        let(:xml) { Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE) }

        def test_replace_text_node
          html = "foo"
          doc = Nokogiri::XML::DocumentFragment.parse(html)
          doc.children[0].replace("bar")
          assert_equal("bar", doc.children[0].content)
        end

        def test_fragment_is_relative
          doc      = Nokogiri::XML('<root><a xmlns="blah" /></root>')
          ctx      = doc.root.child
          fragment = Nokogiri::XML::DocumentFragment.new(doc, "<hello />", ctx)
          hello    = fragment.child

          assert_equal("hello", hello.name)
          assert_equal(doc.root.child.namespace, hello.namespace)
        end

        def test_node_fragment_is_relative
          doc = Nokogiri::XML('<root><a xmlns="blah" /></root>')
          assert(doc.root.child)
          fragment = doc.root.child.fragment("<hello />")
          hello    = fragment.child

          assert_equal("hello", hello.name)
          assert_equal(doc.root.child.namespace, hello.namespace)
        end

        def test_new
          assert(Nokogiri::XML::DocumentFragment.new(xml))
        end

        def test_fragment_should_have_document
          fragment = Nokogiri::XML::DocumentFragment.new(xml)
          assert_equal(xml, fragment.document)
        end

        def test_name
          fragment = Nokogiri::XML::DocumentFragment.new(xml)
          assert_equal("#document-fragment", fragment.name)
        end

        def test_static_method
          fragment = Nokogiri::XML::DocumentFragment.parse("<div>a</div>")
          assert_instance_of(Nokogiri::XML::DocumentFragment, fragment)
        end

        def test_static_method_with_namespaces
          # follows different path in FragmentHandler#start_element which blew up after 597195ff
          fragment = Nokogiri::XML::DocumentFragment.parse("<o:div>a</o:div>")
          assert_instance_of(Nokogiri::XML::DocumentFragment, fragment)
        end

        def test_unparented_text_node_parse
          # https://github.com/sparklemotion/nokogiri/issues/407
          refute_raises do
            fragment = Nokogiri::XML::DocumentFragment.parse("foo")
            fragment.children.after("<bar/>")
          end
        end

        def test_xml_fragment
          fragment = Nokogiri::XML.fragment("<div>a</div>")
          assert_equal("<div>a</div>", fragment.to_s)
        end

        def test_xml_fragment_has_multiple_toplevel_children
          doc = "<div>b</div><div>e</div>"
          fragment = Nokogiri::XML::Document.new.fragment(doc)
          assert_equal("<div>b</div><div>e</div>", fragment.to_s)
        end

        def test_xml_fragment_has_outer_text
          # this test is descriptive, not prescriptive.
          doc = "a<div>b</div>"
          fragment = Nokogiri::XML::Document.new.fragment(doc)
          assert_equal("a<div>b</div>", fragment.to_s)

          doc = "<div>b</div>c"
          fragment = Nokogiri::XML::Document.new.fragment(doc)
          assert_equal("<div>b</div>c", fragment.to_s)
        end

        def test_xml_fragment_case_sensitivity
          doc = "<crazyDiv>b</crazyDiv>"
          fragment = Nokogiri::XML::Document.new.fragment(doc)
          assert_equal("<crazyDiv>b</crazyDiv>", fragment.to_s)
        end

        def test_xml_fragment_with_leading_whitespace
          doc = "     <div>b</div>  "
          fragment = Nokogiri::XML::Document.new.fragment(doc)
          assert_equal("     <div>b</div>  ", fragment.to_s)
        end

        def test_xml_fragment_with_leading_whitespace_and_newline
          doc = "     \n<div>b</div>  "
          fragment = Nokogiri::XML::Document.new.fragment(doc)
          assert_equal("     \n<div>b</div>  ", fragment.to_s)
        end

        def test_fragment_children_search
          fragment = Nokogiri::XML::Document.new.fragment(
            '<div><p id="content">hi</p></div>',
          )
          expected = fragment.children.xpath(".//p")
          assert_equal(1, expected.length)

          css          = fragment.children.css("p")
          search_css   = fragment.children.search("p")
          search_xpath = fragment.children.search(".//p")
          assert_equal(expected, css)
          assert_equal(expected, search_css)
          assert_equal(expected, search_xpath)
        end

        def test_fragment_css_search_with_whitespace_and_node_removal
          # The same xml without leading whitespace in front of the first line
          # does not expose the error. Putting both nodes on the same line
          # instead also fixes the crash.
          fragment = Nokogiri::XML::DocumentFragment.parse(<<~EOXML)
            <p id="content">hi</p> x <!--y--> <p>another paragraph</p>
          EOXML
          children = fragment.css("p")
          assert_equal(2, children.length)
          # removing the last node instead does not yield the error. Probably the
          # node removal leaves around two consecutive text nodes which make the
          # css search crash?
          children.first.remove
          assert_equal(1, fragment.xpath(".//p | self::p").length)
          assert_equal(1, fragment.css("p").length)
        end

        def test_fragment_search_three_ways
          frag = Nokogiri::XML::Document.new.fragment('<p id="content">foo</p><p id="content">bar</p>')
          expected = frag.xpath('./*[@id = "content"]')
          assert_equal(2, expected.length)

          [
            [:css, "#content"],
            [:search, "#content"],
            [:search, "./*[@id = 'content']"],
          ].each do |method, query|
            result = frag.send(method, query)
            assert_equal(
              expected,
              result,
              "fragment search with :#{method} using '#{query}' expected '#{expected}' got '#{result}'",
            )
          end
        end

        def test_search_direct_children_of_fragment
          xml = <<~XML
            <div class="section header" id="1">
              <div class="subsection header">sub 1</div>
              <div class="subsection header">sub 2</div>
            </div>
            <div class="section header" id="2">
              <div class="subsection header">sub 3</div>
              <div class="subsection header">sub 4</div>
            </div>
          XML
          fragment = Nokogiri::XML.fragment(xml)
          result = (fragment > "div.header")
          assert_equal(2, result.length)
          assert_equal(["1", "2"], result.map { |n| n["id"] })

          assert_empty(fragment > ".no-such-match")
        end

        def test_fragment_search_with_multiple_queries
          xml = <<~EOF
            <thing>
              <div class="title">important thing</div>
            </thing>
            <thing>
              <div class="content">stuff</div>
            </thing>
            <thing>
              <p class="blah">more stuff</div>
            </thing>
          EOF
          fragment = Nokogiri::XML.fragment(xml)
          assert_kind_of(Nokogiri::XML::DocumentFragment, fragment)

          assert_equal(3, fragment.xpath(".//div", ".//p").length)
          assert_equal(3, fragment.css(".title", ".content", "p").length)
          assert_equal(3, fragment.search(".//div", "p.blah").length)
        end

        def test_fragment_without_a_namespace_does_not_get_a_namespace
          doc = Nokogiri::XML(<<~EOX)
            <root xmlns="http://tenderlovemaking.com/" xmlns:foo="http://flavorjon.es/" xmlns:bar="http://google.com/">
              <foo:existing></foo:existing>
            </root>
          EOX
          frag = doc.fragment("<newnode></newnode>")
          assert_nil(frag.namespace)
        end

        def test_fragment_namespace_resolves_against_document_root
          doc = Nokogiri::XML(<<~EOX)
            <root xmlns:foo="http://flavorjon.es/" xmlns:bar="http://google.com/">
              <foo:existing></foo:existing>
            </root>
          EOX
          ns = doc.root.namespace_definitions.detect { |x| x.prefix == "bar" }

          frag = doc.fragment("<bar:newnode></bar:newnode>")
          assert(frag.children.first.namespace)
          assert_equal(ns, frag.children.first.namespace)
        end

        def test_fragment_invalid_namespace_is_silently_ignored
          doc = Nokogiri::XML(<<~EOX)
            <root xmlns:foo="http://flavorjon.es/" xmlns:bar="http://google.com/">
              <foo:existing></foo:existing>
            </root>
          EOX
          frag = doc.fragment("<baz:newnode></baz:newnode>")
          assert_nil(frag.children.first.namespace)
        end

        def test_decorator_is_applied
          x = Module.new do
            def awesome!
            end
          end
          util_decorate(xml, x)
          fragment = Nokogiri::XML::DocumentFragment.new(xml, "<div>a</div><div>b</div>")

          assert(node_set = fragment.css("div"))
          assert_respond_to(node_set, :awesome!)
          node_set.each do |node|
            assert_respond_to(node, :awesome!, node.class)
          end
          assert_respond_to(fragment.children, :awesome!, fragment.children.class)
        end

        def test_decorator_is_applied_to_empty_set
          x = Module.new do
            def awesome!
            end
          end
          util_decorate(xml, x)
          fragment = Nokogiri::XML::DocumentFragment.new(xml, "")
          assert_respond_to(fragment.children, :awesome!, fragment.children.class)
        end

        def test_add_node_to_doc_fragment_segfault
          skip_unless_libxml2("valgrind tests should only run with libxml2")

          refute_valgrind_errors do
            frag = Nokogiri::XML::DocumentFragment.new(xml, "<p>hello world</p>")
            Nokogiri::XML::Comment.new(frag, "moo")
          end
        end

        def test_issue_1077_parsing_of_frozen_strings
          input = <<~EOS
            <?xml version="1.0" encoding="utf-8"?>
            <library>
              <book title="I like turtles"/>
            </library>
          EOS
          input.freeze

          refute_raises do
            Nokogiri::XML::DocumentFragment.parse(input)
          end
        end

        def test_dup_should_exist_in_a_new_document
          skip_unless_libxml2("this is only true in the C extension")
          # https://github.com/sparklemotion/nokogiri/issues/1063
          original = Nokogiri::XML::DocumentFragment.parse("<div><p>hello</p></div>")
          duplicate = original.dup
          refute_equal(original.document, duplicate.document)
        end

        def test_dup_should_create_an_xml_document_fragment
          # https://github.com/sparklemotion/nokogiri/issues/1846
          original = Nokogiri::XML::DocumentFragment.parse("<div><p>hello</p></div>")
          duplicate = original.dup
          assert_instance_of(Nokogiri::XML::DocumentFragment, duplicate)
        end

        def test_dup_creates_tree_with_identical_structure
          original = Nokogiri::XML::DocumentFragment.parse("<div><p>hello</p></div>")
          duplicate = original.dup
          assert_equal(original.to_html, duplicate.to_html)
        end

        def test_dup_creates_tree_with_identical_structure_stress
          # https://github.com/sparklemotion/nokogiri/issues/3359
          skip_unless_libxml2("this is testing CRuby GC behavior")

          original = Nokogiri::XML::DocumentFragment.parse("<div><p>hello</p></div>")
          duplicate = original.dup

          stress_memory_while do
            duplicate.to_html
          end

          assert_equal(original.to_html, duplicate.to_html)
        end

        def test_dup_creates_mutable_tree
          original = Nokogiri::XML::DocumentFragment.parse("<div><p>hello</p></div>")
          duplicate = original.dup
          duplicate.at_css("div").add_child("<b>hello there</b>")
          assert_nil(original.at_css("b"))
          refute_nil(duplicate.at_css("b"))
        end

        def test_in_context_fragment_parsing_recovery
          skip("This tests behavior in libxml 2.13") unless Nokogiri.uses_libxml?(">= 2.13.0")

          # https://github.com/sparklemotion/nokogiri/issues/2092
          context_xml = "<root xmlns:n='https://example.com/foo'></root>"
          context_doc = Nokogiri::XML::Document.parse(context_xml)
          invalid_xml_fragment = "<n:a><b></n:a>" # note missing closing tag for `b`
          fragment = context_doc.root.parse(invalid_xml_fragment)

          assert_equal("a", fragment.first.name)
          assert_equal("n", fragment.first.namespace.prefix)
          assert_equal("https://example.com/foo", fragment.first.namespace.href)
        end

        def test_for_libxml_in_context_fragment_parsing_bug_workaround
          skip_unless_libxml2("valgrind tests should only run with libxml2")

          refute_valgrind_errors do
            fragment = Nokogiri::XML.fragment("<div></div>")
            parent = fragment.children.first
            child = parent.parse("<h1></h1>").first
            parent.add_child(child)
          end
        end

        def test_for_libxml_in_context_memory_badness_when_encountering_encoding_errors
          skip_unless_libxml2("valgrind tests should only run with libxml2")

          # see issue #643 for background
          refute_valgrind_errors do
            html = <<~EOHTML
              <html>
                <head>
                  <meta http-equiv="Content-Type" content="text/html; charset=shizzle" />
                </head>
                <body>
                  <div>Foo</div>
                </body>
              </html>
            EOHTML
            doc = Nokogiri::HTML(html)
            doc.at_css("div").replace("Bar")
          end
        end

        describe "parse options" do
          let(:xml_default) do
            Nokogiri::XML::ParseOptions.new(Nokogiri::XML::ParseOptions::DEFAULT_XML)
          end

          let(:xml_strict) do
            Nokogiri::XML::ParseOptions.new(Nokogiri::XML::ParseOptions::DEFAULT_XML).norecover
          end

          let(:input) { "<a>foo</a" }

          it "sets the test up correctly" do
            assert_predicate(xml_strict, :strict?)
          end

          describe "XML.fragment" do
            it "has sane defaults" do
              frag = Nokogiri::XML.fragment(input)
              assert_equal("<a>foo</a>", frag.to_html)
              refute_empty(frag.errors)
            end

            it "accepts options" do
              frag = Nokogiri::XML.fragment(input, xml_default)
              assert_equal("<a>foo</a>", frag.to_html)
              refute_empty(frag.errors)

              assert_raises(Nokogiri::SyntaxError) do
                Nokogiri::XML.fragment(input, xml_strict)
              end
            end

            it "accepts kwargs" do
              frag = Nokogiri::XML.fragment(input, options: xml_default)
              assert_equal("<a>foo</a>", frag.to_html)
              refute_empty(frag.errors)

              assert_raises(Nokogiri::SyntaxError) do
                Nokogiri::XML.fragment(input, options: xml_strict)
              end
            end

            it "takes a config block" do
              default_config = nil
              Nokogiri::XML.fragment(input) do |config|
                default_config = config
              end
              refute_predicate(default_config, :strict?)

              assert_raises(Nokogiri::SyntaxError) do
                Nokogiri::XML.fragment(input, &:norecover)
              end
            end
          end

          describe "XML::DocumentFragment.parse" do
            it "has sane defaults" do
              frag = Nokogiri::XML::DocumentFragment.parse(input)
              assert_equal("<a>foo</a>", frag.to_html)
              refute_empty(frag.errors)
            end

            it "accepts options" do
              frag = Nokogiri::XML::DocumentFragment.parse(input, xml_default)
              assert_equal("<a>foo</a>", frag.to_html)
              refute_empty(frag.errors)

              assert_raises(Nokogiri::SyntaxError) do
                Nokogiri::XML::DocumentFragment.parse(input, xml_strict)
              end
            end

            it "accepts kwargs" do
              frag = Nokogiri::XML::DocumentFragment.parse(input, options: xml_default)
              assert_equal("<a>foo</a>", frag.to_html)
              refute_empty(frag.errors)

              assert_raises(Nokogiri::SyntaxError) do
                Nokogiri::XML::DocumentFragment.parse(input, options: xml_strict)
              end
            end

            it "takes a config block" do
              default_config = nil
              Nokogiri::XML::DocumentFragment.parse(input) do |config|
                default_config = config
              end
              refute_predicate(default_config, :strict?)

              assert_raises(Nokogiri::SyntaxError) do
                Nokogiri::XML::DocumentFragment.parse(input, &:norecover)
              end
            end
          end

          describe "XML::DocumentFragment.new" do
            describe "without a context node" do
              it "has sane defaults" do
                frag = Nokogiri::XML::DocumentFragment.new(Nokogiri::XML::Document.new, input)
                assert_equal("<a>foo</a>", frag.to_html)
                refute_empty(frag.errors)
              end

              it "accepts options" do
                frag = Nokogiri::XML::DocumentFragment.new(Nokogiri::XML::Document.new, input, nil, xml_default)
                assert_equal("<a>foo</a>", frag.to_html)
                refute_empty(frag.errors)

                assert_raises(Nokogiri::SyntaxError) do
                  Nokogiri::XML::DocumentFragment.new(Nokogiri::XML::Document.new, input, nil, xml_strict)
                end
              end

              it "accepts options as kwargs" do
                frag = Nokogiri::XML::DocumentFragment.new(Nokogiri::XML::Document.new, input, options: xml_default)
                assert_equal("<a>foo</a>", frag.to_html)
                refute_empty(frag.errors)

                assert_raises(Nokogiri::SyntaxError) do
                  Nokogiri::XML::DocumentFragment.new(Nokogiri::XML::Document.new, input, options: xml_strict)
                end
              end

              it "takes a config block" do
                default_config = nil
                Nokogiri::XML::DocumentFragment.new(Nokogiri::XML::Document.new, input) do |config|
                  default_config = config
                end
                refute_predicate(default_config, :strict?)

                assert_raises(Nokogiri::SyntaxError) do
                  Nokogiri::XML::DocumentFragment.new(Nokogiri::XML::Document.new, input, &:norecover)
                end
              end
            end

            describe "with a context node" do
              let(:document) { Nokogiri::XML::Document.parse("<context></context>") }
              let(:context_node) { document.at_css("context") }

              it "has sane defaults" do
                frag = Nokogiri::XML::DocumentFragment.new(document, input, context_node)
                assert_equal("<a>foo</a>", frag.to_html)
                refute_empty(frag.errors)
              end

              it "accepts options" do
                frag = Nokogiri::XML::DocumentFragment.new(document, input, context_node, xml_default)
                assert_equal("<a>foo</a>", frag.to_html)
                refute_empty(frag.errors)

                assert_raises(Nokogiri::SyntaxError) do
                  Nokogiri::XML::DocumentFragment.new(document, input, context_node, xml_strict)
                end
              end

              it "takes a config block" do
                default_config = nil
                Nokogiri::XML::DocumentFragment.new(document, input, context_node) do |config|
                  default_config = config
                end
                refute_predicate(default_config, :strict?)

                assert_raises(Nokogiri::SyntaxError) do
                  Nokogiri::XML::DocumentFragment.new(document, input, context_node, &:norecover)
                end
              end
            end
          end
        end

        describe "subclassing" do
          let(:klass) do
            Class.new(Nokogiri::XML::DocumentFragment) do
              attr_accessor :initialized_with, :initialized_count

              def initialize(*args, **kwargs)
                super
                @initialized_with = [args, kwargs]
                @initialized_count ||= 0
                @initialized_count += 1
              end
            end
          end

          describe ".new" do
            it "returns an instance of the right class" do
              fragment = klass.new(xml, "<div>a</div>")
              assert_instance_of(klass, fragment)
            end

            it "calls #initialize exactly once" do
              fragment = klass.new(xml, "<div>a</div>")
              assert_equal(1, fragment.initialized_count)
            end

            it "passes args to #initialize" do
              fragment = klass.new(xml, "<div>a</div>", options: ParseOptions::DEFAULT_XML)
              assert_equal(
                [[xml, "<div>a</div>"], { options: ParseOptions::DEFAULT_XML }],
                fragment.initialized_with,
              )
            end
          end

          it "#dup returns the expected class" do
            doc = klass.new(xml, "<div>a</div>").dup
            assert_instance_of(klass, doc)
          end

          describe ".parse" do
            it "returns an instance of the right class" do
              fragment = klass.parse("<div>a</div>")
              assert_instance_of(klass, fragment)
            end

            it "calls #initialize exactly once" do
              fragment = klass.parse("<div>a</div>")
              assert_equal(1, fragment.initialized_count)
            end

            it "passes the fragment" do
              fragment = klass.parse("<div>a</div>")
              assert_equal(Nokogiri::XML::DocumentFragment.parse("<div>a</div>").to_s, fragment.to_s)
            end
          end
        end

        describe "#path" do
          it "should return '?'" do
            # see https://github.com/sparklemotion/nokogiri/issues/2250
            # this behavior is clearly undesirable, but is what libxml <= 2.9.10 returned, and so we
            # do this for now to preserve the behavior across libxml2 versions.
            xml = <<~EOF
              <root1></root1>
              <root2></root2>
            EOF

            frag = Nokogiri::XML::DocumentFragment.parse(xml)
            assert_equal "?", frag.path

            # # TODO: we should circle back and fix both the `#path` behavior and the `#xpath`
            # # behavior so we can round-trip and get the DocumentFragment back again.
            # assert_equal(frag, frag.at_xpath(doc.path)) # make sure we can round-trip
          end
        end
      end
    end
  end
end
