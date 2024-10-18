# frozen_string_literal: true

require "helper"

describe Nokogiri::XML::SyntaxError do
  it ".new accepts a message" do
    error = Nokogiri::XML::SyntaxError.new("hello")
    assert_equal "hello", error.message
  end

  describe ".aggregate" do
    describe "when there are no errors" do
      it "returns nil" do
        assert_nil(Nokogiri::XML::SyntaxError.aggregate([]))
      end
    end

    describe "when there is exactly one error" do
      it "returns the error" do
        error = Nokogiri::XML::SyntaxError.new("hello")
        assert_equal(error, Nokogiri::XML::SyntaxError.aggregate([error]))
      end
    end

    describe "when there are multiple errors" do
      it "returns a new error with the messages of all errors" do
        errors = [
          Nokogiri::XML::SyntaxError.new("hello"),
          Nokogiri::XML::SyntaxError.new("there"),
          Nokogiri::XML::SyntaxError.new("world"),
        ]
        aggregate = Nokogiri::XML::SyntaxError.aggregate(errors)
        assert_equal(<<~MSG.chomp, aggregate.to_s)
          Multiple errors encountered:
          hello
          there
          world
        MSG
      end
    end
  end

  it "describes the syntax error encountered" do
    if Nokogiri.uses_libxml?
      bad_doc = Nokogiri::XML("test")
      error = bad_doc.errors.first

      assert_equal "1:1: FATAL: Start tag expected, '<' not found", error.message
      assert_equal 1, error.line
      assert_equal 1, error.column
      assert_equal 3, error.level
    else
      bad_doc = Nokogiri::XML("<root>test</bar>")
      error = bad_doc.errors.first

      assert_equal "The element type \"root\" must be terminated by the matching end-tag \"</root>\".", error.message
      assert_nil error.line
      assert_nil error.column
      assert_nil error.level
    end
    assert_nil error.path
  end
end
