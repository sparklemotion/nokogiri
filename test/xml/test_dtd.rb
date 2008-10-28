require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module HTML
    class TestDTD < Nokogiri::TestCase
      def setup
        @xml = Nokogiri::XML.parse(File.read(XML_FILE))
      end

      def test_external_subsets
        assert subset = @xml.internal_subset
        assert_equal 'staff', subset.name
      end

      def test_notations
        dtd = @xml.internal_subset
        assert dtd
        assert notations = dtd.notations
        assert_equal %w[ notation1 notation2 ].sort, notations.keys.sort
        assert notation1 = notations['notation1']
        assert_equal 'notation1', notation1.name
        assert_equal 'notation1File', notation1.public_id
        assert_nil notation1.system_id
      end
    end
  end
end
