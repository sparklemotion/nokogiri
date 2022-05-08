# frozen_string_literal: true

require "helper"

module Nokogiri
  class TestHtml < Nokogiri::TestCase
    describe Nokogiri::HTML do
      it "is the same as Nokogiri::HTML4" do
        assert_same(Nokogiri::HTML, Nokogiri::HTML4)
      end
    end

    describe "Nokogiri.HTML()" do
      it "is the same as Nokogiri.HTML4()" do
        assert_equal(Nokogiri.method(:HTML), Nokogiri.method(:HTML4))
      end

      it "returns a Nokogiri::HTML4::Document" do
        assert_instance_of(Nokogiri::HTML4::Document, Nokogiri::HTML::Document.parse("<html></html>"))
      end
    end

    describe Nokogiri::HTML::Document do
      it "is the same as Nokogiri::HTML4::Document" do
        assert_same(Nokogiri::HTML4::Document, Nokogiri::HTML::Document)
      end
    end
  end
end
