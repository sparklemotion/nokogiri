require "helper"

module Nokogiri
  module XML
    class TestNamespacesInBuilderDoc < Nokogiri::TestCase
      def setup
        super
        @doc = Nokogiri::XML('<fruit xmlns="ns:fruit" xmlns:veg="ns:veg" xmlns:xlink="http://www.w3.org/1999/xlink"/>')
        pear = @doc.create_element('pear')
        bosc = @doc.create_element('bosc')
        pear.add_child(bosc)
        @doc.root << pear
        @doc.root.add_child('<orange/>')
        carrot = @doc.create_element('veg:carrot')
        @doc.root << carrot
        cheese = @doc.create_element('cheese', :xmlns => 'ns:dairy', :'xlink:href' => 'http://example.com/cheese/')
        carrot << cheese
        bacon = @doc.create_element('meat:bacon', :'xmlns:meat' => 'ns:meat')
        apple = @doc.create_element('apple')
        apple['count'] = 2
        bacon << apple
        tomato = @doc.create_element('veg:tomato')
        bacon << tomato
        @doc.root << bacon
      end

      def check_namespace e
        e.namespace.nil? ? nil : e.namespace.href
      end

      def test_default_ns
        assert_equal 'ns:fruit', check_namespace(@doc.root)
      end
      def test_parent_default_ns
        assert_equal 'ns:fruit', check_namespace(@doc.root.elements[0])
        assert_equal 'ns:fruit', check_namespace(@doc.root.elements[1])
      end
      def test_grandparent_default_ns
        assert_equal 'ns:fruit', check_namespace(@doc.root.elements[0].elements[0])
      end
      def test_parent_nondefault_ns
        assert_equal 'ns:veg',   check_namespace(@doc.root.elements[2])
      end
      def test_single_decl_ns_1
        assert_equal 'ns:dairy', check_namespace(@doc.root.elements[2].elements[0])
      end
      def test_nondefault_attr_ns
        assert_equal 'http://www.w3.org/1999/xlink', check_namespace(@doc.root.elements[2].elements[0].attribute_nodes[0])
      end
      def test_single_decl_ns_2
        assert_equal 'ns:meat',  check_namespace(@doc.root.elements[3])
      end
      def test_buried_default_ns
        assert_equal 'ns:fruit',  check_namespace(@doc.root.elements[3].elements[0])
      end
      def test_buried_decl_ns
        assert_equal 'ns:veg',  check_namespace(@doc.root.elements[3].elements[1])
      end
    end
  end
end
