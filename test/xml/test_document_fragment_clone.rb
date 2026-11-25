# frozen_string_literal: true

require "helper"

class TestDocumentFragmentClone < Nokogiri::TestCase
  formats = [Nokogiri::XML, Nokogiri::HTML4]
  formats << Nokogiri::HTML5 if Nokogiri.uses_gumbo?

  formats.each do |format|
    describe "#{format}::DocumentFragment#clone" do
      let(:document) { format::Document.parse("<div>original document</div>") }
      let(:fragment) { document.fragment("<div><p>hello</p></div>tail<!--comment-->") }

      before do
        skip_unless_libxml2("fragment copies use independent documents on CRuby")
      end

      it "copies the fragment and its document" do
        copy = fragment.clone

        refute_same(document, copy.document)
        assert_instance_of(document.class, copy.document)
        assert_instance_of(fragment.class, copy)
        assert_equal(document.to_xml, copy.document.to_xml)
        assert_equal(fragment.to_xml, copy.to_xml)
        copy.traverse { |node| assert_same(copy.document, node.document) }

        copy.at_css("p").content = "changed"
        assert_equal("hello", fragment.at_css("p").content)
        assert_same(document, fragment.document)
        assert_same(document, fragment.at_css("p").document)
      end

      it "supports shallow copies into independent documents" do
        copy = fragment.clone(0)

        assert_empty(copy.children)
        refute_same(document, copy.document)
        refute_empty(fragment.children)
      end

      it "uses an explicitly supplied document" do
        target = format::Document.new

        [0, 1].each do |level|
          copy = fragment.clone(level, target)

          assert_same(target, copy.document)
          copy.traverse { |node| assert_same(target, node.document) }
          assert_equal(level.zero? ? "" : fragment.to_xml, copy.to_xml)
          assert_same(document, fragment.document)
        end
      end

      it "retains singleton methods and frozen state" do
        fragment.define_singleton_method(:marker) { :copied }
        fragment.freeze

        copy = fragment.clone

        assert_equal(:copied, copy.marker)
        refute_same(fragment.singleton_class, copy.singleton_class)
        assert_predicate(copy, :frozen?)
        assert_equal(fragment.to_xml, copy.to_xml)
      end

      it "can clone a clone" do
        copy = fragment.clone.clone

        assert_instance_of(fragment.class, copy)
        assert_equal(fragment.to_xml, copy.to_xml)
        copy.traverse { |node| assert_same(copy.document, node.document) }
      end
    end
  end
end
