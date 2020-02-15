require "helper"

class TestCssCache < Nokogiri::TestCase

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

    assert Nokogiri::CSS::Parser.cache_on?
  end

  def teardown
    Nokogiri::CSS::Parser.clear_cache(true)
    Nokogiri::CSS::Parser.set_cache true
    super
  end

  [false, true].each do |cache_setting|
    define_method "test_css_cache_#{cache_setting ? "true" : "false"}" do
      Nokogiri::CSS::Parser.set_cache cache_setting

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
