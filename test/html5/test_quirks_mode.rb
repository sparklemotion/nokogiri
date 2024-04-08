# encoding: utf-8
# frozen_string_literal: true

require "helper"

describe Nokogiri::HTML5 do
  describe "Document#quirks_mode" do
    let(:document) { Nokogiri::HTML5::Document.parse(html) }

    describe "without parsing anything" do
      it "returns nil" do
        assert_nil(Nokogiri::HTML5::Document.new.quirks_mode)
      end
    end

    describe "on a document with a doctype" do
      let(:html) { "<!DOCTYPE html><p>hello</p>" }

      it "returns NO_QUIRKS" do
        assert_equal(Nokogiri::HTML5::QuirksMode::NO_QUIRKS, document.quirks_mode)
      end
    end

    describe "on a document without a doctype" do
      let(:html) { "<html><p>hello</p>" }

      it "returns QUIRKS" do
        assert_equal(Nokogiri::HTML5::QuirksMode::QUIRKS, document.quirks_mode)
      end
    end
  end

  describe "DocumentFragment#quirks_mode" do
    let(:input)            { "<p><table>" }
    let(:no_quirks_output) { "<p></p><table></table>" }
    let(:quirks_output)    { "<p><table></table></p>" }

    describe "without parsing anything" do
      let(:fragment) { Nokogiri::HTML5::DocumentFragment.new(Nokogiri::HTML5::Document.new) }

      it "returns nil" do
        assert_nil(fragment.quirks_mode)
      end
    end

    describe "in context" do
      describe "document did not invoke the parser" do
        let(:document) { Nokogiri::HTML5::Document.new }

        it "parses the fragment in no-quirks mode" do
          context_node = document.create_element("div")
          fragment = context_node.fragment(input)

          assert_equal(Nokogiri::HTML5::QuirksMode::NO_QUIRKS, fragment.quirks_mode)
          assert_equal(no_quirks_output, fragment.to_html)
        end
      end

      describe "document has a doctype" do
        let(:document) { Nokogiri::HTML5::Document.parse("<!DOCTYPE html><div>") }

        it "parses the fragment in no-quirks mode" do
          context_node = document.at_css("div")
          fragment = context_node.fragment(input)

          assert_equal(Nokogiri::HTML5::QuirksMode::NO_QUIRKS, fragment.quirks_mode)
          assert_equal(no_quirks_output, fragment.to_html)
        end

        describe "context node is just a tag name and not a real node" do
          it "parses the fragment in no-quirks mode" do
            fragment = Nokogiri::HTML5::DocumentFragment.new(document, input, "body")

            assert_equal(Nokogiri::HTML5::QuirksMode::NO_QUIRKS, fragment.quirks_mode)
            assert_equal(no_quirks_output, fragment.to_html)
          end
        end
      end

      describe "document does not have a doctype" do
        let(:document) { Nokogiri::HTML5::Document.parse("<div>") }

        it "parses the fragment in quirks mode" do
          context_node = document.at_css("div")
          fragment = context_node.fragment(input)

          assert_equal(Nokogiri::HTML5::QuirksMode::QUIRKS, fragment.quirks_mode)
          assert_equal(quirks_output, fragment.to_html)
        end

        describe "context node is just a tag name and not a real node" do
          it "parses the fragment in no-quirks mode" do
            fragment = Nokogiri::HTML5::DocumentFragment.new(document, input, "body")

            assert_equal(Nokogiri::HTML5::QuirksMode::NO_QUIRKS, fragment.quirks_mode)
            assert_equal(no_quirks_output, fragment.to_html)
          end
        end
      end
    end

    describe "no context" do
      describe "document did not invoke the parser" do
        let(:document) { Nokogiri::HTML5::Document.new }

        it "parses the fragment in no-quirks mode" do
          fragment = document.fragment(input)

          assert_equal(Nokogiri::HTML5::QuirksMode::NO_QUIRKS, fragment.quirks_mode)
          assert_equal(no_quirks_output, fragment.to_html)
        end
      end

      describe "document has a doctype" do
        let(:document) { Nokogiri::HTML5::Document.parse("<!DOCTYPE html><div>") }

        it "parses the fragment in no-quirks mode" do
          fragment = document.fragment(input)

          assert_equal(Nokogiri::HTML5::QuirksMode::NO_QUIRKS, fragment.quirks_mode)
          assert_equal(no_quirks_output, fragment.to_html)
        end
      end

      describe "document does not have a doctype" do
        let(:document) { Nokogiri::HTML5::Document.parse("<div>") }

        it "parses the fragment in no-quirks mode" do
          fragment = document.fragment(input)

          assert_equal(Nokogiri::HTML5::QuirksMode::NO_QUIRKS, fragment.quirks_mode)
          assert_equal(no_quirks_output, fragment.to_html)
        end
      end
    end
  end
end if Nokogiri.uses_gumbo?
