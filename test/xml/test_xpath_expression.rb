# frozen_string_literal: true

require "helper"

describe Nokogiri::XML::XPath::Expression do
  it ".new" do
    assert_kind_of(Nokogiri::XML::XPath::Expression, Nokogiri::XML::XPath::Expression.new("//foo"))
  end

  it "raises an exception when there are compile-time errors" do
    assert_raises(Nokogiri::XML::XPath::SyntaxError) do
      Nokogiri::XML::XPath.expression("//foo[")
    end
  end
end

describe Nokogiri::XML::XPath do
  it "XPath.expression" do
    assert_kind_of(Nokogiri::XML::XPath::Expression, Nokogiri::XML::XPath.expression("//foo"))
  end
end
