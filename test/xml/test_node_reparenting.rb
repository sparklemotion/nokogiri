require "helper"

module Nokogiri
  module XML
    class TestNodeReparenting < Nokogiri::TestCase

      def setup
        super
        @xml = Nokogiri::XML "<root><a1>First node</a1><a2>Second node</a2><a3>Third node</a3></root>"
      end

      def test_add_child_should_insert_at_end_of_children
        node = Nokogiri::XML::Node.new('x', @xml)
        @xml.root.add_child node
        assert_equal ["a1", "a2", "a3", "x"], @xml.root.children.collect {|n| n.name}
      end

      def test_add_child_fragment_should_insert_fragment_roots_at_end_of_children
        fragment = Nokogiri::XML.fragment("<b1>foo</b1><b2>bar</b2>")
        @xml.root.add_child fragment
        assert_equal ["a1", "a2", "a3", "b1", "b2"], @xml.root.children.collect {|n| n.name}
      end

      def test_chevron_works_as_add_child
        text_node = Nokogiri::XML::Text.new('hello', @xml)
        assert_equal Nokogiri::XML::Node::TEXT_NODE, text_node.type

        @xml.root << text_node

        assert_equal @xml.root.children.last.content, 'hello'
      end

      def test_add_child_already_in_the_document_should_move_the_node
        third_node = @xml.root.children.last
        first_node = @xml.root.children.first

        @xml.root.add_child(first_node)

        assert_equal 2, @xml.root.children.index(first_node)
        assert_equal 1, @xml.root.children.index(third_node)
      end

      def test_add_child_from_other_document_should_remove_from_old_document
        d1 = Nokogiri::XML("<root><item>1</item><item>2</item></root>")
        d2 = Nokogiri::XML("<root><item>3</item><item>4</item></root>")

        d2.at('root').search('item').each do |item|
          d1.at('root').add_child item
        end

        assert_equal 0, d2.search('item').size
        assert_equal 4, d1.search('item').size
      end

      def test_add_child_text_node_should_merge_with_adjacent_text_nodes
        node = @xml.root.children.first
        old_child = node.children.first
        new_child = Nokogiri::XML::Text.new('text', @xml)

        node.add_child new_child

        assert_equal "First nodetext", node.children.first.content
        assert_equal "First nodetext", new_child.content
        assert_equal "First nodetext", old_child.content
      end

      def test_add_child_node_following_sequential_text_nodes_should_have_right_path
        node = @xml.root.children.first
        node.add_child(Nokogiri::XML::Text.new('text', @xml))

        item = node.add_child(Nokogiri::XML::Element.new('item', @xml))

        assert_equal '/root/a1/item', item.path
      end

      def test_add_child_node_with_namespace_should_keep_namespace
        doc   = Nokogiri::XML::Document.new
        item  = Nokogiri::XML::Element.new('item', doc)
        doc.root = item

        entry = Nokogiri::XML::Element.new('entry', doc)
        entry.add_namespace('tlm', 'http://tenderlovemaking.com')
        assert_equal 'http://tenderlovemaking.com', entry.namespaces['xmlns:tlm']
        item.add_child(entry)
        assert_equal 'http://tenderlovemaking.com', entry.namespaces['xmlns:tlm']
      end

      def test_add_child_node_should_inherit_namespace
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

      def test_add_child_node_should_not_inherit_namespace_if_it_has_one
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

      def test_replace_node_should_remove_previous_node_and_insert_new_node
        second_node = @xml.root.children[1]

        new_node = Nokogiri::XML::Node.new('foo', @xml)
        second_node.replace(new_node)

        assert_equal @xml.root.children[1], new_node
        assert_nil second_node.parent
      end

      def test_replace_fragment_should_replace_node_with_fragment_roots
        node = @xml.root.children[1]
        fragment = Nokogiri::XML.fragment("<b1>foo</b1><b2>bar</b2>")
        fc1 = fragment.children[0]
        fc2 = fragment.children[1]

        node.replace fragment

        assert_equal 4, @xml.root.children.length
        assert_equal fc1, @xml.root.children[1]
        assert_equal fc2, @xml.root.children[2]
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
        old_node = @xml.at_css('a1')
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

      def test_add_next_sibling_should_insert_after
        node = Nokogiri::XML::Node.new('x', @xml)
        @xml.root.children[1].add_next_sibling node
        assert_equal ["a1", "a2", "x", "a3"], @xml.root.children.collect {|n| n.name}
      end

      def test_next_equals_should_insert_after
        node = Nokogiri::XML::Node.new('x', @xml)
        @xml.root.children[1].next = node
        assert_equal ["a1", "a2", "x", "a3"], @xml.root.children.collect {|n| n.name}
      end

      def test_add_next_sibling_fragment_should_insert_fragment_roots_after
        fragment = Nokogiri::XML.fragment("<b1>foo</b1><b2>bar</b2>")
        @xml.root.children[1].add_next_sibling fragment
        assert_equal ["a1", "a2", "b1", "b2", "a3"], @xml.root.children.collect {|n| n.name}
      end

      def test_add_next_sibling_text_node_should_merge_with_adjacent_text_nodes
        node = @xml.root.children.first
        text = node.children.first
        new_text = Nokogiri::XML::Text.new('text', @xml)

        text.add_next_sibling new_text

        assert_equal "First nodetext", node.children.first.content
        assert_equal "First nodetext", text.content
        assert_equal "First nodetext", new_text.content
      end

      def test_add_previous_sibling_should_insert_before
        node = Nokogiri::XML::Node.new('x', @xml)
        @xml.root.children[1].add_previous_sibling node
        assert_equal ["a1", "x", "a2", "a3"], @xml.root.children.collect {|n| n.name}
      end

      def test_previous_equals_should_insert_before
        node = Nokogiri::XML::Node.new('x', @xml)
        @xml.root.children[1].previous = node
        assert_equal ["a1", "x", "a2", "a3"], @xml.root.children.collect {|n| n.name}
      end

      def test_add_previous_sibling_fragment_should_insert_fragment_roots_before
        fragment = Nokogiri::XML.fragment("<b1>foo</b1><b2>bar</b2>")
        @xml.root.children[1].add_previous_sibling fragment
        assert_equal ["a1", "b1", "b2", "a2", "a3"], @xml.root.children.collect {|n| n.name}
      end

      def test_add_previous_sibling_text_node_should_merge_with_adjacent_text_nodes
        node = @xml.root.children.first
        text = node.children.first
        new_text = Nokogiri::XML::Text.new('text', @xml)

        text.add_previous_sibling new_text

        assert_equal "textFirst node", node.children.first.content
        assert_equal "textFirst node", text.content
        assert_equal "textFirst node", new_text.content
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
