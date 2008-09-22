require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module CSS
    class TestNthiness < Nokogiri::TestCase
      def setup
        @parser = Nokogiri.Hpricot(<<-EOF
<table>
  <tr><td>row1 </td></tr>
  <tr><td>row2 </td></tr>
  <tr><td>row3 </td></tr>
  <tr><td>row4 </td></tr>
  <tr><td>row5 </td></tr>
  <tr><td>row6 </td></tr>
  <tr><td>row7 </td></tr>
  <tr><td>row8 </td></tr>
  <tr><td>row9 </td></tr>
  <tr><td>row10 </td></tr>
  <tr><td>row11 </td></tr>
  <tr><td>row12 </td></tr>
  <tr><td>row13 </td></tr>
  <tr><td>row14 </td></tr>
</table>
<div>
  <b>bold1 </b>
  <i>italic1 </i>
  <b>bold2 </b>
  <i>italic2 </i>
</div>
EOF
)
      end


      def test_even
        assert_result_rows [2,4,6,8,10,12,14], @parser.search("table/tr:nth(even)")
      end

      def test_odd
        assert_result_rows [1,3,5,7,9,11,13], @parser.search("table/tr:nth(odd)")
      end

      def test_2n
        assert_equal @parser.search("table/tr:nth(even)").inner_text, @parser.search("table/tr:nth(2n)").inner_text
      end

      def test_2np1
        assert_equal @parser.search("table/tr:nth(odd)").inner_text, @parser.search("table/tr:nth(2n+1)").inner_text
      end

      def test_4np3
        assert_result_rows [3,7,11], @parser.search("table/tr:nth(4n+3)")
      end

      def test_3np4
        assert_result_rows [4,7,10,13], @parser.search("table/tr:nth(3n+4)")
      end

      def test_mnp3
        assert_result_rows [1,2,3], @parser.search("table/tr:nth(-n+3)")
      end

      def test_np3
        assert_result_rows [3,4,5,6,7,8,9,10,11,12,13,14], @parser.search("table/tr:nth(n+3)")
      end

      def test_first
        assert_result_rows [1], @parser.search("table/tr:first")
        assert_result_rows [1], @parser.search("table/tr:first()")
      end

      def test_last
        assert_result_rows [14], @parser.search("table/tr:last")
        assert_result_rows [14], @parser.search("table/tr:last()")
      end

      def test_first_child
        assert_result_rows [1], @parser.search("div/b:first-child"), "bold"
        assert_result_rows [1], @parser.search("table/tr:first-child")
      end

      def test_last_child
        assert_result_rows [2], @parser.search("div/b:last-child"), "bold"
        assert_result_rows [14], @parser.search("table/tr:last-child")
      end

      def test_first_of_type
        assert_result_rows [1], @parser.search("table/tr:first-of-type")
        assert_result_rows [1], @parser.search("div/b:first-of-type"), "bold"
      end

      def test_last_of_type
        assert_result_rows [14], @parser.search("table/tr:last-of-type")
        assert_result_rows [2], @parser.search("div/b:last-of-type"), "bold"
      end

      def assert_result_rows intarray, result, word="row"
        assert_equal intarray.size, result.size, "unexpected number of rows returned"
        assert_equal intarray.map{|j| "#{word}#{j}"}.join(' '), result.inner_text.strip, result.inner_text
      end
    end
  end
end

