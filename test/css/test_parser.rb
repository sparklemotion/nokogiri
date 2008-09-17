require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module CSS
    class TestParser < Nokogiri::TestCase
      def setup
        @parser = Nokogiri::CSS::Parser.new
      end

      def test_parse
        ast = @parser.parse('x > y')
        assert_equal('//x/y', ast.to_xpath)
      end
    end
  end
end
