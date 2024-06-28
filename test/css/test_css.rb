# frozen_string_literal: true

require "helper"

describe Nokogiri::CSS do
  describe ".xpath_for" do
    it "accepts just a selector" do
      assert_equal(["//foo"], Nokogiri::CSS.xpath_for("foo"))
    end

    it "accepts a CSS::XPathVisitor" do
      mock_visitor = Minitest::Mock.new
      mock_visitor.expect(:accept, "injected-value", [Nokogiri::CSS::Node])
      mock_visitor.expect(:prefix, "//")

      result = Nokogiri::CSS.xpath_for("foo", visitor: mock_visitor, cache: false)

      mock_visitor.verify
      assert_equal(["//injected-value"], result)
    end

    it "accepts an options hash" do
      assert_output(nil, /Passing options as an explicit hash is deprecated/) do
        assert_equal(
          ["./foo"],
          Nokogiri::CSS.xpath_for("foo", { prefix: "./" }),
        )
      end

      assert_output(nil, /Passing options as an explicit hash is deprecated/) do
        assert_equal(
          ["./foo"],
          Nokogiri::CSS.xpath_for("foo", { visitor: Nokogiri::CSS::XPathVisitor.new(prefix: "./") }),
        )
      end
    end

    it "accepts keyword arguments" do
      assert_equal(
        ["./foo"],
        Nokogiri::CSS.xpath_for("foo", prefix: "./"),
      )
      assert_equal(
        ["./foo"],
        Nokogiri::CSS.xpath_for("foo", visitor: Nokogiri::CSS::XPathVisitor.new(prefix: "./")),
      )
    end

    it "does not accept both prefix and visitor" do
      assert_raises(ArgumentError) do
        Nokogiri::CSS.xpath_for("foo", prefix: "./", visitor: Nokogiri::CSS::XPathVisitor.new)
      end
    end

    describe "error handling" do
      it "raises a SyntaxError exception if the query is not valid CSS" do
        assert_raises(Nokogiri::CSS::SyntaxError) { Nokogiri::CSS.xpath_for("'") }
        assert_raises(Nokogiri::CSS::SyntaxError) { Nokogiri::CSS.xpath_for("a[x=]") }
      end

      it "raises a SyntaxError exception if the query is empty" do
        e = assert_raises(Nokogiri::CSS::SyntaxError) { Nokogiri::CSS.xpath_for("") }
        assert_equal("empty CSS selector", e.message)
      end

      it "raises an TypeError exception if the query is not a string" do
        assert_raises(TypeError) { Nokogiri::CSS.xpath_for(nil) }
        assert_raises(TypeError) { Nokogiri::CSS.xpath_for(3) }
        assert_raises(TypeError) { Nokogiri::CSS.xpath_for(Object.new) }
        assert_raises(TypeError) { Nokogiri::CSS.xpath_for(["foo", "bar"]) }
      end

      it "raises an exception for pseudo-classes that are not XPath Names" do
        # see https://github.com/sparklemotion/nokogiri/issues/3193
        assert_raises(Nokogiri::CSS::SyntaxError) { Nokogiri::CSS.xpath_for("div:-moz-drag-over") }
        assert_raises(Nokogiri::CSS::SyntaxError) { Nokogiri::CSS.xpath_for("div:-moz-drag-over()") }
      end
    end
  end
end
