require "helper"

module Nokogiri
  module XML
    class TestXPathFunctions < Nokogiri::TestCase

      def setup
        super

        @xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)

        @ns = @xml.root.namespaces

        # TODO: Maybe I should move this to the original code.
        @ns["nokogiri"] = "http://www.nokogiri.org/default_ns/ruby/extensions_functions"
        
        Nokogiri::XML::XPathFunctions.reset!
        
        Nokogiri::XML::XPathFunctions.define(:things) do 
          @things ||= []
        end

        Nokogiri::XML::XPathFunctions.define(:thing) do |thing|
          things << thing
          thing
        end
        
        Nokogiri::XML::XPathFunctions.define(:returns_array) do |node_set|
          things << node_set.to_a
          node_set.to_a
        end

        Nokogiri::XML::XPathFunctions.define(:my_filter) do |set, attribute, value|
          set.find_all { |x| x[attribute] == value }
        end

        Nokogiri::XML::XPathFunctions.define(:saves_node_set) do |node_set|
          @things = node_set
        end
        
        @handler = Nokogiri::XML::XPathFunctions.handler
      end

      def test_pass_self_to_function
        set = if Nokogiri.uses_libxml?
                @xml.xpath('//employee/address[my_filter(., "domestic", "Yes")]')
              else
                @xml.xpath('//employee/address[nokogiri:my_filter(., "domestic", "Yes")]', @ns)
              end
        assert set.length > 0
        set.each do |node|
          assert_equal 'Yes', node['domestic']
        end
      end

      def test_custom_xpath_function_gets_strings
        set = @xml.xpath('//employee')
        if Nokogiri.uses_libxml?
          @xml.xpath('//employee[thing("asdf")]')
        else
          @xml.xpath('//employee[nokogiri:thing("asdf")]', @ns)
        end
        assert_equal(set.length, @handler.things.length)
        assert_equal(['asdf'] * set.length, @handler.things)
      end

      def test_custom_xpath_gets_true_booleans
        set = @xml.xpath('//employee')
        if Nokogiri.uses_libxml?
          @xml.xpath('//employee[thing(true())]')
        else
          @xml.xpath("//employee[nokogiri:thing(true())]", @ns)
        end
        assert_equal(set.length, @handler.things.length)
        assert_equal([true] * set.length, @handler.things)
      end

      def test_custom_xpath_gets_false_booleans
        set = @xml.xpath('//employee')
        if Nokogiri.uses_libxml?
          @xml.xpath('//employee[thing(false())]')
        else
          @xml.xpath("//employee[nokogiri:thing(false())]", @ns)
        end
        assert_equal(set.length, @handler.things.length)
        assert_equal([false] * set.length, @handler.things)
      end

      def test_custom_xpath_gets_numbers
        set = @xml.xpath('//employee')
        if Nokogiri.uses_libxml?
          @xml.xpath('//employee[thing(10)]')
        else
          @xml.xpath('//employee[nokogiri:thing(10)]', @ns)
        end
        assert_equal(set.length, @handler.things.length)
        assert_equal([10] * set.length, @handler.things)
      end

      def test_custom_xpath_gets_node_sets
        set = @xml.xpath('//employee/name')
        if Nokogiri.uses_libxml?
          @xml.xpath('//employee[thing(name)]')
        else
          @xml.xpath('//employee[nokogiri:thing(name)]', @ns)
        end
        assert_equal(set.length, @handler.things.length)
        assert_equal(set.to_a, @handler.things.flatten)
      end

      def test_custom_xpath_gets_node_sets_and_returns_array
        set = @xml.xpath('//employee/name')
        if Nokogiri.uses_libxml?
          @xml.xpath('//employee[returns_array(name)]')
        else
          @xml.xpath('//employee[nokogiri:returns_array(name)]', @ns)
        end
        assert_equal(set.length, @handler.things.length)
        assert_equal(set.to_a, @handler.things.flatten)
      end

      def test_custom_xpath_handler_is_passed_a_decorated_node_set
        x = Module.new do
          def awesome! ; end
        end
        util_decorate(@xml, x)

        assert @xml.xpath('//employee/name')

        @xml.xpath('//employee[saves_node_set(name)]')
        assert_equal @xml, @handler.things.document
        assert @handler.things.respond_to?(:awesome!)
      end
      
      def test_override_custom_xpath_handler
        assert_raise RuntimeError, /xmlXPathCompOpEval: function thing not found/ do
          @xml.xpath('//employee[thing(name)]', nil)
        end
      end

      def test_reset_custom_xpath_handler
        Nokogiri::XML::XPathFunctions.reset!
        assert_raise RuntimeError, /xmlXPathCompOpEval: function thing not found/ do
          @xml.xpath('//employee[thing(name)]')
        end
      end
      
      def test_replace_custom_xpath_handler
        my_handler = Class.new {
          def thing(node_set, initial)
            node_set.find_all { |n| n.content.start_with?(initial)  }
          end
        }.new
        set = @xml.xpath('//employee[thing(name, "R")]', my_handler)
        assert_equal(set.length, 2)
      end

    end
  end
end
