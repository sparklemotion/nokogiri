# frozen_string_literal: true

require "helper"

module Nokogiri
  module XML
    class TestSyntaxError < Nokogiri::TestCase
      it "#new accepts a message" do
        error = Nokogiri::XML::SyntaxError.new("hello")
        assert_equal "hello", error.message
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
      end
    end
  end
end
