require "helper"

module Nokogiri
  module XML
    class TestNodeReparenting < Nokogiri::TestCase

      describe "node reparenting methods" do
        before do
          @xml = Nokogiri::XML "<root><a1>First node</a1><a2>Second node</a2><a3>Third node</a3></root>"
          @html = Nokogiri::HTML(<<-eohtml)
            <html>
              <head></head>
              <body>
                <div class='baz'><a href="foo" class="bar">first</a></div>
              </body>
            </html>
          eohtml
        end

        [ :add_child, :add_previous_sibling, :add_next_sibling,
          :inner_html=, :replace ].each do |method|
          describe "##{method}" do
            [:current, :another].each do |which|
              describe "passed a Node in the #{which} document" do
                it "unlinks the Node from its previous position"
                it "inserts the Node in the proper position"
              end
            end
            describe "passed a Node with a Namespace" do
              it "keeps the Namespace"
            end
            describe "given a parent Node with a default and a non-default Namespace" do
              describe "passed an Node without a namespace" do
                it "inserts an Node that inherits the default Namespace"
              end
              describe "passed a Node with a Namespace that matches the parent's non-default Namespace" do
                it "inserts a Node that inherits the matching parent Namespace"
              end
            end
            describe "passed a Text node" do
              it "merges the Text node with adjacent Text nodes"
            end
            describe "passed a markup string" do
              it "inserts the fragment roots in the proper position"
            end
            describe "passed a fragment" do
              it "inserts the fragment roots in the proper position"
            end
            describe "passed a document" do
              it "raises an exception"
            end
          end
        end

        [ [:<<,         :add_child],
          [:after,      :add_next_sibling],
          [:next=,      :add_next_sibling],
          [:before,     :add_previous_sibling],
          [:previous=,  :add_previous_sibling],
          [:content=,   :inner_html=],
          [:swap,       :replace]
        ].each do |method, aliased|
          describe "##{method}" do
            it "is an alias for #{aliased}"
          end
        end

        describe "#before" do
          it "prepends text nodes" do
            assert node = @html.at('//body').children.first
            node.before "some text"
            assert_equal 'some text', @html.at('//body').children[0].content.strip
          end

          it "prepends elements" do
            @html.at('//div').before('<a href="awesome">town</a>')
            assert_equal 'awesome', @html.at('//div').previous['href']
          end
        end

        describe "#after" do
          it "appends text nodes" do
            assert node = @html.at('//body/div')
            node.after "some text"
            assert_equal 'some text', node.next.text.strip
          end

          it "appends elements" do
            @html.at('//div').after('<a href="awesome">town</a>')
            assert_equal 'awesome', @html.at('//div').next['href']
          end
        end

        describe "#inner_html=" do
          it "replaces children with new content" do
            assert div = @html.at('//div')
            div.inner_html = '1<span>2</span>3'
            assert_equal '1',    div.children[0].to_s
            assert_equal 'span', div.children[1].name
            assert_equal '2',    div.children[1].inner_text
            assert_equal '3',    div.children[2].to_s

            div.inner_html = 'testing'
            assert_equal 'testing', div.content
          end
        end

        describe "#add_child" do
          it "appends to children" do
            node = Nokogiri::XML::Node.new('x', @xml)
            @xml.root.add_child node
            assert_equal ["a1", "a2", "a3", "x"], @xml.root.children.collect {|n| n.name}
          end

          describe "given a fragment" do
            it "appends fragment roots to children" do
              fragment = Nokogiri::XML.fragment("<b1>foo</b1><b2>bar</b2>")
              @xml.root.add_child fragment
              assert_equal ["a1", "a2", "a3", "b1", "b2"], @xml.root.children.collect {|n| n.name}
            end
          end

          describe "given a node in the same document" do
            it "moves the node" do
              third_node = @xml.root.children.last
              first_node = @xml.root.children.first

              @xml.root.add_child(first_node)

              assert_equal 2, @xml.root.children.index(first_node)
              assert_equal 1, @xml.root.children.index(third_node)
            end
          end

          describe "given a node in another document" do
            it "removes from old document" do
              d1 = Nokogiri::XML("<root><item>1</item><item>2</item></root>")
              d2 = Nokogiri::XML("<root><item>3</item><item>4</item></root>")

              d2.at('root').search('item').each do |item|
                d1.at('root').add_child item
              end

              assert_equal 0, d2.search('item').size
              assert_equal 4, d1.search('item').size
            end
          end

          describe "given a text node" do
            it "merges with adjacent text nodes" do
              node = @xml.root.children.first
              old_child = node.children.first
              new_child = Nokogiri::XML::Text.new('text', @xml)

              node.add_child new_child

              assert_equal "First nodetext", node.children.first.content
              assert_equal "First nodetext", new_child.content
              assert_equal "First nodetext", old_child.content
            end
          end

          describe "given a new node with a namespace" do
            it "keeps the namespace" do
              doc   = Nokogiri::XML::Document.new
              item  = Nokogiri::XML::Element.new('item', doc)
              doc.root = item

              entry = Nokogiri::XML::Element.new('entry', doc)
              entry.add_namespace('tlm', 'http://tenderlovemaking.com')
              assert_equal 'http://tenderlovemaking.com', entry.namespaces['xmlns:tlm']
              item.add_child(entry)
              assert_equal 'http://tenderlovemaking.com', entry.namespaces['xmlns:tlm']
            end
          end

          describe "given a parent node with a default namespace" do
            before do
              @doc = Nokogiri::XML(<<-eoxml)
                <root xmlns="http://tenderlovemaking.com/">
                  <first>
                  </first>
                </root>
              eoxml
            end

            it "inserts a node that inherits the default namespace" do
              assert node = @doc.at('//xmlns:first')
              child = Nokogiri::XML::Node.new('second', @doc)
              node.add_child(child)
              assert @doc.at('//xmlns:second')
            end
          end

          describe "given a parent node with a non-default namespace" do
            before do
              @doc = Nokogiri::XML(<<-eoxml)
                <root xmlns="http://tenderlovemaking.com/" xmlns:foo="http://flavorjon.es/">
                  <first>
                  </first>
                </root>
              eoxml
            end

            describe "and a child node with a namespace matching the parent's non-default namespace" do
              it "inserts a node that inherits the matching parent namespace" do
                assert node = @doc.at('//xmlns:first')
                child = Nokogiri::XML::Node.new('second', @doc)

                ns = @doc.root.namespace_definitions.detect { |x| x.prefix == "foo" }
                child.namespace = ns

                node.add_child(child)
                assert @doc.at('//foo:second', "foo" => "http://flavorjon.es/")
              end
            end
          end

          it "chevron_works_as_add_child" do
            text_node = Nokogiri::XML::Text.new('hello', @xml)
            assert_equal Nokogiri::XML::Node::TEXT_NODE, text_node.type

            @xml.root << text_node

            assert_equal @xml.root.children.last.content, 'hello'
          end
        end

        describe "#replace" do
          it "removes previous node and insert new node" do
            second_node = @xml.root.children[1]

            new_node = Nokogiri::XML::Node.new('foo', @xml)
            second_node.replace(new_node)

            assert_equal @xml.root.children[1], new_node
            assert_nil second_node.parent
          end

          it "replaces node with fragment roots" do
            node = @xml.root.children[1]
            fragment = Nokogiri::XML.fragment("<b1>foo</b1><b2>bar</b2>")
            fc1 = fragment.children[0]
            fc2 = fragment.children[1]

            node.replace fragment

            assert_equal 4, @xml.root.children.length
            assert_equal fc1, @xml.root.children[1]
            assert_equal fc2, @xml.root.children[2]
          end

          describe "when a document has a default namespace" do
            before do
              @fruits = Nokogiri::XML(<<-eoxml)
                <fruit xmlns="http://fruits.org">
                  <apple />
                </fruit>
              eoxml
            end

            it "inserts a node with default namespaces" do
              apple = @fruits.css('apple').first

              orange = Nokogiri::XML::Node.new('orange', @fruits)
              apple.replace(orange)

              assert_equal orange, @fruits.css('orange').first
            end
          end

          describe "when passed a document" do
            it "raises an exception" do
              new_node = Nokogiri::XML.parse('<foo>bar</foo>')
              old_node = @xml.at_css('a1')
              assert_raises(ArgumentError){ old_node.replace new_node }
            end
          end

          describe "given a node from another document" do
            it "doesn't blow up" do
              xml1 = "<test> <caption>Original caption</caption> </test>"
              xml2 = "<test> <caption>Replacement caption</caption> </test>"
              doc1 = Nokogiri::XML(xml1)
              doc2 = Nokogiri::XML(xml2)
              caption1 = doc1.xpath("//caption")[0]
              caption2 = doc2.xpath("//caption")[0]
              caption1.replace(caption2) # this segfaulted under 1.4.0 and earlier
              assert_equal "Replacement caption", doc1.css("caption").inner_text
            end
          end
        end

        it "add_next_sibling_should_insert_after" do
          node = Nokogiri::XML::Node.new('x', @xml)
          @xml.root.children[1].add_next_sibling node
          assert_equal ["a1", "a2", "x", "a3"], @xml.root.children.collect {|n| n.name}
        end

        it "next_equals_should_insert_after" do
          node = Nokogiri::XML::Node.new('x', @xml)
          @xml.root.children[1].next = node
          assert_equal ["a1", "a2", "x", "a3"], @xml.root.children.collect {|n| n.name}
        end

        it "add_next_sibling_fragment_should_insert_fragment_roots_after" do
          fragment = Nokogiri::XML.fragment("<b1>foo</b1><b2>bar</b2>")
          @xml.root.children[1].add_next_sibling fragment
          assert_equal ["a1", "a2", "b1", "b2", "a3"], @xml.root.children.collect {|n| n.name}
        end

        it "add_next_sibling_text_node_should_merge_with_adjacent_text_nodes" do
          node = @xml.root.children.first
          text = node.children.first
          new_text = Nokogiri::XML::Text.new('text', @xml)

          text.add_next_sibling new_text

          assert_equal "First nodetext", node.children.first.content
          assert_equal "First nodetext", text.content
          assert_equal "First nodetext", new_text.content
        end

        it "add_previous_sibling_should_insert_before" do
          node = Nokogiri::XML::Node.new('x', @xml)
          @xml.root.children[1].add_previous_sibling node
          assert_equal ["a1", "x", "a2", "a3"], @xml.root.children.collect {|n| n.name}
        end

        it "previous_equals_should_insert_before" do
          node = Nokogiri::XML::Node.new('x', @xml)
          @xml.root.children[1].previous = node
          assert_equal ["a1", "x", "a2", "a3"], @xml.root.children.collect {|n| n.name}
        end

        it "add_previous_sibling_fragment_should_insert_fragment_roots_before" do
          fragment = Nokogiri::XML.fragment("<b1>foo</b1><b2>bar</b2>")
          @xml.root.children[1].add_previous_sibling fragment
          assert_equal ["a1", "b1", "b2", "a2", "a3"], @xml.root.children.collect {|n| n.name}
        end

        it "add_previous_sibling_text_node_should_merge_with_adjacent_text_nodes" do
          node = @xml.root.children.first
          text = node.children.first
          new_text = Nokogiri::XML::Text.new('text', @xml)

          text.add_previous_sibling new_text

          assert_equal "textFirst node", node.children.first.content
          assert_equal "textFirst node", text.content
          assert_equal "textFirst node", new_text.content
        end

        describe "unlinking a node and then reparenting it" do
          it "not blow up" do
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
  end
end
