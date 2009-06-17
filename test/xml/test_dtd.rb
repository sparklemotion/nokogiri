require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestDTD < Nokogiri::TestCase
      def setup
        super
        @xml = Nokogiri::XML(File.open(XML_FILE))
        assert @dtd = @xml.internal_subset
      end

      def test_validate
        list = @xml.internal_subset.validate @xml
        assert_equal 44, list.length
      end

      def test_external_subsets
        assert subset = @xml.internal_subset
        assert_equal 'staff', subset.name
      end

      def test_entities
        assert entities = @dtd.entities
        assert_equal %w[ ent1 ent2 ent3 ent4 ent5 ].sort, entities.keys.sort
      end

      def test_attributes
        assert_nil @dtd.attributes
      end

      def test_elements
        assert elements = @dtd.elements
        assert_equal %w[ br ], elements.keys
        assert_equal 'br', elements['br'].name
      end

      def test_notations
        assert notations = @dtd.notations
        assert_equal %w[ notation1 notation2 ].sort, notations.keys.sort
        assert notation1 = notations['notation1']
        assert_equal 'notation1', notation1.name
        assert_equal 'notation1File', notation1.public_id
        assert_nil notation1.system_id
      end
    end
  end
end
