require "helper"

module Nokogiri
  module XML
    class TestNodeReparenting < Nokogiri::TestCase

      def setup
        super
        @xml = Nokogiri::XML(File.read(XML_FILE), XML_FILE)
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

      def test_add_child_in_same_document
        child = @xml.css('employee').first

        assert previous_last_child = child.children.last
        assert new_child = child.children.first

        last = child.children.last

        child.add_child(new_child)
        assert_equal new_child, child.children.last
        assert_equal last, child.children.last
      end

      def test_add_child_from_other_document
        d1 = Nokogiri::XML("<root><item>1</item><item>2</item></root>")
        d2 = Nokogiri::XML("<root><item>3</item><item>4</item></root>")

        d2.at('root').search('item').each do |i|
          d1.at('root').add_child i
        end

        assert_equal 0, d2.search('item').size
        assert_equal 4, d1.search('item').size
      end

      def test_add_child_path_following_sequential_text_nodes
        xml = Nokogiri::XML('<root>text</root>')
        xml.root.add_child(Nokogiri::XML::Text.new('text', xml))
        item = xml.root.add_child(Nokogiri::XML::Element.new('item', xml))
        assert_equal '/root/item', item.path
      end

      def test_add_namespace_add_child
        doc   = Nokogiri::XML::Document.new
        item  = Nokogiri::XML::Element.new('item', doc)
        doc.root = item

        entry = Nokogiri::XML::Element.new('entry', doc)
        entry.add_namespace('tlm', 'http://tenderlovemaking.com')
        assert_equal 'http://tenderlovemaking.com', entry.namespaces['xmlns:tlm']
        item.add_child(entry)
        assert_equal 'http://tenderlovemaking.com', entry.namespaces['xmlns:tlm']
      end

      def test_add_child_should_inherit_namespace
        doc = Nokogiri::XML(<<-eoxml)
          <root xmlns="http://tenderlovemaking.com/">
            <first>
            </first>
          </root>
        eoxml
        assert node = doc.at('//xmlns:first')
        child = Nokogiri::XML::Node.new('second', doc)
        node.add_child(child)
        assert doc.at('//xmlns:second')
      end

      def test_add_child_should_not_inherit_namespace_if_it_has_one
        doc = Nokogiri::XML(<<-eoxml)
          <root xmlns="http://tenderlovemaking.com/" xmlns:foo="http://flavorjon.es/">
            <first>
            </first>
          </root>
        eoxml
        assert node = doc.at('//xmlns:first')
        child = Nokogiri::XML::Node.new('second', doc)

        ns = doc.root.namespace_definitions.detect { |x| x.prefix == "foo" }
        child.namespace = ns

        node.add_child(child)
        assert doc.at('//foo:second', "foo" => "http://flavorjon.es/")
      end

      def test_replace
        set = @xml.search('//employee')
        assert 5, set.length
        assert 0, @xml.search('//form').length

        first = set[0]
        second = set[1]

        node = Nokogiri::XML::Node.new('form', @xml)
        first.replace(node)

        assert set = @xml.search('//employee')
        assert_equal 4, set.length
        assert 1, @xml.search('//form').length

        assert_equal set[0].to_xml, second.to_xml
      end

      def test_replace_with_default_namespaces
        fruits = Nokogiri::XML(<<-eoxml)
          <fruit xmlns="http://fruits.org">
            <apple />
          </fruit>
        eoxml

        apple = fruits.css('apple').first

        orange = Nokogiri::XML::Node.new('orange', fruits)
        apple.replace(orange)

        assert_equal orange, fruits.css('orange').first
      end

      def test_illegal_replace_of_node_with_doc
        new_node = Nokogiri::XML.parse('<foo>bar</foo>')
        old_node = @xml.at('//employee')
        assert_raises(ArgumentError){ old_node.replace new_node }
      end

      def test_replace_with_node_from_different_docs
        xml1 = "<test> <caption>Original caption</caption> </test>"
        xml2 = "<test> <caption>Replacement caption</caption> </test>"
        doc1 = Nokogiri::XML(xml1)
        doc2 = Nokogiri::XML(xml2)
        caption1 = doc1.xpath("//caption")[0]
        caption2 = doc2.xpath("//caption")[0]
        caption1.replace(caption2) # this segfaulted under 1.4.0 and earlier
        assert_equal "Replacement caption", doc1.css("caption").inner_text
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

      def test_unlink_then_reparent
        # see http://github.com/tenderlove/nokogiri/issues#issue/22
        10.times do
          STDOUT.putc "."
          STDOUT.flush
          begin
            doc = Nokogiri::XML <<-EOHTML
              <root>
                <a>
                  <b/>
                  <c/>
                </a>
              </root>
            EOHTML

            root = doc.at("root")
            a = root.at("a")
            b = a.at("b")
            c = a.at("c")
            a.add_next_sibling(b.unlink)
            c.unlink
          end
          GC.start
        end
      end

    end
  end
end
