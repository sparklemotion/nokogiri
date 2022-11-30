# encoding: utf-8
# frozen_string_literal: true

require "helper"

describe Nokogiri::HTML5 do
  describe "Document#quirks_mode" do
    let(:document) { Nokogiri::HTML5::Document.parse(html) }

    describe "without parsing anything" do
      it "returns nil" do
        assert_nil(Nokogiri::HTML5::Document.new.quirks_mode)
      end
    end

    describe "on a document with a doctype" do
      let(:html) { "<!DOCTYPE html><p>hello</p>" }

      it "returns NO_QUIRKS" do
        assert_equal(Nokogiri::HTML5::QuirksMode::NO_QUIRKS, document.quirks_mode)
      end
    end

    describe "on a document without a doctype" do
      let(:html) { "<html><p>hello</p>" }

      it "returns QUIRKS" do
        assert_equal(Nokogiri::HTML5::QuirksMode::QUIRKS, document.quirks_mode)
      end
    end
  end
end if Nokogiri.uses_gumbo?
