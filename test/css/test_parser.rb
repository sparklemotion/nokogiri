require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module CSS
    class TestParser < Nokogiri::TestCase
      def setup
        @parser = Nokogiri::CSS::Parser.new
      end

      def test_star
        assert_xpath "//*", @parser.parse('*')
      end

      def test_class
        assert_xpath  "//*[contains(@class, 'a') and contains(@class, 'b')]",
                      @parser.parse('.a.b')
        assert_xpath  "//*[contains(@class, 'awesome')]",
                      @parser.parse('.awesome')
        assert_xpath  "//foo[contains(@class, 'awesome')]",
                      @parser.parse('foo.awesome')
        assert_xpath  "//foo//*[contains(@class, 'awesome')]",
                      @parser.parse('foo .awesome')
      end

      def test_ident
        assert_xpath '//x', @parser.parse('x')
      end

      def test_parse_space
        assert_xpath '//x//y', @parser.parse('x y')
      end

      def test_parse_descendant
        assert_xpath '//x/y', @parser.parse('x > y')
      end

      def assert_xpath expected, ast
        assert_equal expected, ast.to_xpath
      end
    end
  end
end
