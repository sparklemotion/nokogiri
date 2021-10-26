# frozen_string_literal: true

require "helper"

class TestCssCacheAccess < Nokogiri::TestCase
  def setup
    super
    @css = "a1 > b2 > c3"
    @parse_result = Nokogiri::CSS.parse(@css)
    @to_xpath_result = @parse_result.map(&:to_xpath)

    Nokogiri::CSS::Parser.clear_cache
    Nokogiri::CSS::Parser.class_eval do
      class << @cache
        alias :old_bracket :[]

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

    assert(Nokogiri::CSS::Parser.cache_on?)
  end

  def teardown
    Nokogiri::CSS::Parser.clear_cache(true)
    Nokogiri::CSS::Parser.set_cache(true)
    super
  end

  [false, true].each do |cache_setting|
    define_method "test_css_cache_#{cache_setting ? "true" : "false"}" do
      Nokogiri::CSS::Parser.set_cache(cache_setting)

      Nokogiri::CSS.xpath_for(@css)
      Nokogiri::CSS.xpath_for(@css)
      Nokogiri::CSS::Parser.new.xpath_for(@css)
      Nokogiri::CSS::Parser.new.xpath_for(@css)

      if cache_setting
        assert_equal(1, Nokogiri::CSS::Parser.class_eval { @cache.count })
        assert_equal(4, Nokogiri::CSS::Parser.class_eval { @cache.access_count })
      else
        assert_equal(0, Nokogiri::CSS::Parser.class_eval { @cache.count })
        assert_equal(0, Nokogiri::CSS::Parser.class_eval { @cache.access_count })
      end
    end
  end
end

class TestCssCache < Nokogiri::TestCase
  def teardown
    Nokogiri::CSS::Parser.set_cache(true)
    super
  end

  def test_enabled_cache_is_used
    Nokogiri::CSS::Parser.clear_cache
    Nokogiri::CSS::Parser.set_cache(true)

    css = ".foo .bar .baz"
    cache = Nokogiri::CSS::Parser.instance_variable_get("@cache")

    assert_nil(cache[css])
    Nokogiri::CSS.xpath_for(css)
    assert(cache[css])

    cache[css] = "this is an injected value"
    assert_equal("this is an injected value", Nokogiri::CSS.xpath_for(css))
  end

  def test_disabled_cache_is_not_used
    Nokogiri::CSS::Parser.clear_cache
    Nokogiri::CSS::Parser.set_cache(false)

    css = ".foo .bar .baz"
    cache = Nokogiri::CSS::Parser.instance_variable_get("@cache")

    assert_nil(cache[css])
    Nokogiri::CSS.xpath_for(css)
    assert_nil(cache[css])
  end

  def test_without_cache_avoids_cache
    Nokogiri::CSS::Parser.clear_cache
    Nokogiri::CSS::Parser.set_cache(true)

    css = ".foo .bar .baz"
    cache = Nokogiri::CSS::Parser.instance_variable_get("@cache")

    assert_nil(cache[css])
    Nokogiri::CSS::Parser.without_cache do
      Nokogiri::CSS.xpath_for(css)
    end
    assert_nil(cache[css])
  end

  def test_without_cache_resets_cache_value
    Nokogiri::CSS::Parser.set_cache(true)

    Nokogiri::CSS::Parser.without_cache do
      assert(!Nokogiri::CSS::Parser.cache_on?)
    end
    assert(Nokogiri::CSS::Parser.cache_on?)
  end

  def test_without_cache_resets_cache_value_even_after_exception
    Nokogiri::CSS::Parser.set_cache(true)

    assert_raises(RuntimeError) do
      Nokogiri::CSS::Parser.without_cache do
        raise RuntimeError
      end
    end
    assert(Nokogiri::CSS::Parser.cache_on?)
  end

  def test_race_condition
    # https://github.com/sparklemotion/nokogiri/issues/1935
    threads = []

    Nokogiri::CSS::Parser.set_cache(true)

    threads << Thread.new do
      Nokogiri::CSS::Parser.without_cache do
        sleep(0.02)
      end
    end

    threads << Thread.new do
      sleep(0.01)

      Nokogiri::CSS::Parser.without_cache do
        sleep(0.02)
      end
    end

    threads.each(&:join)

    assert(Nokogiri::CSS::Parser.cache_on?)
  end
end
