# frozen_string_literal: true

require "helper"

module Nokogiri
  module HTML
    class TestBuilder < Nokogiri::TestCase
      def test_top_level_function_builds
        foo = nil
        Nokogiri() { |xml| foo = xml }
        assert_instance_of(Nokogiri::HTML4::Builder, foo)
      end

      def test_builder_returns_html4_document
        html_doc = Nokogiri::HTML4::Builder.new do
          div("hello")
        end

        assert_kind_of(Nokogiri::HTML4::Document, html_doc.doc)
      end

      def test_builder_with_explicit_tags
        html_doc = Nokogiri::HTML4::Builder.new do
          div.slide(class: "another_class") do
            node = Nokogiri::XML::Node.new("id", doc)
            node.content = "hello"
            insert(node)
          end
        end.doc
        assert_equal(1, html_doc.css("div.slide > id").length)
        assert_equal("hello", html_doc.at("div.slide > id").content)
      end

      def test_hash_as_attributes_for_attribute_method
        html = Nokogiri::HTML4::Builder.new do ||
          div.slide(class: "another_class") do
            span("Slide 1")
          end
        end.to_html
        assert_match('class="slide another_class"', html)
      end

      def test_hash_as_attributes
        builder = Nokogiri::HTML4::Builder.new do
          div(id: "awesome") do
            h1("america")
          end
        end
        assert_equal(
          '<div id="awesome"><h1>america</h1></div>',
          builder.doc.root.to_html.delete("\n").gsub(/>\s*</, "><"),
        )
      end

      def test_href_with_attributes
        uri = "http://tenderlovemaking.com/"
        built = Nokogiri::XML::Builder.new do
          div do
            a("King Khan & The Shrines", href: uri)
          end
        end
        assert_equal(
          "http://tenderlovemaking.com/",
          built.doc.at("a")[:href],
        )
      end

      def test_tag_nesting
        builder = Nokogiri::HTML4::Builder.new do
          body do
            span.left("")
            span.middle do
              div.icon("")
            end
            span.right("")
          end
        end
        assert(node = builder.doc.css("span.right").first)
        assert_equal("middle", node.previous_sibling["class"])
      end

      def test_has_ampersand
        builder = Nokogiri::HTML4::Builder.new do
          div.rad.thing! do
            text("<awe&some>")
            b("hello & world")
          end
        end
        assert_equal(
          '<div class="rad" id="thing">&lt;awe&amp;some&gt;<b>hello &amp; world</b></div>',
          builder.doc.root.to_html.delete("\n"),
        )
      end

      def test_multi_tags
        builder = Nokogiri::HTML4::Builder.new do
          div.rad.thing! do
            text("<awesome>")
            b("hello")
          end
        end
        assert_equal(
          '<div class="rad" id="thing">&lt;awesome&gt;<b>hello</b></div>',
          builder.doc.root.to_html.delete("\n"),
        )
      end

      def test_attributes_plus_block
        builder = Nokogiri::HTML4::Builder.new do
          div.rad.thing! do
            text("<awesome>")
          end
        end
        assert_equal(
          '<div class="rad" id="thing">&lt;awesome&gt;</div>',
          builder.doc.root.to_html.chomp,
        )
      end

      def test_builder_adds_attributes
        builder = Nokogiri::HTML4::Builder.new do
          div.rad.thing!("tender div")
        end
        assert_equal(
          '<div class="rad" id="thing">tender div</div>',
          builder.doc.root.to_html.chomp,
        )
      end

      def test_bold_tag
        builder = Nokogiri::HTML4::Builder.new do
          b("bold tag")
        end
        assert_equal("<b>bold tag</b>", builder.doc.root.to_html.chomp)
      end

      def test_html_then_body_tag
        builder = Nokogiri::HTML4::Builder.new do
          html do
            body do
              b("bold tag")
            end
          end
        end
        assert_equal(
          "<html><body><b>bold tag</b></body></html>",
          builder.doc.root.to_html.chomp.gsub(/>\s*</, "><"),
        )
      end

      def test_instance_eval_with_delegation_to_block_context
        class << self
          def foo
            "foo!"
          end
        end

        builder = Nokogiri::HTML4::Builder.new { text(foo) }
        assert_includes(builder.to_html, "foo!")
      end

      def test_builder_with_param
        doc = Nokogiri::HTML4::Builder.new do |html|
          html.body do
            html.p("hello world")
          end
        end.doc

        assert(node = doc.xpath("//body/p").first)
        assert_equal("hello world", node.content)
      end

      def test_builder_with_id
        text = "hello world"
        doc = Nokogiri::HTML4::Builder.new do |html|
          html.body do
            html.id_(text)
          end
        end.doc

        assert(node = doc.xpath("//body/id").first)
        assert_equal(text, node.content)
      end
    end
  end
end
