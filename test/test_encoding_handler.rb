# -*- coding: utf-8 -*-
# frozen_string_literal: true

require "helper"

describe Nokogiri::EncodingHandler do
  after do
    Nokogiri::EncodingHandler.clear_aliases!
    Nokogiri::EncodingHandler.install_default_aliases
  end

  it :test_get do
    refute_nil(Nokogiri::EncodingHandler["NOKOGIRI-SENTINEL"])
    refute_nil(Nokogiri::EncodingHandler["UTF-8"])
    assert_nil(Nokogiri::EncodingHandler["alsdkjfhaldskjfh"])
  end

  it :test_name do
    eh = Nokogiri::EncodingHandler["UTF-8"]
    assert_equal("UTF-8", eh.name)
  end

  it :test_alias do
    Nokogiri::EncodingHandler.alias("UTF-8", "UTF-18")
    assert_equal("UTF-8", Nokogiri::EncodingHandler["UTF-18"].name)
  end

  it :test_cleanup_aliases do
    assert_nil(Nokogiri::EncodingHandler["UTF-9"])
    Nokogiri::EncodingHandler.alias("UTF-8", "UTF-9")
    refute_nil(Nokogiri::EncodingHandler["UTF-9"])

    Nokogiri::EncodingHandler.clear_aliases!
    assert_nil(Nokogiri::EncodingHandler["UTF-9"])
  end

  it :test_delete do
    assert_nil(Nokogiri::EncodingHandler["UTF-9"])
    Nokogiri::EncodingHandler.alias("UTF-8", "UTF-9")
    refute_nil(Nokogiri::EncodingHandler["UTF-9"])

    Nokogiri::EncodingHandler.delete("UTF-9")
    assert_nil(Nokogiri::EncodingHandler["UTF-9"])
  end

  it :test_delete_non_existent do
    assert_nil(Nokogiri::EncodingHandler.delete("UTF-9"))
  end

  it "deprecates Nokogiri.install_default_aliases" do
    assert_output("", /deprecated/) do
      Nokogiri.install_default_aliases
    end
  end
end
