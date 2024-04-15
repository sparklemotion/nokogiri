# frozen_string_literal: true

require "helper"

module Nokogiri
  module XML
    class Node
      class TestAttributeMethods < Nokogiri::TestCase
        def setup
          super
          @xml = Nokogiri::XML(File.read(XML_FILE), XML_FILE)
        end

        def test_each
          attributes = @xml.xpath("//address")[1].map do |key, value|
            [key, value]
          end
          assert_equal([["domestic", "Yes"], ["street", "Yes"]], attributes)
        end

        def test_remove_attribute
          address = @xml.xpath("/staff/employee/address").first
          assert_equal("Yes", address["domestic"])
          attr = address.attributes["domestic"]

          returned_attr = address.remove_attribute("domestic")
          assert_nil(address["domestic"])
          assert_equal(attr, returned_attr)
        end

        def test_remove_attribute_when_not_found
          address = @xml.xpath("/staff/employee/address").first
          attr = address.remove_attribute("not-an-attribute")
          assert_nil(attr)
        end

        def test_attribute_setter_accepts_non_string
          address = @xml.xpath("/staff/employee/address").first
          assert_equal("Yes", address[:domestic])
          address[:domestic] = "Altered Yes"
          assert_equal("Altered Yes", address[:domestic])
        end

        def test_attribute_accessor_accepts_non_string
          address = @xml.xpath("/staff/employee/address").first
          assert_equal("Yes", address["domestic"])
          assert_equal("Yes", address[:domestic])
        end

        def test_empty_attribute_reading
          node = Nokogiri::XML('<foo empty="" whitespace="  "/>')

          assert_equal("", node.root["empty"])
          assert_equal("  ", node.root["whitespace"])
        end

        def test_delete
          address = @xml.xpath("/staff/employee/address").first
          assert_equal("Yes", address["domestic"])
          address.delete("domestic")
          assert_nil(address["domestic"])
        end

        def test_attributes
          assert(node = @xml.search("//address").first)
          assert_nil(node["asdfasdfasdf"])
          assert_equal("Yes", node["domestic"])

          assert(node = @xml.search("//address")[2])
          attr = node.attributes
          assert_equal(2, attr.size)
          assert_equal("Yes", attr["domestic"].value)
          assert_equal("Yes", attr["domestic"].to_s)
          assert_equal("No", attr["street"].value)
        end

        def test_values
          assert_equal(["Yes", "Yes"], @xml.xpath("//address")[1].values)
        end

        def test_value?
          refute(@xml.xpath("//address")[1].value?("no_such_value"))
          assert(@xml.xpath("//address")[1].value?("Yes"))
        end

        def test_keys
          assert_equal(["domestic", "street"], @xml.xpath("//address")[1].keys)
        end

        def test_attribute_with_symbol
          assert_equal("Yes", @xml.css("address").first[:domestic])
        end

        def test_non_existent_attribute_should_return_nil
          node = @xml.root.first_element_child
          assert_nil(node.attribute("type"))
        end

        #
        #  CSS classes, specifically
        #
        def test_classes
          xml = Nokogiri::XML(<<-eoxml)
        <div>
          <p class=" foo  bar foo ">test</p>
          <p class="">test</p>
        </div>
          eoxml
          div = xml.at_xpath("//div")
          p1, p2 = xml.xpath("//p")

          assert_empty(div.classes)
          assert_equal(["foo", "bar", "foo"], p1.classes)
          assert_empty(p2.classes)
        end

        def test_add_class
          xml = Nokogiri::XML(<<-eoxml)
        <div>
          <p class=" foo  bar foo ">test</p>
          <p class="">test</p>
        </div>
          eoxml
          div = xml.at_xpath("//div")
          p1, p2 = xml.xpath("//p")

          assert_same(div, div.add_class("main"))
          assert_equal("main", div["class"])

          assert_same(p1, p1.add_class("baz foo"))
          assert_equal("foo bar foo baz", p1["class"])

          assert_same(p2, p2.add_class("foo baz foo"))
          assert_equal("foo baz foo", p2["class"])
        end

        def test_append_class
          xml = Nokogiri::XML(<<-eoxml)
        <div>
          <p class=" foo  bar foo ">test</p>
          <p class="">test</p>
        </div>
          eoxml
          div = xml.at_xpath("//div")
          p1, p2 = xml.xpath("//p")

          assert_same(div, div.append_class("main"))
          assert_equal("main", div["class"])

          assert_same(p1, p1.append_class("baz foo"))
          assert_equal("foo bar foo baz foo", p1["class"])

          assert_same(p2, p2.append_class("foo baz foo"))
          assert_equal("foo baz foo", p2["class"])
        end

        def test_remove_class
          xml = Nokogiri::XML(<<-eoxml)
        <div>
          <p class=" foo  bar baz foo ">test</p>
          <p class=" foo  bar baz foo ">test</p>
          <p class="foo foo">test</p>
          <p class="">test</p>
        </div>
          eoxml
          div = xml.at_xpath("//div")
          p1, p2, p3, p4 = xml.xpath("//p")

          assert_same(div, div.remove_class("main"))
          assert_nil(div["class"])

          assert_same(p1, p1.remove_class("bar baz"))
          assert_equal("foo foo", p1["class"])

          assert_same(p2, p2.remove_class)
          assert_nil(p2["class"])

          assert_same(p3, p3.remove_class("foo"))
          assert_nil(p3["class"])

          assert_same(p4, p4.remove_class("foo"))
          assert_nil(p4["class"])
        end

        #
        #  keyword attributes, generally
        #
        describe "keyword attribute helpers" do
          let(:node) do
            Nokogiri::XML::DocumentFragment.parse(<<~EOM).at_css("div")
              <div blargh=" foo  bar baz bar foo  quux foo manx ">hello</div>
            EOM
          end

          describe "setup" do
            it { _(node.get_attribute("noob")).must_be_nil }
          end

          describe "#kwattr_values" do
            it "returns an array of space-delimited values" do
              _(node.kwattr_values("blargh")).must_equal(["foo", "bar", "baz", "bar", "foo", "quux", "foo", "manx"])
            end

            describe "when no attribute exists" do
              it "returns an empty array" do
                _(node.kwattr_values("noob")).must_equal([])
              end
            end

            describe "when an empty attribute exists" do
              it "returns an empty array" do
                node.set_attribute("noob", "")
                _(node.kwattr_values("noob")).must_equal([])

                node.set_attribute("noob", "  ")
                _(node.kwattr_values("noob")).must_equal([])
              end
            end
          end

          describe "kwattr_add" do
            it "returns the node for chaining" do
              _(node.kwattr_add("noob", "asdf")).must_be_same_as(node)
            end

            it "creates a new attribute when necessary" do
              _(node.kwattr_add("noob", "asdf").get_attribute("noob")).wont_be_nil
            end

            it "adds a new bare keyword string" do
              _(node.kwattr_add("blargh", "jimmy").kwattr_values("blargh"))
                .must_equal(["foo", "bar", "baz", "bar", "foo", "quux", "foo", "manx", "jimmy"])
            end

            it "does not add a repeated bare keyword string" do
              _(node.kwattr_add("blargh", "foo").kwattr_values("blargh"))
                .must_equal(["foo", "bar", "baz", "bar", "foo", "quux", "foo", "manx"])
            end

            describe "given a string of keywords" do
              it "adds new keywords and ignores existing keywords" do
                _(node.kwattr_add("blargh", "foo jimmy\tjohnny").kwattr_values("blargh"))
                  .must_equal(["foo", "bar", "baz", "bar", "foo", "quux", "foo", "manx", "jimmy", "johnny"])
              end
            end

            describe "given an array of keywords" do
              it "adds new keywords and ignores existing keywords" do
                _(node.kwattr_add("blargh", ["foo", "jimmy"]).kwattr_values("blargh"))
                  .must_equal(["foo", "bar", "baz", "bar", "foo", "quux", "foo", "manx", "jimmy"])
              end
            end
          end

          describe "kwattr_append" do
            it "returns the node for chaining" do
              _(node.kwattr_append("noob", "asdf")).must_be_same_as(node)
            end

            it "creates a new attribute when necessary" do
              _(node.kwattr_append("noob", "asdf").get_attribute("noob")).wont_be_nil
            end

            it "adds a new bare keyword string" do
              _(node.kwattr_append("blargh", "jimmy").kwattr_values("blargh"))
                .must_equal(["foo", "bar", "baz", "bar", "foo", "quux", "foo", "manx", "jimmy"])
            end

            it "adds a repeated bare keyword string" do
              _(node.kwattr_append("blargh", "foo").kwattr_values("blargh"))
                .must_equal(["foo", "bar", "baz", "bar", "foo", "quux", "foo", "manx", "foo"])
            end

            describe "given a string of keywords" do
              it "adds new keywords and existing keywords" do
                _(node.kwattr_append("blargh", "foo jimmy\tjohnny").kwattr_values("blargh"))
                  .must_equal(["foo", "bar", "baz", "bar", "foo", "quux", "foo", "manx", "foo", "jimmy", "johnny"])
              end
            end

            describe "given an array of keywords" do
              it "adds new keywords and existing keywords" do
                _(node.kwattr_append("blargh", ["foo", "jimmy"]).kwattr_values("blargh"))
                  .must_equal(["foo", "bar", "baz", "bar", "foo", "quux", "foo", "manx", "foo", "jimmy"])
              end
            end
          end

          describe "kwattr_remove" do
            it "returns the node for chaining" do
              _(node.kwattr_remove("noob", "asdf")).must_be_same_as(node)
            end

            it "gracefully handles a non-existent attribute" do
              _(node.kwattr_remove("noob", "asdf").get_attribute("noob")).must_be_nil
            end

            it "removes an existing bare keyword string" do
              _(node.kwattr_remove("blargh", "foo").kwattr_values("blargh"))
                .must_equal(["bar", "baz", "bar", "quux", "manx"])
            end

            it "gracefully ignores a non-existent bare keyword string" do
              _(node.kwattr_remove("blargh", "jimmy").kwattr_values("blargh"))
                .must_equal(["foo", "bar", "baz", "bar", "foo", "quux", "foo", "manx"])
            end

            describe "given a string of keywords" do
              it "removes existing keywords and ignores other keywords" do
                _(node.kwattr_remove("blargh", "foo jimmy\tjohnny").kwattr_values("blargh"))
                  .must_equal(["bar", "baz", "bar", "quux", "manx"])
              end
            end

            describe "given an array of keywords" do
              it "adds new keywords and existing keywords" do
                _(node.kwattr_remove("blargh", ["foo", "jimmy"]).kwattr_values("blargh"))
                  .must_equal(["bar", "baz", "bar", "quux", "manx"])
              end
            end

            it "removes the attribute when no values are left" do
              _(node.kwattr_remove("blargh", ["foo", "bar", "baz", "bar", "foo", "quux", "foo", "manx"]).get_attribute("blargh")).must_be_nil
            end
          end
        end
      end
    end
  end
end
