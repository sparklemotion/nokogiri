# frozen_string_literal: true

require "helper"

describe Nokogiri::CSS do
  describe ".xpath_for" do
    it "accepts just a selector" do
      assert_equal(["//foo"], Nokogiri::CSS.xpath_for("foo"))
    end

    it "accepts a CSS::XPathVisitor" do
      Nokogiri::CSS::Parser.without_cache do
        mock_visitor = Minitest::Mock.new
        mock_visitor.expect(:accept, "injected-value", [Nokogiri::CSS::Node])

        result = Nokogiri::CSS.xpath_for("foo", visitor: mock_visitor)

        mock_visitor.verify
        assert_equal(["//injected-value"], result)
      end
    end

    it "accepts an options hash" do
      assert_equal(
        ["./foo"],
        Nokogiri::CSS.xpath_for("foo", { prefix: "./", visitor: Nokogiri::CSS::XPathVisitor.new }),
      )
    end

    it "accepts keyword arguments" do
      assert_equal(
        ["./foo"],
        Nokogiri::CSS.xpath_for("foo", prefix: "./", visitor: Nokogiri::CSS::XPathVisitor.new),
      )
    end

    describe "error handling" do
      it "raises a SyntaxError exception if the query is not valid CSS" do
        assert_raises(Nokogiri::CSS::SyntaxError) { Nokogiri::CSS.xpath_for("'") }
        assert_raises(Nokogiri::CSS::SyntaxError) { Nokogiri::CSS.xpath_for("a[x=]") }
      end

      it "raises a SyntaxError exception if the query is empty" do
        e = assert_raises(Nokogiri::CSS::SyntaxError) { Nokogiri::CSS.xpath_for("") }
        assert_includes("empty CSS selector", e.message)
      end

      it "raises an TypeError exception if the query is not a string" do
        assert_raises(TypeError) { Nokogiri::CSS.xpath_for(nil) }
        assert_raises(TypeError) { Nokogiri::CSS.xpath_for(3) }
        assert_raises(TypeError) { Nokogiri::CSS.xpath_for(Object.new) }
      end
    end
  end
end
