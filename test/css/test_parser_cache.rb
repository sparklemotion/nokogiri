# frozen_string_literal: true

require "helper"

describe Nokogiri::CSS::Parser do
  describe "cache" do
    def setup
      super
      @css = "a1 > b2 > c3"

      Nokogiri::CSS::SelectorCache.clear_cache
      Nokogiri::CSS::SelectorCache.class_eval do
        class << @cache
          alias_method :old_bracket, :[]

          def access_count
            @access_count ||= 0
          end

          def [](key)
            @access_count ||= 0
            @access_count += 1
            old_bracket(key)
          end
        end
      end
    end

    def teardown
      Nokogiri::CSS::SelectorCache.clear_cache(true)
      super
    end

    [false, true].each do |cache_setting|
      define_method "test_css_cache_#{cache_setting ? "true" : "false"}" do
        Nokogiri::CSS.xpath_for(@css, cache: cache_setting)
        Nokogiri::CSS.xpath_for(@css, cache: cache_setting)

        if cache_setting
          assert_equal(1, Nokogiri::CSS::SelectorCache.class_eval { @cache.count })
          assert_equal(2, Nokogiri::CSS::SelectorCache.class_eval { @cache.access_count })
        else
          assert_equal(0, Nokogiri::CSS::SelectorCache.class_eval { @cache.count })
          assert_equal(0, Nokogiri::CSS::SelectorCache.class_eval { @cache.access_count })
        end
      end
    end
  end

  class TestCssCache < Nokogiri::TestCase
    def test_enabled_cache_is_used
      Nokogiri::CSS::SelectorCache.clear_cache

      css = ".foo .bar .baz"
      cache = Nokogiri::CSS::SelectorCache.instance_variable_get(:@cache)

      assert_empty(cache)
      Nokogiri::CSS.xpath_for(css)
      refute_empty(cache)
      key = cache.keys.first

      cache[key] = "this is an injected value"
      assert_equal("this is an injected value", Nokogiri::CSS.xpath_for(css))
    end

    def test_without_cache_avoids_cache
      Nokogiri::CSS::SelectorCache.clear_cache

      css = ".foo .bar .baz"
      cache = Nokogiri::CSS::SelectorCache.instance_variable_get(:@cache)

      assert_empty(cache)
      Nokogiri::CSS.xpath_for(css, cache: false)
      assert_empty(cache)
    end

    def test_cache_key_on_ns_prefix_and_visitor_config
      Nokogiri::CSS::SelectorCache.clear_cache

      cache = Nokogiri::CSS::SelectorCache.instance_variable_get(:@cache)
      assert_empty(cache)

      Nokogiri::CSS.xpath_for("foo")
      Nokogiri::CSS.xpath_for("foo", prefix: ".//")
      Nokogiri::CSS.xpath_for("foo", prefix: ".//", ns: { "example" => "http://example.com/" })
      Nokogiri::CSS.xpath_for(
        "foo",
        ns: { "example" => "http://example.com/" },
        visitor: Nokogiri::CSS::XPathVisitor.new(
          builtins: Nokogiri::CSS::XPathVisitor::BuiltinsConfig::ALWAYS,
          prefix: ".//",
        ),
      )
      Nokogiri::CSS.xpath_for(
        "foo",
        ns: { "example" => "http://example.com/" },
        visitor: Nokogiri::CSS::XPathVisitor.new(
          builtins: Nokogiri::CSS::XPathVisitor::BuiltinsConfig::ALWAYS,
          doctype: Nokogiri::CSS::XPathVisitor::DoctypeConfig::HTML5,
          prefix: ".//",
        ),
      )
      assert_equal(5, cache.length)
    end
  end
end
