require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module CSS
    class TestParser < Nokogiri::TestCase
      def setup
        @parser = Nokogiri::CSS::Parser.new
      end

      def test_function_with_arguments
        assert_xpath  "//a[position() = 2]",
                      @parser.parse("a[2]")
        assert_xpath  "//a[position() = 2]",
                      @parser.parse("a:nth-child(2)")
      end

      def test_attributes_with_at
        ## This is non standard CSS
        assert_xpath  "//a[@id = 'Boing']",
                      @parser.parse("a[@id='Boing']")
      end

      def test_not_equal
        ## This is non standard CSS
        assert_xpath  "//a[child::text() != 'Boing']",
                      @parser.parse("a[text()!='Boing']")
      end

      def test_function
        ## This is non standard CSS
        assert_xpath  "//a[child::text()]",
                      @parser.parse("a[text()]")

        ## This is non standard CSS
        assert_xpath  "//child::text()",
                      @parser.parse("text()")

        ## This is non standard CSS
        assert_xpath  "//a[contains(child::text(), 'Boing')]",
                      @parser.parse("a[text()*='Boing']")

        ## This is non standard CSS
        assert_xpath  "//script//comment()",
                      @parser.parse("script comment()")
      end

      def test_nonstandard_nth_selectors
        ## These are non standard CSS
        assert_xpath '//a[position() = 100]', @parser.parse('a:eq(99)')
        assert_xpath '//a[position() = 1]', @parser.parse('a:first') # no parens
        assert_xpath '//a[position() = last()]', @parser.parse('a:last') # no parens
        assert_xpath '//a[position() = 100]', @parser.parse('a:nth(99)')
        assert_xpath '//a[position() = 1]', @parser.parse('a:first()')
        assert_xpath '//a[position() = last()]', @parser.parse('a:last()')

        # TODO: this is ambiguous because Hpricot has an off-by-one error
        assert_xpath '//a[position() = 100]', @parser.parse('a:nth-of-type(99)')
      end

      def test_standard_nth_selectors
        assert_xpath '//a[position() = 1]', @parser.parse('a:first-of-type()')
        assert_xpath '//a[position() = last()]', @parser.parse('a:last-of-type()')
        assert_xpath '//a[position() = last() - 99]', @parser.parse('a:nth-last-of-type(99)')
        assert_xpath '//a[position() = last() - 99]', @parser.parse('a:nth-last-of-type(99)')
      end

      def test_nth_child_selectors
        # TODO: verify the xpath is correct for these -child pseudoclasses
        assert_xpath '//*[position() = 1][self::a]', @parser.parse('a:first-child')
        assert_xpath '//*[position() = last()][self::a]', @parser.parse('a:last-child')
        assert_xpath '//*[position() = 100][self::a]', @parser.parse('a:nth-child(99)')
        assert_xpath '//*[position() = last() - 99][self::a]', @parser.parse('a:nth-last-child(99)')
      end

      def test_miscellaneous_selectors
        # TODO: figure out the xpath equivalents
        assert_xpath '//i-do-not-know', @parser.parse('a:only-child')
        assert_xpath '//i-do-not-know', @parser.parse('a:only-of-type')
        assert_xpath '//i-do-not-know', @parser.parse('a:empty')
      end

      def test_nth_a_n_plus_b
        assert_xpath '//a[(position() mod 2) = 0]', @parser.parse('a:nth-of-type(2n)')
        assert_xpath '//a[(position() mod 2) = 1]', @parser.parse('a:nth-of-type(2n+1)')
        assert_xpath '//a[(position() mod 2) = 0]', @parser.parse('a:nth-of-type(even)')
        assert_xpath '//a[(position() mod 2) = 1]', @parser.parse('a:nth-of-type(odd)')
        assert_xpath '//a[(position() mod 4) = 3]', @parser.parse('a:nth-of-type(4n+3)')
      end

      def test_preceding_selector
        assert_xpath  "//F[preceding-sibling::E]",
                      @parser.parse("E ~ F")
      end

      def test_attribute
        assert_xpath  "//h1[@a = 'Tender Lovemaking']",
                      @parser.parse("h1[a='Tender Lovemaking']")
      end

      def test_id
        assert_xpath "//*[@id = 'foo']", @parser.parse('#foo')
      end

      def test_pseudo_class_no_ident
        assert_xpath "//*[1 = 1]", @parser.parse(':link')
      end

      def test_pseudo_class
        assert_xpath "//a[1 = 1]", @parser.parse('a:link')
        assert_xpath "//a[1 = 1]", @parser.parse('a:visited')
        assert_xpath "//a[1 = 1]", @parser.parse('a:hover')
        assert_xpath "//a[1 = 1]", @parser.parse('a:active')
        assert_xpath  "//a[1 = 1 and contains(@class, 'foo')]",
                      @parser.parse('a:active.foo')
      end

      def test_star
        assert_xpath "//*", @parser.parse('*')
        assert_xpath "//*[contains(@class, 'pastoral')]",
                      @parser.parse('*.pastoral')
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

      def test_parse_slash
        ## This is non standard CSS
        assert_xpath '//x/y', @parser.parse('x/y')
      end

      def test_parse_doubleslash
        ## This is non standard CSS
        assert_xpath '//x//y', @parser.parse('x//y')
      end

      def test_multi_path
        assert_xpath ['//x/y', '//y/z'], @parser.parse('x > y, y > z')
        assert_xpath ['//x/y', '//y/z'], @parser.parse('x > y,y > z')
        ###
        # TODO: should we make this work?
        # assert_xpath ['//x/y', '//y/z'], @parser.parse('x > y | y > z')
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
