# frozen_string_literal: true

require "helper"

module Nokogiri
  module XML
    class TestXPath < Nokogiri::TestCase
      def setup
        super

        @xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)

        @handler = Class.new do
          attr_reader :things

          def initialize
            super
            @things = []
          end

          def thing(thing)
            @things << thing
            thing
          end

          def another_thing(thing)
            @things << thing
            thing
          end

          def returns_array(node_set)
            @things << node_set.to_a
            node_set.to_a
          end

          def my_filter(set, attribute, value)
            set.find_all { |x| x[attribute] == value }
          end

          def saves_node_set(node_set)
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
        assert_equal(4, @xml.xpath("//address[@domestic=$value]", nil, value: "Yes").length)
      end

      def test_variable_binding_with_search
        assert_equal(4, @xml.search("//address[@domestic=$value]", nil, value: "Yes").length)
      end

      def test_unknown_attribute
        assert_equal(0, @xml.xpath('//employee[@id="asdfasdf"]/@fooo').length)
        assert_nil(@xml.xpath('//employee[@id="asdfasdf"]/@fooo')[0])
      end

      def test_boolean_false
        refute(@xml.xpath("1 = 2"))
      end

      def test_boolean_true
        assert(@xml.xpath("1 = 1"))
      end

      def test_number_integer
        assert_equal(2, @xml.xpath("1 + 1"))
      end

      def test_number_float
        assert_in_delta(1.5, @xml.xpath("1.5"))
      end

      def test_string
        assert_equal("foo", @xml.xpath('concat("fo", "o")'))
      end

      def test_node_search_with_multiple_queries
        xml = <<~EOF
          <document>
            <thing>
              <div class="title">important thing</div>
            </thing>
            <thing>
              <div class="content">stuff</div>
            </thing>
            <thing>
              <p class="blah">more stuff</div>
            </thing>
          </document>
        EOF
        node = Nokogiri::XML(xml).root
        assert_kind_of(Nokogiri::XML::Node, node)

        assert_equal(3, node.xpath(".//div", ".//p").length)
        assert_equal(3, node.css(".title", ".content", "p").length)
        assert_equal(3, node.search(".//div", "p.blah").length)
      end

      def test_css_search_with_ambiguous_integer_or_string_attributes
        # https://github.com/sparklemotion/nokogiri/issues/711
        html = "<body><div><img width=200>"
        doc = Nokogiri::HTML4(html)
        refute_nil(doc.at_css("img[width='200']"))
        refute_nil(doc.at_css("img[width=200]"))
      end

      def test_xpath_with_nonnamespaced_custom_function_is_deprecated_but_works
        skip_unless_libxml2("only deprecated in CRuby")

        result = nil
        assert_output("", /Invoking custom handler functions without a namespace is deprecated/) do
          result = @xml.xpath("anint()", @handler)
        end
        assert_equal(1230456, result)
      end

      def test_xpath_with_namespaced_custom_function_is_not_deprecated
        result = nil
        assert_silent do
          result = @xml.xpath("nokogiri:anint()", @handler)
        end
        assert_equal(1230456, result)
      end

      def test_css_search_uses_custom_selectors_with_arguments
        set = @xml.css('employee > address:my_filter("domestic", "Yes")', @handler)
        refute_empty(set)
        set.each do |node|
          assert_equal("Yes", node["domestic"])
        end
      end

      def test_css_search_uses_custom_selectors
        set = @xml.xpath("//employee")
        @xml.css("employee:thing()", @handler)
        assert_equal(set.length, @handler.things.length)
        assert_equal(set.to_a, @handler.things.flatten)
      end

      def test_search_with_css_query_uses_custom_selectors_with_arguments
        set = @xml.search('employee > address:my_filter("domestic", "Yes")', @handler)
        refute_empty(set)
        set.each do |node|
          assert_equal("Yes", node["domestic"])
        end
      end

      def test_search_with_xpath_query_uses_custom_selectors_with_arguments
        set = @xml.search('//employee/address[nokogiri:my_filter(., "domestic", "Yes")]', @handler)
        refute_empty(set)
        set.each do |node|
          assert_equal("Yes", node["domestic"])
        end
      end

      def test_pass_self_to_function
        set = @xml.xpath('//employee/address[nokogiri:my_filter(., "domestic", "Yes")]', @handler)
        refute_empty(set)
        set.each do |node|
          assert_equal("Yes", node["domestic"])
        end
      end

      def test_custom_xpath_function_gets_strings
        set = @xml.xpath("//employee")
        @xml.xpath('//employee[nokogiri:thing("asdf")]', @handler)
        assert_equal(set.length, @handler.things.length)
        assert_equal(["asdf"] * set.length, @handler.things)
      end

      def parse_params(node)
        params = {}
        node.xpath("./param").each do |p|
          subparams = parse_params(p)
          if !subparams.empty?
            if !params.key?(p.attributes["name"].value)
              params[p.attributes["name"].value] = subparams
            elsif params[p.attributes["name"].value].is_a?(Array)
              params[p.attributes["name"].value] << subparams
            else
              value = params[p.attributes["name"].value]
              params[p.attributes["name"].value] = [value, subparams]
            end
          else
            params[p.attributes["name"].value] = p.text
          end
        end
        params
      end

      # issue #741 (xpath() around 10x slower in JRuby)
      def test_slow_jruby_xpath
        skip("testing against an absolute time is brittle. help make this better! see https://github.com/sparklemotion/nokogiri/issues/741")

        doc = Nokogiri::XML(File.open(XPATH_FILE))
        start = Time.now

        doc.xpath(".//category").each do |c|
          c.xpath("programformats/programformat").each do |p|
            p.xpath("./modules/module").each do |m|
              parse_params(m)
            end
          end
        end
        stop = Time.now
        elapsed_time = stop - start
        time_limit = 20
        assert_send([elapsed_time, :<, time_limit], "XPath is taking too long")
      end

      # issue #1109 (jruby impl's xpath() cache not being cleared on attr removal)
      def test_xpath_results_cache_should_get_cleared_on_attr_removal
        doc = Nokogiri::HTML('<html><div name="foo"></div></html>')
        element = doc.at_xpath('//div[@name="foo"]')
        element.remove_attribute("name")
        assert_nil(doc.at_xpath('//div[@name="foo"]'))
      end

      # issue #1109 (jruby impl's xpath() cache not being cleared on attr update )
      def test_xpath_results_cache_should_get_cleared_on_attr_update
        doc = Nokogiri::HTML('<html><div name="foo"></div></html>')
        element = doc.at_xpath('//div[@name="foo"]')
        element["name"] = "bar"
        assert_nil(doc.at_xpath('//div[@name="foo"]'))
      end

      def test_custom_xpath_function_returns_string
        result = @xml.xpath('nokogiri:thing("asdf")', @handler)
        assert_equal("asdf", result)
      end

      def test_custom_xpath_gets_true_booleans
        set = @xml.xpath("//employee")
        @xml.xpath("//employee[nokogiri:thing(true())]", @handler)
        assert_equal(set.length, @handler.things.length)
        assert_equal([true] * set.length, @handler.things)
      end

      def test_custom_xpath_gets_false_booleans
        set = @xml.xpath("//employee")
        @xml.xpath("//employee[nokogiri:thing(false())]", @handler)
        assert_equal(set.length, @handler.things.length)
        assert_equal([false] * set.length, @handler.things)
      end

      def test_custom_xpath_gets_numbers
        set = @xml.xpath("//employee")
        @xml.xpath("//employee[nokogiri:thing(10)]", @handler)
        assert_equal(set.length, @handler.things.length)
        assert_equal([10] * set.length, @handler.things)
      end

      def test_custom_xpath_gets_node_sets
        set = @xml.xpath("//employee/name")
        @xml.xpath("//employee[nokogiri:thing(name)]", @handler)
        assert_equal(set.length, @handler.things.length)
        assert_equal(set.to_a, @handler.things.flatten)
      end

      def test_custom_xpath_gets_node_sets_and_returns_array
        set = @xml.xpath("//employee/name")
        @xml.xpath("//employee[nokogiri:returns_array(name)]", @handler)
        assert_equal(set.length, @handler.things.length)
        assert_equal(set.to_a, @handler.things.flatten)
      end

      def test_custom_xpath_handler_is_passed_a_decorated_node_set
        x = Module.new do
          def awesome!; end
        end
        util_decorate(@xml, x)

        assert(@xml.xpath("//employee/name"))

        @xml.xpath("//employee[nokogiri:saves_node_set(name)]", @handler)
        assert_equal(@xml, @handler.things.document)
        assert_respond_to(@handler.things, :awesome!)
      end

      def test_code_that_invokes_OP_RESET_inside_libxml2
        doc = "<html><body id='foo'><foo>hi</foo></body></html>"
        xpath = 'id("foo")//foo'
        nokogiri = Nokogiri::HTML4.parse(doc)
        assert(nokogiri.xpath(xpath))
      end

      def test_custom_xpath_handler_with_args_under_gc_pressure
        skip_unless_libxml2("valgrind tests should only run with libxml2")

        refute_valgrind_errors do
          # see http://github.com/sparklemotion/nokogiri/issues/#issue/345
          tool_inspector = Class.new do
            def name_equals(nodeset, name, *args)
              nodeset.all? do |node|
                args.each(&:inspect)
                node["name"] == name
              end
            end
          end.new

          xml = <<~EOXML
            <toolbox>
              #{"<tool name='hammer'/><tool name='wrench'/>" * 10}
            </toolbox>
          EOXML
          doc = Nokogiri::XML(xml)

          # long list of long arguments, to apply GC pressure during
          # ruby_funcall argument marshalling
          xpath = ["//tool[nokogiri:name_equals(.,'hammer'"]
          500.times { xpath << "'unused argument #{"x" * 1000}'" }
          xpath << "'unused argument')]"
          xpath = xpath.join(",")

          assert_equal(doc.xpath("//tool[@name='hammer']"), doc.xpath(xpath, tool_inspector))
        end
      end

      def test_custom_xpath_without_arguments
        value = @xml.xpath("nokogiri:value()", @handler)
        assert_in_delta(123.456, value)
      end

      def test_custom_xpath_without_arguments_returning_int
        value = @xml.xpath("nokogiri:anint()", @handler)
        assert_equal(1230456, value)
      end

      def test_custom_xpath_with_bullshit_arguments
        xml = "<foo> </foo>"
        doc = Nokogiri::XML.parse(xml)
        foo = doc.xpath(
          "//foo[nokogiri:bool_function(bar/baz)]",
          Class.new do
            def bool_function(value)
              true
            end
          end.new,
        )
        assert_equal(foo, doc.xpath("//foo"))
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
        assert_equal("[]", node.xpath("Format").inspect)
      end

      def test_very_specific_xml_xpath_making_problems_in_jruby
        # manually merges pull request #681
        xml_string = <<~EOF
          <?xml version="1.0" encoding="UTF-8"?>
          <ONIXMessage xmlns:elibri="http://elibri.com.pl/ns/extensions" release="3.0" xmlns="http://www.editeur.org/onix/3.0/reference">
            <Product>
              <RecordReference>a</RecordReference>
            </Product>
          </ONIXMessage>
        EOF
        xml_doc = Nokogiri::XML(xml_string)
        onix = xml_doc.children.first
        assert_equal("a", onix.at_xpath("xmlns:Product").at_xpath("xmlns:RecordReference").text)
      end

      def test_xpath_after_attribute_change
        xml_string = <<~EOF
          <?xml version="1.0" encoding="UTF-8"?>
          <mods version="3.0" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-0.xsd" xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <titleInfo>
              <nonSort>THE</nonSort>
              <title xml:lang="eng">ARTICLE TITLE HYDRANGEA ARTICLE 1</title>
              <subTitle>SUBTITLE</subTitle>
            </titleInfo>
            <titleInfo lang="finnish">
              <title>Artikkelin otsikko Hydrangea artiklan 1</title>
            </titleInfo>
          </mods>
        EOF
        xml_doc = Nokogiri::XML(xml_string)
        ns_hash = { "mods" => "http://www.loc.gov/mods/v3" }
        node = xml_doc.at_xpath("//mods:titleInfo[1]", ns_hash)
        node["lang"] = "english"
        assert_equal(1, xml_doc.xpath("//mods:titleInfo[1]/@lang", ns_hash).length)
        assert_equal("english", xml_doc.xpath("//mods:titleInfo[1]/@lang", ns_hash).first.value)
      end

      def test_xpath_after_element_removal
        xml_string = <<~EOF
          <?xml version="1.0" encoding="UTF-8"?>
          <mods version="3.0" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-0.xsd" xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <titleInfo>
              <nonSort>THE</nonSort>
              <title xml:lang="eng">ARTICLE TITLE HYDRANGEA ARTICLE 1</title>
              <subTitle>SUBTITLE</subTitle>
            </titleInfo>
            <titleInfo lang="finnish">
              <title>Artikkelin otsikko Hydrangea artiklan 1</title>
            </titleInfo>
          </mods>
        EOF
        xml_doc = Nokogiri::XML(xml_string)
        ns_hash = { "mods" => "http://www.loc.gov/mods/v3" }
        node = xml_doc.at_xpath("//mods:titleInfo[1]", ns_hash)
        node.remove
        assert_equal(1, xml_doc.xpath("//mods:titleInfo", ns_hash).length)
        assert_equal("finnish", xml_doc.xpath("//mods:titleInfo[1]/@lang", ns_hash).first.value)
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
        assert_equal(1, sections.size)
        assert_equal("[TEXT_INSIDE_SECTION]", sections.first.text)
      end

      def test_xpath_syntax_error_should_not_display_line_and_column_if_both_are_zero
        doc = Nokogiri::XML("<ns1:Root></ns1:Root>")
        e = assert_raises(Nokogiri::XML::SyntaxError) do
          doc.xpath("//ns1:Root")
        end
        refute_includes(e.message, "0:0")
      end

      def test_huge_xpath_query
        if Nokogiri::VersionInfo.instance.libxml2_using_system? && Nokogiri.uses_libxml?([">= 2.9.11", "< 2.9.13"])
          skip("upstream libxml2 3e1aad4f")
        end

        # real world example from https://github.com/sparklemotion/nokogiri/issues/2257
        query = File.read(File.join(ASSETS_DIR, "huge-xpath-query.txt"))

        doc = Nokogiri::XML::Document.parse("<root></root>")
        handler = Class.new do
          def seconds(context)
            42
          end

          def add(context, rhs)
            42
          end
        end
        result = doc.xpath(query, { "ct" => "https://test.nokogiri.org/ct", "date" => "https://test.nokogiri.org/date" }, handler.new)
        assert(result)
      end

      describe "nokogiri-builtin:css-class xpath function" do
        before do
          @doc = Nokogiri::HTML4::Document.parse("<html></html>")
        end

        it "accepts exactly two arguments" do
          assert_raises(Nokogiri::XML::XPath::SyntaxError) do
            @doc.xpath("nokogiri-builtin:css-class()")
          end
          assert_raises(Nokogiri::XML::XPath::SyntaxError) do
            @doc.xpath("nokogiri-builtin:css-class('one')")
          end
          assert_raises(Nokogiri::XML::XPath::SyntaxError) do
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
          it "only matches complete whitespace-delimited words (#{format("0x%02X", ws.bytes.first)})" do
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
          result = @xml.xpath("//employee[nokogiri:thing(.)]/employeeId[nokogiri:another_thing(.)]", @handler)
          assert_equal(5, result.length)
          assert_equal(10, @handler.things.length)
        end

        it "doesn't get confused by an XPath function, flavor 1" do
          # test that it doesn't get confused by an XPath function
          result = @xml.xpath("//employee[nokogiri:thing(.)]/employeeId[last()]", @handler)
          assert_equal(5, result.length)
          assert_equal(5, @handler.things.length)
        end

        it "doesn't get confused by an XPath function, flavor 2" do
          # test that it doesn't get confused by an XPath function
          result = @xml.xpath("//employee[last()]/employeeId[nokogiri:thing(.)]", @handler)
          assert_equal(1, result.length)
          assert_equal(1, @handler.things.length)
        end
      end

      describe "Document#xpath_doctype" do
        it "Nokogiri::XML::Document" do
          assert_equal(
            Nokogiri::CSS::XPathVisitor::DoctypeConfig::XML,
            Nokogiri::XML::Document.parse("<root></root>").xpath_doctype,
          )
          assert_equal(
            Nokogiri::CSS::XPathVisitor::DoctypeConfig::XML,
            Nokogiri::XML::DocumentFragment.parse("<root></root>").document.xpath_doctype,
          )
        end

        it "Nokogiri::HTML4::Document" do
          assert_equal(
            Nokogiri::CSS::XPathVisitor::DoctypeConfig::HTML4,
            Nokogiri::HTML4::Document.parse("<root></root>").xpath_doctype,
          )
          assert_equal(
            Nokogiri::CSS::XPathVisitor::DoctypeConfig::HTML4,
            Nokogiri::HTML4::DocumentFragment.parse("<root></root>").document.xpath_doctype,
          )
        end

        it "Nokogiri::HTML5::Document" do
          skip("HTML5 is not supported") unless defined?(Nokogiri::HTML5)
          assert_equal(
            Nokogiri::CSS::XPathVisitor::DoctypeConfig::HTML5,
            Nokogiri::HTML5::Document.parse("<root></root>").xpath_doctype,
          )
          assert_equal(
            Nokogiri::CSS::XPathVisitor::DoctypeConfig::HTML5,
            Nokogiri::HTML5::DocumentFragment.parse("<root></root>").document.xpath_doctype,
          )
        end
      end

      describe "HTML5 foreign elements" do
        # https://github.com/sparklemotion/nokogiri/issues/2376
        let(:html) { <<~HTML }
          <!DOCTYPE html>
          <html>
            <body>
              <div id="svg-container">
                <svg version="1.1" width="300" height="200" xmlns="http://www.w3.org/2000/svg">
                  <rect width="100%" height="100%" fill="red" />
                  <circle cx="150" cy="100" r="80" fill="green" />
                  <text x="150" y="125" font-size="60" text-anchor="middle" fill="white">SVG</text>
                </svg>
              </div>
            </body>
          </html>
        HTML

        let(:ns) { { "nsfoo" => "http://www.w3.org/2000/svg" } }

        describe "in an XML doc" do
          let(:doc) { Nokogiri::XML::Document.parse(html) }

          it "requires namespace in XPath queries" do
            assert_empty(doc.xpath("//svg"))
            refute_empty(doc.xpath("//nsfoo:svg", ns))
          end

          it "requires namespace in CSS queries" do
            assert_empty(doc.css("svg"))
            refute_empty(doc.css("nsfoo|svg", ns))
          end
        end

        describe "in an HTML4 doc" do
          let(:doc) { Nokogiri::HTML4::Document.parse(html) }

          it "omits namespace in XPath queries" do
            refute_empty(doc.xpath("//svg"))
            assert_empty(doc.xpath("//nsfoo:svg", ns))
          end

          it "omits namespace in CSS queries" do
            refute_empty(doc.css("svg"))
            assert_empty(doc.css("nsfoo|svg", ns))
          end
        end

        describe "in an HTML5 doc" do
          let(:doc) { Nokogiri::HTML5::Document.parse(html) }

          it "requires namespace in XPath queries" do
            skip("HTML5 is not supported") unless defined?(Nokogiri::HTML5)
            assert_empty(doc.xpath("//svg"))
            refute_empty(doc.xpath("//nsfoo:svg", ns))
          end

          it "omits namespace in CSS queries" do
            skip("HTML5 is not supported") unless defined?(Nokogiri::HTML5)
            refute_empty(doc.css("svg"))
            refute_empty(doc.css("nsfoo|svg", ns)) # if they specify the valid ns, use it
            assert_empty(doc.css("nsbar|svg", { "nsbar" => "http://example.com/nsbar" }))
          end
        end
      end

      describe "XPath wildcard namespaces" do
        let(:xml) { <<~XML }
          <root xmlns:ns1="http://nokogiri.org/ns1" xmlns:ns2="http://nokogiri.org/ns2">
            <ns1:child>ns1 child</ns1:child>
            <ns2:child>ns2 child</ns2:child>
            <child>plain child</child>
          </root>
        XML

        let(:doc) { Nokogiri::XML::Document.parse(xml) }

        it "allows namespace wildcards" do
          skip_unless_libxml2_patch("0009-allow-wildcard-namespaces.patch")

          assert_equal(1, doc.xpath("//n:child", { "n" => "http://nokogiri.org/ns1" }).length)
          assert_equal(3, doc.xpath("//*:child").length)
          assert_equal(1, doc.xpath("//self::n:child", { "n" => "http://nokogiri.org/ns1" }).length)
          assert_equal(3, doc.xpath("//self::*:child").length)
        end
      end
    end
  end
end
