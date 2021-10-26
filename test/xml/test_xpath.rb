require "helper"

module Nokogiri
  module XML
    class TestXPath < Nokogiri::TestCase
      # ** WHY ALL THOSE _if Nokogiri.uses_libxml?_ **
      # Hi, my dear readers,
      #
      # After reading these tests you may be wondering why all those ugly
      # if Nokogiri.uses_libxml? sparsed over the whole document. Well, let
      # me explain it. While using XPath in Java, you need the extension
      # functions to be in a namespace. This is not required by XPath, afaik,
      # but it is an usual convention though.
      #
      # Yours truly,
      #
      # The guy whose headaches belong to Nokogiri JRuby impl.

      def setup
        super

        @xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)

        @handler = Class.new do
          attr_reader :things

          def initialize
            @things = []
          end

          def thing thing
            @things << thing
            thing
          end

          def another_thing thing
            @things << thing
            thing
          end

          def returns_array node_set
            @things << node_set.to_a
            node_set.to_a
          end

          def my_filter set, attribute, value
            set.find_all { |x| x[attribute] == value }
          end

          def saves_node_set node_set
            @things = node_set
          end

          def value
            123.456
          end

          def anint
            1230456
          end
        end.new
      end

      def test_variable_binding
        assert_equal 4, @xml.xpath('//address[@domestic=$value]', nil, value: 'Yes').length
      end

      def test_variable_binding_with_search
        assert_equal 4, @xml.search('//address[@domestic=$value]', nil, value: 'Yes').length
      end

      def test_unknown_attribute
        assert_equal 0, @xml.xpath('//employee[@id="asdfasdf"]/@fooo').length
        assert_nil @xml.xpath('//employee[@id="asdfasdf"]/@fooo')[0]
      end

      def test_boolean_false
        assert_equal false, @xml.xpath('1 = 2')
      end

      def test_boolean_true
        assert_equal true, @xml.xpath('1 = 1')
      end

      def test_number_integer
        assert_equal 2, @xml.xpath('1 + 1')
      end

      def test_number_float
        assert_equal 1.5, @xml.xpath('1.5')
      end

      def test_string
        assert_equal 'foo', @xml.xpath('concat("fo", "o")')
      end

      def test_node_search_with_multiple_queries
        xml = '<document>
                 <thing>
                   <div class="title">important thing</div>
                 </thing>
                 <thing>
                   <div class="content">stuff</div>
                 </thing>
                 <thing>
                   <p class="blah">more stuff</div>
                 </thing>
               </document>'
        node = Nokogiri::XML(xml).root
        assert_kind_of Nokogiri::XML::Node, node

        assert_equal 3, node.xpath('.//div', './/p').length
        assert_equal 3, node.css('.title', '.content', 'p').length
        assert_equal 3, node.search('.//div', 'p.blah').length
      end

      def test_css_search_with_ambiguous_integer_or_string_attributes
        # https://github.com/sparklemotion/nokogiri/issues/711
        html = "<body><div><img width=200>"
        doc = Nokogiri::HTML(html)
        assert_not_nil doc.at_css("img[width='200']")
        assert_not_nil doc.at_css("img[width=200]")
      end

      def test_css_search_uses_custom_selectors_with_arguments
        set = @xml.css('employee > address:my_filter("domestic", "Yes")', @handler)
        assert set.length > 0
        set.each do |node|
          assert_equal 'Yes', node['domestic']
        end
      end

      def test_css_search_uses_custom_selectors
        set = @xml.xpath('//employee')
        @xml.css('employee:thing()', @handler)
        assert_equal(set.length, @handler.things.length)
        assert_equal(set.to_a, @handler.things.flatten)
      end

      def test_search_with_css_query_uses_custom_selectors_with_arguments
        set = @xml.search('employee > address:my_filter("domestic", "Yes")', @handler)
        assert set.length > 0
        set.each do |node|
          assert_equal 'Yes', node['domestic']
        end
      end

      def test_search_with_xpath_query_uses_custom_selectors_with_arguments
        set = if Nokogiri.uses_libxml?
          @xml.search('//employee/address[my_filter(., "domestic", "Yes")]', @handler)
        else
          @xml.search('//employee/address[nokogiri:my_filter(., "domestic", "Yes")]', @handler)
        end
        assert set.length > 0
        set.each do |node|
          assert_equal 'Yes', node['domestic']
        end
      end

      def test_pass_self_to_function
        set = if Nokogiri.uses_libxml?
          @xml.xpath('//employee/address[my_filter(., "domestic", "Yes")]', @handler)
        else
          @xml.xpath('//employee/address[nokogiri:my_filter(., "domestic", "Yes")]', @handler)
        end
        assert set.length > 0
        set.each do |node|
          assert_equal 'Yes', node['domestic']
        end
      end

      def test_custom_xpath_function_gets_strings
        set = @xml.xpath('//employee')
        if Nokogiri.uses_libxml?
          @xml.xpath('//employee[thing("asdf")]', @handler)
        else
          @xml.xpath('//employee[nokogiri:thing("asdf")]', @handler)
        end
        assert_equal(set.length, @handler.things.length)
        assert_equal(['asdf'] * set.length, @handler.things)
      end

      def parse_params node
        params = {}
        node.xpath('./param').each do |p|
          subparams = parse_params p
          if subparams.length > 0
            if not params.has_key? p.attributes['name'].value
              params[p.attributes['name'].value] = subparams
            elsif params[p.attributes['name'].value].is_a? Array
              params[p.attributes['name'].value] << subparams
            else
              value = params[p.attributes['name'].value]
              params[p.attributes['name'].value] = [value, subparams]
            end
          else
            params[p.attributes['name'].value] = p.text
          end
        end
        params
      end

      # issue #741 (xpath() around 10x slower in JRuby)
      def test_slow_jruby_xpath
        skip("testing against an absolute time is brittle. help make this better! see https://github.com/sparklemotion/nokogiri/issues/741")

        doc = Nokogiri::XML(File.open(XPATH_FILE))
        start = Time.now

        doc.xpath('.//category').each do |c|
          c.xpath('programformats/programformat').each do |p|
            p.xpath('./modules/module').each do |m|
              parse_params m
            end
          end
        end
        stop = Time.now
        elapsed_time = stop - start
        time_limit = 20
        assert_send [elapsed_time, :<, time_limit], "XPath is taking too long"
      end

      # issue #1109 (jruby impl's xpath() cache not being cleared on attr removal)
      def test_xpath_results_cache_should_get_cleared_on_attr_removal
        doc = Nokogiri::HTML('<html><div name="foo"></div></html>')
        element = doc.at_xpath('//div[@name="foo"]')
        element.remove_attribute('name')
        assert_nil doc.at_xpath('//div[@name="foo"]')
      end

      # issue #1109 (jruby impl's xpath() cache not being cleared on attr update )
      def test_xpath_results_cache_should_get_cleared_on_attr_update
        doc = Nokogiri::HTML('<html><div name="foo"></div></html>')
        element = doc.at_xpath('//div[@name="foo"]')
        element['name'] = 'bar'
        assert_nil doc.at_xpath('//div[@name="foo"]')
      end

      def test_custom_xpath_function_returns_string
        if Nokogiri.uses_libxml?
          result = @xml.xpath('thing("asdf")', @handler)
        else
          result = @xml.xpath('nokogiri:thing("asdf")', @handler)
        end
        assert_equal 'asdf', result
      end

      def test_custom_xpath_gets_true_booleans
        set = @xml.xpath('//employee')
        if Nokogiri.uses_libxml?
          @xml.xpath('//employee[thing(true())]', @handler)
        else
          @xml.xpath("//employee[nokogiri:thing(true())]", @handler)
        end
        assert_equal(set.length, @handler.things.length)
        assert_equal([true] * set.length, @handler.things)
      end

      def test_custom_xpath_gets_false_booleans
        set = @xml.xpath('//employee')
        if Nokogiri.uses_libxml?
          @xml.xpath('//employee[thing(false())]', @handler)
        else
          @xml.xpath("//employee[nokogiri:thing(false())]", @handler)
        end
        assert_equal(set.length, @handler.things.length)
        assert_equal([false] * set.length, @handler.things)
      end

      def test_custom_xpath_gets_numbers
        set = @xml.xpath('//employee')
        if Nokogiri.uses_libxml?
          @xml.xpath('//employee[thing(10)]', @handler)
        else
          @xml.xpath('//employee[nokogiri:thing(10)]', @handler)
        end
        assert_equal(set.length, @handler.things.length)
        assert_equal([10] * set.length, @handler.things)
      end

      def test_custom_xpath_gets_node_sets
        set = @xml.xpath('//employee/name')
        if Nokogiri.uses_libxml?
          @xml.xpath('//employee[thing(name)]', @handler)
        else
          @xml.xpath('//employee[nokogiri:thing(name)]', @handler)
        end
        assert_equal(set.length, @handler.things.length)
        assert_equal(set.to_a, @handler.things.flatten)
      end

      def test_custom_xpath_gets_node_sets_and_returns_array
        set = @xml.xpath('//employee/name')
        if Nokogiri.uses_libxml?
          @xml.xpath('//employee[returns_array(name)]', @handler)
        else
          @xml.xpath('//employee[nokogiri:returns_array(name)]', @handler)
        end
        assert_equal(set.length, @handler.things.length)
        assert_equal(set.to_a, @handler.things.flatten)
      end

      def test_custom_xpath_handler_is_passed_a_decorated_node_set
        x = Module.new do
          def awesome!; end
        end
        util_decorate(@xml, x)

        assert @xml.xpath('//employee/name')

        @xml.xpath('//employee[saves_node_set(name)]', @handler)
        assert_equal @xml, @handler.things.document
        assert @handler.things.respond_to?(:awesome!)
      end

      def test_code_that_invokes_OP_RESET_inside_libxml2
        doc = "<html><body id='foo'><foo>hi</foo></body></html>"
        xpath = 'id("foo")//foo'
        nokogiri = Nokogiri::HTML.parse(doc)
        assert nokogiri.xpath(xpath)
      end

      def test_custom_xpath_handler_with_args_under_gc_pressure
        skip_unless_libxml2("valgrind tests should only run with libxml2")

        refute_valgrind_errors do
          # see http://github.com/sparklemotion/nokogiri/issues/#issue/345
          tool_inspector = Class.new do
            def name_equals(nodeset, name, *args)
              nodeset.all? do |node|
                args.each { |thing| thing.inspect }
                node["name"] == name
              end
            end
          end.new

          xml = <<~EOXML
            <toolbox>
              #{"<tool name='hammer'/><tool name='wrench'/>" * 10}
            </toolbox>
          EOXML
          doc = Nokogiri::XML xml

          # long list of long arguments, to apply GC pressure during
          # ruby_funcall argument marshalling
          xpath = ["//tool[name_equals(.,'hammer'"]
          500.times { xpath << "'unused argument #{'x' * 1000}'" }
          xpath << "'unused argument')]"
          xpath = xpath.join(',')

          assert_equal doc.xpath("//tool[@name='hammer']"), doc.xpath(xpath, tool_inspector)
        end
      end

      def test_custom_xpath_without_arguments
        if Nokogiri.uses_libxml?
          value = @xml.xpath('value()', @handler)
        else
          value = @xml.xpath('nokogiri:value()', @handler)
        end
        assert_equal 123.456, value
      end

      def test_custom_xpath_without_arguments_returning_int
        if Nokogiri.uses_libxml?
          value = @xml.xpath('anint()', @handler)
        else
          value = @xml.xpath('nokogiri:anint()', @handler)
        end
        assert_equal 1230456, value
      end

      def test_custom_xpath_with_bullshit_arguments
        xml = %q{<foo> </foo>}
        doc = Nokogiri::XML.parse(xml)
        foo = doc.xpath('//foo[bool_function(bar/baz)]',
          Class.new do
            def bool_function(value)
              true
            end
          end.new)
        assert_equal foo, doc.xpath("//foo")
      end

      def test_node_set_should_be_decorated
        # "called decorate on nil" exception in JRuby issue#514
        process_output = <<~END
          <test>
            <track type="Image">
            <Format>LZ77</Format>
          </test>
        END
        doc = Nokogiri::XML.parse(process_output)
        node = doc.xpath(%{//track[@type='Video']})
        assert_equal "[]", node.xpath("Format").inspect
      end

      def test_very_specific_xml_xpath_making_problems_in_jruby
        # manually merges pull request #681
        xml_string = %q{<?xml version="1.0" encoding="UTF-8"?>
        <ONIXMessage xmlns:elibri="http://elibri.com.pl/ns/extensions" release="3.0" xmlns="http://www.editeur.org/onix/3.0/reference">
          <Product>
            <RecordReference>a</RecordReference>
          </Product>
        </ONIXMessage>}

        xml_doc = Nokogiri::XML(xml_string)
        onix = xml_doc.children.first
        assert_equal 'a', onix.at_xpath('xmlns:Product').at_xpath('xmlns:RecordReference').text
      end

      def test_xpath_after_attribute_change
        xml_string = %q{<?xml version="1.0" encoding="UTF-8"?>
        <mods version="3.0" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-0.xsd" xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <titleInfo>
              <nonSort>THE</nonSort>
              <title xml:lang="eng">ARTICLE TITLE HYDRANGEA ARTICLE 1</title>
              <subTitle>SUBTITLE</subTitle>
          </titleInfo>
          <titleInfo lang="finnish">
              <title>Artikkelin otsikko Hydrangea artiklan 1</title>
          </titleInfo>
        </mods>}

        xml_doc = Nokogiri::XML(xml_string)
        ns_hash = { 'mods' => 'http://www.loc.gov/mods/v3' }
        node = xml_doc.at_xpath('//mods:titleInfo[1]', ns_hash)
        node['lang'] = 'english'
        assert_equal 1, xml_doc.xpath('//mods:titleInfo[1]/@lang', ns_hash).length
        assert_equal 'english', xml_doc.xpath('//mods:titleInfo[1]/@lang', ns_hash).first.value
      end

      def test_xpath_after_element_removal
        xml_string = %q{<?xml version="1.0" encoding="UTF-8"?>
        <mods version="3.0" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-0.xsd" xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <titleInfo>
              <nonSort>THE</nonSort>
              <title xml:lang="eng">ARTICLE TITLE HYDRANGEA ARTICLE 1</title>
              <subTitle>SUBTITLE</subTitle>
          </titleInfo>
          <titleInfo lang="finnish">
              <title>Artikkelin otsikko Hydrangea artiklan 1</title>
          </titleInfo>
        </mods>}

        xml_doc = Nokogiri::XML(xml_string)
        ns_hash = { 'mods' => 'http://www.loc.gov/mods/v3' }
        node = xml_doc.at_xpath('//mods:titleInfo[1]', ns_hash)
        node.remove
        assert_equal 1, xml_doc.xpath('//mods:titleInfo', ns_hash).length
        assert_equal 'finnish', xml_doc.xpath('//mods:titleInfo[1]/@lang', ns_hash).first.value
      end

      def test_xpath_after_reset_doc_via_innerhtml
        xml = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <document xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0">
            <text:section name="Section1">[TEXT_INSIDE_SECTION]</text:section>
          </document>
        XML

        doc = Nokogiri::XML(xml)
        doc.inner_html = doc.inner_html
        sections = doc.xpath(".//text:section[@name='Section1']")
        assert_equal 1, sections.size
        assert_equal "[TEXT_INSIDE_SECTION]", sections.first.text
      end

      def test_xpath_syntax_error
        doc = Nokogiri::XML('<ns1:Root></ns1:Root>')
        begin
          doc.xpath('//ns1:Root')
        rescue => e
          assert_equal false, e.message.include?('0:0')
        end
      end

      def test_huge_xpath_query
        if Nokogiri.uses_libxml?("~>2.9.11") && !Nokogiri::VERSION_INFO["libxml"]["patches"]&.include?("0007-Fix-XPath-recursion-limit.patch")
          skip("libxml2 under test is broken with respect to xpath query recusion depth")
        end

        # real world example
        # from https://github.com/sparklemotion/nokogiri/issues/2257
        query = File.read(File.join(ASSETS_DIR, 'huge-xpath-query.txt'))

        doc = Nokogiri::XML::Document.parse("<root></root>")
        handler = Class.new do
          def seconds(context)
            42
          end

          def add(context, rhs)
            42
          end
        end
        doc.xpath(query, { "ct" => "https://test.nokogiri.org/ct", "date" => "https://test.nokogiri.org/date" }, handler.new)
      end

      describe "nokogiri-builtin:css-class xpath function" do
        before do
          @doc = Nokogiri::HTML::Document.parse("<html></html>")
        end

        it "accepts exactly two arguments" do
          assert_raise(Nokogiri::XML::XPath::SyntaxError) do
            @doc.xpath("nokogiri-builtin:css-class()")
          end
          assert_raise(Nokogiri::XML::XPath::SyntaxError) do
            @doc.xpath("nokogiri-builtin:css-class('one')")
          end
          assert_raise(Nokogiri::XML::XPath::SyntaxError) do
            @doc.xpath("nokogiri-builtin:css-class('one', 'two', 'three')")
          end

          @doc.xpath("nokogiri-builtin:css-class('one', 'two')")
        end

        it "returns true if second arg is zero-length" do
          assert(@doc.xpath("nokogiri-builtin:css-class('anything', '')"))
        end

        it "matches equal string" do
          refute(@doc.xpath("nokogiri-builtin:css-class('asdf', 'asd')"))
          refute(@doc.xpath("nokogiri-builtin:css-class('asdf', 'sdf')"))
          assert(@doc.xpath("nokogiri-builtin:css-class('asdf', 'asdf')"))
          refute(@doc.xpath("nokogiri-builtin:css-class('asdf', 'xasdf')"))
          refute(@doc.xpath("nokogiri-builtin:css-class('asdf', 'asdfx')"))
        end

        it "matches start of string" do
          refute(@doc.xpath("nokogiri-builtin:css-class('asdf qwer', 'asd')"))
          assert(@doc.xpath("nokogiri-builtin:css-class('asdf qwer', 'asdf')"))
          refute(@doc.xpath("nokogiri-builtin:css-class('asdf qwer', 'asdfg')"))
        end

        it "matches end of string" do
          refute(@doc.xpath("nokogiri-builtin:css-class('qwer asdf', 'sdf')"))
          assert(@doc.xpath("nokogiri-builtin:css-class('qwer asdf', 'asdf')"))
          refute(@doc.xpath("nokogiri-builtin:css-class('qwer asdf', 'xasdf')"))
        end

        it "matches middle of string" do
          refute(@doc.xpath("nokogiri-builtin:css-class('qwer asdf zxcv', 'xasdf')"))
          refute(@doc.xpath("nokogiri-builtin:css-class('qwer asdf zxcv', 'asd')"))
          assert(@doc.xpath("nokogiri-builtin:css-class('qwer asdf zxcv', 'asdf')"))
          refute(@doc.xpath("nokogiri-builtin:css-class('qwer asdf zxcv', 'sdf')"))
          refute(@doc.xpath("nokogiri-builtin:css-class('qwer asdf zxcv', 'asdfx')"))
        end

        # see xmlIsBlank_ch()
        [" ", "\t", "\n", "\r"].each do |ws|
          it "only matches complete whitespace-delimited words (#{sprintf("0x%02X", ws.bytes.first)})" do
            assert(@doc.xpath("nokogiri-builtin:css-class('a#{ws}qwer#{ws}b', 'qwer')"))
            refute(@doc.xpath("nokogiri-builtin:css-class('a#{ws}qwer#{ws}b', 'q')"))
            refute(@doc.xpath("nokogiri-builtin:css-class('a#{ws}qwer#{ws}b', 'qw')"))
            refute(@doc.xpath("nokogiri-builtin:css-class('a#{ws}qwer#{ws}b', 'qwe')"))
            refute(@doc.xpath("nokogiri-builtin:css-class('a#{ws}qwer#{ws}b', 'w')"))
            refute(@doc.xpath("nokogiri-builtin:css-class('a#{ws}qwer#{ws}b', 'we')"))
            refute(@doc.xpath("nokogiri-builtin:css-class('a#{ws}qwer#{ws}b', 'wer')"))
            refute(@doc.xpath("nokogiri-builtin:css-class('a#{ws}qwer#{ws}b', 'e')"))
            refute(@doc.xpath("nokogiri-builtin:css-class('a#{ws}qwer#{ws}b', 'er')"))
            refute(@doc.xpath("nokogiri-builtin:css-class('a#{ws}qwer#{ws}b', 'r')"))
          end
        end
      end

      describe "jruby inferring XPath functions from the handler methods" do
        it "should not get confused simply by a string similarity" do
          # https://github.com/sparklemotion/nokogiri/pull/1890
          # this describes a bug where XmlXpathContext naively replaced query substrings using method names
          handler = Class.new do
            def collision(nodes)
              nil
            end
          end.new
          found_by_id = @xml.xpath("//*[@id='partial_collision_id']", handler)
          assert_equal 1, found_by_id.length
        end

        it "handles multiple handler function calls" do
          # test that jruby handles this case identically to C
          result = @xml.xpath('//employee[thing(.)]/employeeId[another_thing(.)]', @handler)
          assert_equal(5, result.length)
          assert_equal(10, @handler.things.length)
        end

        it "doesn't get confused by an XPath function, flavor 1" do
          # test that it doesn't get confused by an XPath function
          result = @xml.xpath('//employee[thing(.)]/employeeId[last()]', @handler)
          assert_equal(5, result.length)
          assert_equal(5, @handler.things.length)
        end

        it "doesn't get confused by an XPath function, flavor 2" do
          # test that it doesn't get confused by an XPath function
          result = @xml.xpath('//employee[last()]/employeeId[thing(.)]', @handler)
          assert_equal(1, result.length)
          assert_equal(1, @handler.things.length)
        end
      end
    end
  end
end
