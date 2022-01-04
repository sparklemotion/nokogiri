# frozen_string_literal: true

require "helper"

class TestNokogiriCSS < Nokogiri::TestCase
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
  end
end
