require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestNodeSet < Nokogiri::TestCase
      def setup
        super
        @xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
      end

      def test_dup
        assert node_set = @xml.xpath('//employee')
        dup = node_set.dup
        assert_equal node_set.length, dup.length
        node_set.zip(dup).each do |a,b|
          assert_equal a, b
        end
      end

      def test_xmlns_is_automatically_registered
        doc = Nokogiri::XML(<<-eoxml)
          <root xmlns="http://tenderlovemaking.com/">
            <foo>
              <bar/>
            </foo>
          </root>
        eoxml
        set = doc.css('foo')
        assert_equal 1, set.css('xmlns|bar').length
        assert_equal 0, set.css('|bar').length
        assert_equal 1, set.xpath('//xmlns:bar').length
        assert_equal 1, set.search('xmlns|bar').length
        assert_equal 1, set.search('//xmlns:bar').length
        assert set.at('//xmlns:bar')
        assert set.at('xmlns|bar')
        assert set.at('bar')
      end

      def test_length_size
        assert node_set = @xml.search('//employee')
        assert_equal node_set.length, node_set.size
      end

      def test_to_xml
        assert node_set = @xml.search('//employee')
        assert node_set.to_xml
      end

      def test_inner_html
        doc = Nokogiri::HTML(<<-eohtml)
          <html>
            <body>
              <div>
                <a>one</a>
              </div>
              <div>
                <a>two</a>
              </div>
            </body>
          </html>
        eohtml
        assert html = doc.css('div').inner_html
        assert_match '<a>', html
      end

      def test_at
        assert node_set = @xml.search('//employee')
        assert_equal node_set.first, node_set.at(0)
      end

      def test_to_ary
        assert node_set = @xml.search('//employee')
        foo = []
        foo += node_set
        assert_equal node_set.length, foo.length
      end

      def test_push
        node = Nokogiri::XML::Node.new('foo', @xml)
        node.content = 'bar'

        assert node_set = @xml.search('//employee')
        node_set.push(node)

        assert node_set.include?(node)
      end

      def test_unlink
        xml = Nokogiri::XML.parse(<<-eoxml)
        <root>
          <a class='foo bar'>Bar</a>
          <a class='bar foo'>Bar</a>
          <a class='bar'>Bar</a>
          <a>Hello world</a>
          <a class='baz bar foo'>Bar</a>
          <a class='bazbarfoo'>Awesome</a>
          <a class='bazbar'>Awesome</a>
        </root>
        eoxml
        set = xml.xpath('//a')
        set.unlink
        set.each do |node|
          assert !node.parent
          #assert !node.document
          assert !node.previous_sibling
          assert !node.next_sibling
        end
        assert_no_match(/Hello world/, xml.to_s)
      end

      def test_nodeset_search_takes_namespace
        @xml = Nokogiri::XML.parse(<<-eoxml)
<root>
 <car xmlns:part="http://general-motors.com/">
  <part:tire>Michelin Model XGV</part:tire>
 </car>
 <bicycle xmlns:part="http://schwinn.com/">
  <part:tire>I'm a bicycle tire!</part:tire>
 </bicycle>
</root>
        eoxml
        set = @xml/'root'
        assert_equal 1, set.length
        bike_tire = set.search('//bike:tire', 'bike' => "http://schwinn.com/")
        assert_equal 1, bike_tire.length
      end

      def test_new_nodeset
        node_set = Nokogiri::XML::NodeSet.new(@xml)
        assert_equal(0, node_set.length)
        node = Nokogiri::XML::Node.new('form', @xml)
        node_set << node
        assert_equal(1, node_set.length)
        assert_equal(node, node_set.last)
      end

      def test_search_on_nodeset
        assert node_set = @xml.search('//employee')
        assert sub_set = node_set.search('.//name')
        assert_equal(node_set.length, sub_set.length)
      end

      def test_negative_index_works
        assert node_set = @xml.search('//employee')
        assert_equal node_set.last, node_set[-1]
      end

      def test_large_negative_index_returns_nil
        assert node_set = @xml.search('//employee')
        assert_nil(node_set[-1 * (node_set.length + 1)])
      end

      def test_node_set_fetches_private_data
        assert node_set = @xml.search('//employee')

        set = node_set
        assert_equal(set[0], set[0])
      end

      def test_node_set_returns_0
        assert node_set = @xml.search('//asdkfjhasdlkfjhaldskfh')
        assert_equal(0, node_set.length)
      end

      def test_wrap
        employees = (@xml/"//employee").wrap("<wrapper/>")
        assert_equal 'wrapper', employees[0].parent.name
        assert_equal 'employee', @xml.search("//wrapper").first.children[0].name
      end
    end
  end
end
