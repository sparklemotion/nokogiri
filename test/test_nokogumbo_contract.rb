# frozen_string_literal: true

require "helper"

describe "Nokogumbo contract expectations" do
  # per https://github.com/rubys/nokogumbo/pull/171
  it "includes the HTML5 public interface" do
    skip("Gumbo is not supported on this platform") unless Nokogiri.uses_gumbo?

    assert_includes(Nokogiri.singleton_methods, :HTML5)

    assert_equal("constant", defined?(Nokogiri::HTML5))
    assert_includes(Nokogiri::HTML5.singleton_methods, :parse)
    assert_includes(Nokogiri::HTML5.singleton_methods, :fragment)

    assert_equal("constant", defined?(Nokogiri::HTML5::Node))
    assert_equal("constant", defined?(Nokogiri::HTML5::Document))
    assert_equal("constant", defined?(Nokogiri::HTML5::DocumentFragment))
  end

  it "includes a replacement for the Nokogumbo private interface" do
    skip("Gumbo is not supported on this platform") unless Nokogiri.uses_gumbo?

    assert_equal("constant", defined?(Nokogiri::Gumbo))
    assert_includes(Nokogiri::Gumbo.singleton_methods, :parse)
    assert_includes(Nokogiri::Gumbo.singleton_methods, :fragment)
  end
end
