# frozen_string_literal: true

require "helper"

describe Nokogiri::CSS::SelectorCache do
  before do
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

  after do
    Nokogiri::CSS::SelectorCache.clear_cache(true)
  end

  let(:selector_list) { "a1 > b2 > c3" }

  it "uses the cache by default" do
    Nokogiri::CSS.xpath_for(selector_list)
    Nokogiri::CSS.xpath_for(selector_list)

    assert_equal(1, Nokogiri::CSS::SelectorCache.class_eval { @cache.count })
    assert_equal(2, Nokogiri::CSS::SelectorCache.class_eval { @cache.access_count })
  end

  it "uses the cache when explicitly requested" do
    Nokogiri::CSS.xpath_for(selector_list, cache: true)
    Nokogiri::CSS.xpath_for(selector_list, cache: true)

    assert_equal(1, Nokogiri::CSS::SelectorCache.class_eval { @cache.count })
    assert_equal(2, Nokogiri::CSS::SelectorCache.class_eval { @cache.access_count })
  end

  it "does not use the cache when explicitly requested" do
    Nokogiri::CSS.xpath_for(selector_list, cache: false)
    Nokogiri::CSS.xpath_for(selector_list, cache: false)

    assert_equal(0, Nokogiri::CSS::SelectorCache.class_eval { @cache.count })
    assert_equal(0, Nokogiri::CSS::SelectorCache.class_eval { @cache.access_count })
  end

  it "uses the cached expressions" do
    Nokogiri::CSS::SelectorCache.clear_cache

    cache = Nokogiri::CSS::SelectorCache.instance_variable_get(:@cache)

    assert_empty(cache)
    Nokogiri::CSS.xpath_for(selector_list)
    refute_empty(cache)
    key = cache.keys.first

    cache[key] = ["this is an injected value"]
    assert_equal(["this is an injected value"], Nokogiri::CSS.xpath_for(selector_list))
  end

  it "test_cache_key_on_ns_prefix_and_visitor_config" do
    Nokogiri::CSS::SelectorCache.clear_cache

    cache = Nokogiri::CSS::SelectorCache.instance_variable_get(:@cache)
    assert_empty(cache)

    Nokogiri::CSS.xpath_for(selector_list)
    Nokogiri::CSS.xpath_for(selector_list, prefix: ".//")
    Nokogiri::CSS.xpath_for(selector_list, prefix: ".//", ns: { "example" => "http://example.com/" })
    Nokogiri::CSS.xpath_for(
      selector_list,
      visitor: Nokogiri::CSS::XPathVisitor.new(
        builtins: Nokogiri::CSS::XPathVisitor::BuiltinsConfig::ALWAYS,
        prefix: ".//",
        namespaces: { "example" => "http://example.com/" },
      ),
    )
    Nokogiri::CSS.xpath_for(
      selector_list,
      visitor: Nokogiri::CSS::XPathVisitor.new(
        builtins: Nokogiri::CSS::XPathVisitor::BuiltinsConfig::ALWAYS,
        doctype: Nokogiri::CSS::XPathVisitor::DoctypeConfig::HTML5,
        prefix: ".//",
        namespaces: { "example" => "http://example.com/" },
      ),
    )
    assert_equal(5, cache.length)
  end
end
