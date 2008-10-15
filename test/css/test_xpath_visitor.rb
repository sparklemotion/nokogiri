require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module CSS
    class TestXPathVisitor < Nokogiri::TestCase
      def setup
        @parser = Nokogiri::CSS::Parser.new
      end

      def test_class_selectors
        assert_xpath  "//*[contains(concat(' ', @class, ' '),concat(' ', 'red', ' '))]",
                      @parser.parse(".red")
      end

      def test_pipe
        assert_xpath  "//a[@id = 'Boing' or starts-with(@id, concat('Boing', '-'))]",
                      @parser.parse("a[id|='Boing']")
      end

      def assert_xpath expecteds, asts
        expecteds = [expecteds].flatten
        expecteds.zip(asts).each do |expected, actual|
          assert_equal expected, actual.to_xpath
        end
      end
    end
  end
end
