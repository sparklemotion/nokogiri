# frozen_string_literal: true

require "helper"

describe Nokogiri::CSS::Parser do
  let(:parser) { Nokogiri::CSS::Parser.new }

  it "#find_by_type" do
    ast = parser.parse("a:nth-child(2)").first
    matches = ast.find_by_type(
      [
        :CONDITIONAL_SELECTOR,
        [:ELEMENT_NAME],
        [
          :PSEUDO_CLASS,
          [:FUNCTION],
        ],
      ],
    )
    assert_equal(1, matches.length)
    assert_equal(ast, matches.first)
  end

  it "#to_type" do
    ast = parser.parse("a:nth-child(2)").first
    assert_equal(
      [
        :CONDITIONAL_SELECTOR,
        [:ELEMENT_NAME],
        [
          :PSEUDO_CLASS,
          [:FUNCTION],
        ],
      ],
      ast.to_type,
    )
  end

  it "#to_a_" do
    asts = parser.parse("a:nth-child(2)")
    assert_equal(
      [
        :CONDITIONAL_SELECTOR,
        [:ELEMENT_NAME, ["a"]],
        [
          :PSEUDO_CLASS,
          [:FUNCTION, ["nth-child("], ["2"]],
        ],
      ],
      asts.first.to_a,
    )
  end

  it "parses xpath attributes in conditional selectors" do
    ast = parser.parse("a[@class~=bar]").first
    assert_equal(
      [
        :CONDITIONAL_SELECTOR,
        [:ELEMENT_NAME, ["a"]],
        [
          :ATTRIBUTE_CONDITION,
          [:ATTRIB_NAME, ["class"]],
          [:includes],
          ["bar"],
        ],
      ],
      ast.to_a,
    )
  end

  it "parses xpath attributes" do
    ast = parser.parse("a/@href").first
    assert_equal(
      [:CHILD_SELECTOR, [:ELEMENT_NAME, ["a"]], [:ATTRIB_NAME, ["href"]]],
      ast.to_a,
    )
  end

  it "parses xpath attributes passed to xpath functions" do
    ast = parser.parse("a:foo(@href)").first
    assert_equal(
      [
        :CONDITIONAL_SELECTOR,
        [:ELEMENT_NAME, ["a"]],
        [
          :PSEUDO_CLASS,
          [
            :FUNCTION,
            ["foo("],
            [:ATTRIB_NAME, ["href"]],
          ],
        ],
      ],
      ast.to_a,
    )

    ast = parser.parse("a:foo(@href,@id)").first
    assert_equal(
      [
        :CONDITIONAL_SELECTOR,
        [:ELEMENT_NAME, ["a"]],
        [
          :PSEUDO_CLASS,
          [
            :FUNCTION,
            ["foo("],
            [:ATTRIB_NAME, ["href"]],
            [:ATTRIB_NAME, ["id"]],
          ],
        ],
      ],
      ast.to_a,
    )
  end
end
