require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestNode < Nokogiri::TestCase
      def test_ancestors
        xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        address = xml.xpath('//address').first
        assert_equal 3, address.ancestors.length
        assert_equal ['employee', 'staff', nil],
          address.ancestors.map { |x| x.name }
      end

      def test_remove_attribute
        xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        address = xml.xpath('/staff/employee/address').first
        assert_equal 'Yes', address['domestic']
        address.remove_attribute 'domestic'
        assert_nil address['domestic']
      end

      def test_delete
        xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        address = xml.xpath('/staff/employee/address').first
        assert_equal 'Yes', address['domestic']
        address.delete 'domestic'
        assert_nil address['domestic']
      end

      def test_angry_add_child
        xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        child = xml.css('employee').first

        assert new_child = child.children.first

        last = child.children.last

        # Magic!  Don't try this at home folks
        child.add_child(new_child)
        assert_equal new_child, child.children.last
        assert_equal last, child.children.last
      end

      def test_add_child
        xml = Nokogiri::XML(<<-eoxml)
        <root>
          <a>Hello world</a>
        </root>
        eoxml
        text_node = Nokogiri::XML::Text.new('hello', xml)
        assert_equal Nokogiri::XML::Node::TEXT_NODE, text_node.type
        xml.root.add_child text_node
        assert_match 'hello', xml.to_s
      end

      def test_chevron_works_as_add_child
        xml = Nokogiri::XML(<<-eoxml)
        <root>
          <a>Hello world</a>
        </root>
        eoxml
        text_node = Nokogiri::XML::Text.new('hello', xml)
        xml.root << text_node
        assert_match 'hello', xml.to_s
      end

      def test_add_previous_sibling
        xml = Nokogiri::XML(<<-eoxml)
        <root>
          <a>Hello world</a>
        </root>
        eoxml
        b_node = Nokogiri::XML::Node.new('a', xml)
        assert_equal Nokogiri::XML::Node::ELEMENT_NODE, b_node.type
        b_node.content = 'first'
        a_node = xml.xpath('//a').first
        a_node.add_previous_sibling(b_node)
        assert_equal('first', xml.xpath('//a').first.text)
      end

      def test_add_previous_sibling_merge
        xml = Nokogiri::XML(<<-eoxml)
        <root>
          <a>Hello world</a>
        </root>
        eoxml

        assert a_tag = xml.css('a').first

        left_space = a_tag.previous
        right_space = a_tag.next
        assert left_space.text?
        assert right_space.text?

        left_space.add_previous_sibling(right_space)
        assert_equal left_space, right_space
      end

      def test_add_next_sibling_merge
        xml = Nokogiri::XML(<<-eoxml)
        <root>
          <a>Hello world</a>
        </root>
        eoxml

        assert a_tag = xml.css('a').first

        left_space = a_tag.previous
        right_space = a_tag.next
        assert left_space.text?
        assert right_space.text?

        right_space.add_next_sibling(left_space)
        assert_equal left_space, right_space
      end

      def test_find_by_css_with_tilde_eql
        xml = Nokogiri::XML.parse(<<-eoxml)
        <root>
          <a>Hello world</a>
          <a class='foo bar'>Bar</a>
          <a class='bar foo'>Bar</a>
          <a class='bar'>Bar</a>
          <a class='baz bar foo'>Bar</a>
          <a class='bazbarfoo'>Awesome</a>
          <a class='bazbar'>Awesome</a>
        </root>
        eoxml
        set = xml.css('a[@class~="bar"]')
        assert_equal 4, set.length
        assert_equal ['Bar'], set.map { |node| node.content }.uniq
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
        node = xml.xpath('//a')[3]
        assert_equal('Hello world', node.text)
        assert_match(/Hello world/, xml.to_s)
        assert node.parent
        assert node.document
        assert node.previous_sibling
        assert node.next_sibling
        node.unlink
        assert !node.parent
        # assert !node.document # ugh. libxml doesn't clear node->doc pointer, due to xmlDict implementation.
        assert !node.previous_sibling
        assert !node.next_sibling
        assert_no_match(/Hello world/, xml.to_s)
      end

      def test_dup_shallow
        html = Nokogiri::HTML.parse(File.read(HTML_FILE), HTML_FILE)
        found = html.search('//div/a').first
        dup = found.dup(0)
        assert dup
        assert_equal '', dup.content
      end

      def test_dup
        html = Nokogiri::HTML.parse(File.read(HTML_FILE), HTML_FILE)
        found = html.search('//div/a').first
        dup = found.dup
        assert dup
        assert_equal found.content, dup.content
      end

      def test_search_can_handle_xpath_and_css
        html = Nokogiri::HTML.parse(File.read(HTML_FILE), HTML_FILE)
        found = html.search('//div/a', 'div > p')
        length = html.xpath('//div/a').length +
          html.css('div > p').length
        assert_equal length, found.length
      end

      def test_find_by_xpath
        html = Nokogiri::HTML.parse(File.read(HTML_FILE), HTML_FILE)
        found = html.xpath('//div/a')
        assert_equal 3, found.length
      end

      def test_find_by_css
        html = Nokogiri::HTML.parse(File.read(HTML_FILE), HTML_FILE)
        found = html.css('div > a')
        assert_equal 3, found.length
      end

      def test_next_sibling
        xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        assert node = xml.root
        assert sibling = node.child.next_sibling
        assert_equal('employee', sibling.name)
      end

      def test_previous_sibling
        xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        assert node = xml.root
        assert sibling = node.child.next_sibling
        assert_equal('employee', sibling.name)
        assert_equal(sibling.previous_sibling, node.child)
      end

      def test_name=
        xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        assert node = xml.root
        node.name = 'awesome'
        assert_equal('awesome', node.name)
      end

      def test_child
        xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        assert node = xml.root
        assert child = node.child
        assert_equal('text', child.name)
      end

      def test_key?
        xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        assert node = xml.search('//address').first
        assert(!node.key?('asdfasdf'))
      end

      def test_set_property
        xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        assert node = xml.search('//address').first
        node['foo'] = 'bar'
        assert_equal('bar', node['foo'])
      end

      def test_attributes
        xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        assert node = xml.search('//address').first
        assert_nil(node['asdfasdfasdf'])
        assert_equal('Yes', node['domestic'])

        assert node = xml.search('//address')[2]
        attr = node.attributes
        assert_equal 2, attr.size
        assert_equal 'Yes', attr['domestic'].value
        assert_equal 'Yes', attr['domestic'].to_s
        assert_equal 'No', attr['street'].value
      end

      def test_path
        xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        assert set = xml.search('//employee')
        assert node = set.first
        assert_equal('/staff/employee[1]', node.path)
      end

      def test_search_by_symbol
        xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        assert set = xml.search(:employee)
        assert 5, set.length

        assert node = xml.at(:employee)
        assert node.text =~ /EMP0001/
      end

      def test_new_node
        xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
        node = Nokogiri::XML::Node.new('form', xml)
        assert_equal('form', node.name)
        assert(node.document)
      end

      def test_content
        xml = Nokogiri::XML.parse(File.read(XML_FILE))
        node = Nokogiri::XML::Node.new('form', xml)
        assert_equal('', node.content)

        node.content = 'hello world!'
        assert_equal('hello world!', node.content)
      end

      def test_whitespace_nodes
        doc = Nokogiri::XML.parse("<root><b>Foo</b>\n<i>Bar</i> <p>Bazz</p></root>")
        children = doc.at('//root').children.collect{|j| j.to_s}
        assert_equal "\n", children[1]
        assert_equal " ", children[3]
      end

      def test_replace
        xml = Nokogiri::XML.parse(File.read(XML_FILE))
        set = xml.search('//employee')
        assert 5, set.length
        assert 0, xml.search('//form').length

        first = set[0]
        second = set[1]

        node = Nokogiri::XML::Node.new('form', xml)
        first.replace(node)

        assert set = xml.search('//employee')
        assert_equal 4, set.length
        assert 1, xml.search('//form').length

        assert_equal set[0].to_xml, second.to_xml
        assert_equal set[0].to_xml(5), second.to_xml(5)
        assert_not_equal set[0].to_xml, set[0].to_xml(5)
      end

      def test_illegal_replace_of_node_with_doc
        xml = Nokogiri::XML.parse(File.read(XML_FILE))
        new_node = Nokogiri::XML.parse('<foo>bar</foo>')
        old_node = xml.at('//employee')
        assert_raises(ArgumentError){ old_node.replace new_node }
      end

      def test_namespace_as_hash
        xml = Nokogiri::XML.parse(<<-eoxml)
<root>
 <car xmlns:part="http://general-motors.com/">
  <part:tire>Michelin Model XGV</part:tire>
 </car>
 <bicycle xmlns:part="http://schwinn.com/">
  <part:tire>I'm a bicycle tire!</part:tire>
 </bicycle>
</root>
        eoxml

        tires = xml.xpath('//bike:tire', {'bike' => 'http://schwinn.com/'})
        assert_equal 1, tires.length
      end

      def test_namespaces
        xml = Nokogiri::XML.parse(<<-EOF)
<x xmlns:a='http://foo.com/' xmlns:b='http://bar.com/'>
  <y xmlns:c='http://bazz.com/'>
    <a:div>hello a</a:div>
    <b:div>hello b</b:div>
    <c:div>hello c</c:div>
  </y>  
</x>
EOF
        assert namespaces = xml.root.namespaces
        assert namespaces.key?('xmlns:a')
        assert_equal 'http://foo.com/', namespaces['xmlns:a']
        assert namespaces.key?('xmlns:b')
        assert_equal 'http://bar.com/', namespaces['xmlns:b']
        assert ! namespaces.key?('xmlns:c')

        assert namespaces = xml.namespaces
        assert namespaces.key?('xmlns:a')
        assert_equal 'http://foo.com/', namespaces['xmlns:a']
        assert namespaces.key?('xmlns:b')
        assert_equal 'http://bar.com/', namespaces['xmlns:b']
        assert namespaces.key?('xmlns:c')
        assert_equal 'http://bazz.com/', namespaces['xmlns:c']

        assert_equal "hello a", xml.search("//a:div", xml.namespaces).first.inner_text
        assert_equal "hello b", xml.search("//b:div", xml.namespaces).first.inner_text
        assert_equal "hello c", xml.search("//c:div", xml.namespaces).first.inner_text
      end

      def test_namespace
        xml = Nokogiri::XML.parse(<<-EOF)
<x xmlns:a='http://foo.com/' xmlns:b='http://bar.com/'>
  <y xmlns:c='http://bazz.com/'>
    <a:div>hello a</a:div>
    <b:div>hello b</b:div>
    <c:div>hello c</c:div>
    <div>hello moon</div>
  </y>  
</x>
EOF
        set = xml.search("//y/*")
        assert_equal "a", set[0].namespace
        assert_equal "b", set[1].namespace
        assert_equal "c", set[2].namespace
        assert_equal nil, set[3].namespace
      end

    end
  end
end
