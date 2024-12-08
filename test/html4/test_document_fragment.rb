# -*- coding: utf-8 -*-
# frozen_string_literal: true

require "helper"

module Nokogiri
  module HTML
    class TestDocumentFragment < Nokogiri::TestCase
      describe Nokogiri::HTML4::DocumentFragment do
        let(:html) { Nokogiri::HTML4.parse(File.read(HTML_FILE), HTML_FILE) }

        def test_ascii_8bit_encoding
          s = +"hello"
          s.force_encoding(::Encoding::ASCII_8BIT)
          assert_equal("hello", Nokogiri::HTML4::DocumentFragment.parse(s).to_html)
        end

        def test_unlink_empty_document
          frag = Nokogiri::HTML4::DocumentFragment.parse("").unlink # must_not_raise
          assert_nil(frag.parent)
        end

        def test_colons_are_not_removed
          doc = Nokogiri::HTML4::DocumentFragment.parse("<span>3:30pm</span>")
          assert_match(/3:30/, doc.to_s)
        end

        def test_parse_in_context
          assert_equal("<br>", html.root.parse("<br />").to_s)
        end

        def test_inner_html=
          fragment = Nokogiri::HTML4.fragment("<hr />")

          fragment.inner_html = "hello"
          assert_equal("hello", fragment.inner_html)
        end

        def test_ancestors_search
          html = <<~EOF
            <div>
              <ul>
                <li>foo</li>
              </ul>
            </div>
          EOF
          fragment = Nokogiri::HTML4.fragment(html)
          li = fragment.at("li")
          assert(li.matches?("li"))
        end

        def test_new
          assert(Nokogiri::HTML4::DocumentFragment.new(html))
        end

        def test_body_fragment_should_contain_body
          fragment = Nokogiri::HTML4::DocumentFragment.parse("  <body><div>foo</div></body>")
          assert_match(/^<body>/, fragment.to_s)
        end

        def test_nonbody_fragment_should_not_contain_body
          fragment = Nokogiri::HTML4::DocumentFragment.parse("<div>foo</div>")
          assert_match(/^<div>/, fragment.to_s)
        end

        def test_fragment_should_have_document
          fragment = Nokogiri::HTML4::DocumentFragment.new(html)
          assert_equal(html, fragment.document)
        end

        def test_empty_fragment_should_be_searchable_by_css
          fragment = Nokogiri::HTML4.fragment("")
          assert_equal(0, fragment.css("a").size)
        end

        def test_empty_fragment_should_be_searchable
          fragment = Nokogiri::HTML4.fragment("")
          assert_equal(0, fragment.search("//a").size)
        end

        def test_name
          fragment = Nokogiri::HTML4::DocumentFragment.new(html)
          assert_equal("#document-fragment", fragment.name)
        end

        def test_static_method
          fragment = Nokogiri::HTML4::DocumentFragment.parse("<div>a</div>")
          assert_instance_of(Nokogiri::HTML4::DocumentFragment, fragment)
        end

        def test_html_fragment
          fragment = Nokogiri::HTML4.fragment("<div>a</div>")
          assert_equal("<div>a</div>", fragment.to_s)
        end

        def test_html_fragment_has_outer_text
          doc = "a<div>b</div>c"
          fragment = Nokogiri::HTML4::Document.new.fragment(doc)
          assert_equal("a<div>b</div>c", fragment.to_s)
        end

        def test_html_fragment_case_insensitivity
          doc = "<Div>b</Div>"
          fragment = Nokogiri::HTML4::Document.new.fragment(doc)
          assert_equal("<div>b</div>", fragment.to_s)
        end

        def test_html_fragment_with_leading_whitespace
          doc = "     <div>b</div>  "
          fragment = Nokogiri::HTML4::Document.new.fragment(doc)
          assert_match(%r%     <div>b</div> *%, fragment.to_s)
        end

        def test_html_fragment_with_leading_whitespace_and_newline
          doc = "     \n<div>b</div>  "
          fragment = Nokogiri::HTML4::Document.new.fragment(doc)
          assert_match(%r%     \n<div>b</div> *%, fragment.to_s)
        end

        def test_html_fragment_with_input_and_intermediate_whitespace
          doc = "<label>Label</label><input type=\"text\"> <span>span</span>"
          fragment = Nokogiri::HTML4::Document.new.fragment(doc)
          assert_equal("<label>Label</label><input type=\"text\"> <span>span</span>", fragment.to_s)
        end

        def test_html_fragment_with_leading_text_and_newline
          fragment = Nokogiri::HTML4::Document.new.fragment("First line\nSecond line<br>Broken line")
          assert_equal("First line\nSecond line<br>Broken line", fragment.to_s)
        end

        def test_html_fragment_with_leading_whitespace_and_text_and_newline
          fragment = Nokogiri::HTML4::Document.new.fragment("  First line\nSecond line<br>Broken line")
          assert_equal("  First line\nSecond line<br>Broken line", fragment.to_s)
        end

        def test_html_fragment_with_leading_entity
          failed = "&quot;test<br/>test&quot;"
          fragment = Nokogiri::HTML4::DocumentFragment.parse(failed)
          assert_equal('"test<br>test"', fragment.to_html)
        end

        def test_to_s
          doc = "<span>foo<br></span><span>bar</span>"
          fragment = Nokogiri::HTML4::Document.new.fragment(doc)
          assert_equal("<span>foo<br></span><span>bar</span>", fragment.to_s)
        end

        def test_to_html
          doc = "<span>foo<br></span><span>bar</span>"
          fragment = Nokogiri::HTML4::Document.new.fragment(doc)
          assert_equal("<span>foo<br></span><span>bar</span>", fragment.to_html)
        end

        def test_to_xhtml
          doc = "<span>foo<br></span><span>bar</span><p></p>"
          fragment = Nokogiri::HTML4::Document.new.fragment(doc)
          assert_equal("<span>foo<br /></span><span>bar</span><p></p>", fragment.to_xhtml)
        end

        def test_to_xml
          doc = "<span>foo<br></span><span>bar</span>"
          fragment = Nokogiri::HTML4::Document.new.fragment(doc)
          assert_equal("<span>foo<br/></span><span>bar</span>", fragment.to_xml)
        end

        def test_fragment_script_tag_with_cdata
          doc = Nokogiri::HTML4::Document.new
          fragment = doc.fragment("<script>var foo = 'bar';</script>")
          assert_equal(
            "<script>var foo = 'bar';</script>",
            fragment.to_s,
          )
        end

        def test_fragment_with_comment
          doc = Nokogiri::HTML4::Document.new
          fragment = doc.fragment("<p>hello<!-- your ad here --></p>")
          assert_equal(
            "<p>hello<!-- your ad here --></p>",
            fragment.to_s,
          )
        end

        def test_element_children_counts
          doc = Nokogiri::HTML4::DocumentFragment.parse("   <div>  </div>\n   ")
          assert_equal(1, doc.element_children.count)
        end

        def test_malformed_fragment_is_corrected
          fragment = Nokogiri::HTML4::DocumentFragment.parse("<div </div>")

          if Nokogiri.uses_libxml?(">= 2.14.0")
            assert_pattern do
              fragment => [
                { name: "div", attributes: [
                    { name: "<", value: ""},
                    { name: "div", value: ""},
                  ]}
              ]
            end
          else
            assert_equal("<div></div>", fragment.to_s)
          end
        end

        def test_malformed_html5_fragment_serializes_like_gumbo
          skip_unless_libxml2(">= 2.14.0")

          fragment = Nokogiri::HTML4::DocumentFragment.parse("<div </div>")

          pending "libxml2 does not serialize HTML5 like gumbo (yet)" do
            assert_equal('<div <="" div=""></div>', fragment.to_s)
          end
        end

        def test_unclosed_script_tag
          # see GH#315
          fragment = Nokogiri::HTML4::DocumentFragment.parse("foo <script>bar")
          assert_equal("foo <script>bar</script>", fragment.to_html)
        end

        def test_error_propagation_on_fragment_parse
          frag = Nokogiri::HTML4::DocumentFragment.parse("<hello>oh, hello there</goodbye>")
          refute_empty(frag.errors)
        end

        def test_error_propagation_on_fragment_parse_in_node_context
          doc = Nokogiri::HTML4::Document.parse("<html><body><div></div></body></html>")
          context_node = doc.at_css("div")
          frag = Nokogiri::HTML4::DocumentFragment.new(doc, "<hello>oh, hello there</goodbye>", context_node)
          refute_empty(frag.errors)
        end

        def test_error_propagation_on_fragment_parse_in_node_context_should_not_include_preexisting_errors
          doc = Nokogiri::HTML4::Document.parse("<html><body><div></jimmy></body></html>")
          refute_empty(doc.errors)
          doc_errors = doc.errors.map(&:to_s)

          context_node = doc.at_css("div")
          frag = Nokogiri::HTML4::DocumentFragment.new(doc, "<hello>oh, hello there.</goodbye>", context_node)
          refute_empty(frag.errors)

          assert(
            frag.errors.none? do |err|
              doc_errors.include?(err.to_s)
            end,
            "errors should not include pre-existing document errors",
          )
        end

        def test_capturing_nonparse_errors_during_fragment_clone
          # see https://github.com/sparklemotion/nokogiri/issues/1196 for background
          original = Nokogiri::HTML4.fragment("<div id='unique'></div><div id='unique'></div>")
          original_errors = original.errors.dup

          copy = original.dup
          assert_equal(original_errors, copy.errors)
        end

        def test_capturing_nonparse_errors_during_node_copy_between_fragments
          # Errors should be emitted while parsing only, and should not change when moving nodes.
          frag1 = Nokogiri::HTML4.fragment("<div id='unique'>one</foo1>")
          frag2 = Nokogiri::HTML4.fragment("<div id='unique'>two</foo2>")
          node1 = frag1.at_css("#unique")
          node2 = frag2.at_css("#unique")
          original_errors1 = frag1.errors.dup
          original_errors2 = frag2.errors.dup

          refute_empty(original_errors1)
          refute_empty(original_errors2)

          node1.add_child(node2)

          assert_equal(original_errors1, frag1.errors)
          assert_equal(original_errors2, frag2.errors)
        end

        def test_dup_should_create_an_html_document_fragment
          # https://github.com/sparklemotion/nokogiri/issues/1846
          original = Nokogiri::HTML4::DocumentFragment.parse("<div><p>hello</p></div>")
          duplicate = original.dup
          assert_instance_of(Nokogiri::HTML4::DocumentFragment, duplicate)
        end

        def test_parse_with_io
          fragment = Nokogiri::HTML4::DocumentFragment.parse(StringIO.new("<div>hello</div>"), "UTF-8")
          assert_instance_of(HTML4::DocumentFragment, fragment)
          assert_equal("<div>hello</div>", fragment.to_s)

          fragment = Nokogiri::HTML4::DocumentFragment.parse(StringIO.new("<div>hello</div>"))
          assert_equal("<div>hello</div>", fragment.to_s)
        end

        describe "encoding" do
          describe "#fragment" do
            it "parses an encoded string" do
              input = "<div>こんにちは！</div>".encode("EUC-JP")
              fragment = Nokogiri::HTML4.fragment(input)
              assert_equal("EUC-JP", fragment.document.encoding)
              assert_equal("こんにちは！", fragment.content)
            end

            it "returns a string matching the passed encoding" do
              input = "<div>hello world</div>"

              fragment = Nokogiri::HTML4.fragment(input, "ISO-8859-1")
              assert_equal("ISO-8859-1", fragment.document.encoding)
              assert_equal("hello world", fragment.content)
            end
          end

          describe "#parse" do
            it "parses an encoded string" do
              input = "<div>こんにちは！</div>".encode("EUC-JP")

              fragment = Nokogiri::HTML4::DocumentFragment.parse(input)
              assert_equal("EUC-JP", fragment.document.encoding)
              assert_equal("こんにちは！", fragment.content)
            end

            it "returns a string matching the passed encoding" do
              input = "<div>hello world</div>"

              fragment = Nokogiri::HTML4::DocumentFragment.parse(input, "ISO-8859-1")
              assert_equal("ISO-8859-1", fragment.document.encoding)
              assert_equal("hello world", fragment.content)
            end

            it "returns a string matching an encoding passed with kwargs" do
              input = "<div>hello world</div>"

              fragment = Nokogiri::HTML4::DocumentFragment.parse(input, encoding: "ISO-8859-1")
              assert_equal("ISO-8859-1", fragment.document.encoding)
              assert_equal("hello world", fragment.content)
            end

            it "respects encoding for empty strings" do
              fragment = Nokogiri::HTML::DocumentFragment.parse("", "UTF-8")
              assert_equal "UTF-8", fragment.to_html.encoding.to_s

              fragment = Nokogiri::HTML::DocumentFragment.parse("", "US-ASCII")
              assert_equal "US-ASCII", fragment.to_html.encoding.to_s

              fragment = Nokogiri::HTML::DocumentFragment.parse("", "ISO-8859-1")
              assert_equal "ISO-8859-1", fragment.to_html.encoding.to_s
            end
          end

          describe "#to_html" do
            it "serializes empty strings with the passed encoding" do
              fragment = Nokogiri::HTML::DocumentFragment.parse("", "UTF-8")
              assert_equal "ISO-8859-1", fragment.to_html(encoding: "ISO-8859-1").encoding.to_s
              assert_equal "US-ASCII", fragment.to_html(encoding: "US-ASCII").encoding.to_s
            end
          end
        end

        describe "parse options" do
          let(:html4_default) do
            Nokogiri::XML::ParseOptions.new(Nokogiri::XML::ParseOptions::DEFAULT_HTML)
          end

          let(:html4_strict) do
            Nokogiri::XML::ParseOptions.new(Nokogiri::XML::ParseOptions::DEFAULT_HTML).norecover
          end

          let(:html4_huge) do
            Nokogiri::XML::ParseOptions.new(Nokogiri::XML::ParseOptions::DEFAULT_HTML).huge
          end

          let(:input) { "<div>foo</div>" }

          it "sets the test up correctly" do
            refute_predicate(html4_default, :strict?)
            refute_predicate(html4_default, :huge?)
            assert_predicate(html4_strict, :strict?)
            assert_predicate(html4_huge, :huge?)
          end

          describe "HTML4.fragment" do
            it "has reasonable defaults" do
              frag = Nokogiri::HTML4.fragment(input)

              assert_equal("<div>foo</div>", frag.to_html)
              assert_equal(html4_default, frag.parse_options)
            end

            it "accepts options" do
              frag = Nokogiri::HTML4.fragment(input, nil, html4_huge)

              assert_equal("<div>foo</div>", frag.to_html)
              assert_equal(html4_huge, frag.parse_options)
            end

            it "accepts options as kwargs" do
              frag = Nokogiri::HTML4::DocumentFragment.parse(input, options: html4_huge)

              assert_equal("<div>foo</div>", frag.to_html)
              assert_equal(html4_huge, frag.parse_options)
            end

            it "takes a config block" do
              default_config = nil
              frag = Nokogiri::HTML4.fragment(input) do |config|
                default_config = config.dup
                config.huge
              end

              assert_equal(html4_default, default_config)
              refute_predicate(default_config, :huge?)
              assert_predicate(frag.parse_options, :huge?)
            end
          end

          describe "HTML4::DocumentFragment.parse" do
            it "has reasonable defaults" do
              frag = Nokogiri::HTML4::DocumentFragment.parse(input)

              assert_equal("<div>foo</div>", frag.to_html)
              assert_equal(html4_default, frag.parse_options)
            end

            it "accepts options" do
              frag = Nokogiri::HTML4::DocumentFragment.parse(input, nil, html4_huge)

              assert_equal("<div>foo</div>", frag.to_html)
              assert_equal(html4_huge, frag.parse_options)
            end

            it "takes a config block" do
              default_config = nil
              frag = Nokogiri::HTML4::DocumentFragment.parse(input) do |config|
                default_config = config.dup
                config.huge
              end

              assert_equal(html4_default, default_config)
              refute_predicate(default_config, :huge?)
              assert_predicate(frag.parse_options, :huge?)
            end
          end

          describe "HTML4::DocumentFragment.new" do
            describe "without a context node" do
              it "has reasonable defaults" do
                frag = Nokogiri::HTML4::DocumentFragment.new(Nokogiri::HTML4::Document.new, input)

                assert_equal("<div>foo</div>", frag.to_html)
                assert_equal(html4_default, frag.parse_options)
              end

              it "accepts options" do
                frag = Nokogiri::HTML4::DocumentFragment.new(Nokogiri::HTML4::Document.new, input, nil, html4_huge)

                assert_equal("<div>foo</div>", frag.to_html)
                assert_equal(html4_huge, frag.parse_options)
              end

              it "takes a config block" do
                default_config = nil
                frag = Nokogiri::HTML4::DocumentFragment.new(Nokogiri::HTML4::Document.new, input) do |config|
                  default_config = config.dup
                  config.huge
                end

                assert_equal(html4_default, default_config)
                refute_predicate(default_config, :huge?)
                assert_predicate(frag.parse_options, :huge?)
              end
            end

            describe "with a context node" do
              let(:document) { Nokogiri::HTML4::Document.parse("<context></context>") }
              let(:context_node) { document.at_css("context") }
              let(:input) { "<div>foo</div" }

              it "has sane defaults" do
                frag = Nokogiri::HTML4::DocumentFragment.new(document, input, context_node)
                assert_equal("<div>foo</div>", frag.to_html)
                refute_empty(frag.errors)
              end

              it "accepts options" do
                frag = Nokogiri::HTML4::DocumentFragment.new(document, input, context_node, html4_default)
                assert_equal("<div>foo</div>", frag.to_html)
                refute_empty(frag.errors)

                assert_raises(Nokogiri::SyntaxError) do
                  Nokogiri::HTML4::DocumentFragment.new(document, input, context_node, html4_strict)
                end
              end

              it "takes a config block" do
                default_config = nil
                Nokogiri::HTML4::DocumentFragment.new(document, input, context_node) do |config|
                  default_config = config
                end
                refute_predicate(default_config, :strict?)

                assert_raises(Nokogiri::SyntaxError) do
                  Nokogiri::HTML4::DocumentFragment.new(document, input, context_node, &:norecover)
                end
              end
            end
          end
        end

        describe "subclassing" do
          let(:klass) do
            Class.new(Nokogiri::HTML4::DocumentFragment) do
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
              fragment = klass.new(html, "<div>a</div>")
              assert_instance_of(klass, fragment)
            end

            it "calls #initialize exactly once" do
              fragment = klass.new(html, "<div>a</div>")
              assert_equal(1, fragment.initialized_count)
            end

            it "passes args to #initialize" do
              fragment = klass.new(html, "<div>a</div>", options: 1)
              assert_equal(
                [[html, "<div>a</div>"], { options: 1 }],
                fragment.initialized_with,
              )
            end
          end

          it "#dup returns the expected class" do
            doc = klass.new(html, "<div>a</div>").dup
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
              assert_equal(Nokogiri::HTML4::DocumentFragment.parse("<div>a</div>").to_s, fragment.to_s)
            end
          end
        end
      end
    end
  end
end
