# frozen_string_literal: true

require "helper"

module Nokogiri
  module XML
    class TestNodeReparenting < Nokogiri::TestCase
      describe "standard node reparenting behavior" do
        # describe "namespace handling during reparenting" do
        #   describe "given a Node" do
        #     describe "with a Namespace" do
        #       it "keeps the Namespace"
        #     end
        #     describe "given a parent Node with a default and a non-default Namespace" do
        #       describe "passed an Node without a namespace" do
        #         it "inserts an Node that inherits the default Namespace"
        #       end
        #       describe "passed a Node with a Namespace that matches the parent's non-default Namespace" do
        #         it "inserts a Node that inherits the matching parent Namespace"
        #       end
        #     end
        #   end
        #   describe "given a markup string" do
        #     describe "parsed relative to the document" do
        #       describe "with a Namespace" do
        #         it "keeps the Namespace"
        #       end
        #       describe "given a parent Node with a default and a non-default Namespace" do
        #         describe "passed an Node without a namespace" do
        #           it "inserts an Node that inherits the default Namespace"
        #         end
        #         describe "passed a Node with a Namespace that matches the parent's non-default Namespace" do
        #           it "inserts a Node that inherits the matching parent Namespace"
        #         end
        #       end
        #     end
        #     describe "parsed relative to a specific node" do
        #       describe "with a Namespace" do
        #         it "keeps the Namespace"
        #       end
        #       describe "given a parent Node with a default and a non-default Namespace" do
        #         describe "passed an Node without a namespace" do
        #           it "inserts an Node that inherits the default Namespace"
        #         end
        #         describe "passed a Node with a Namespace that matches the parent's non-default Namespace" do
        #           it "inserts a Node that inherits the matching parent Namespace"
        #         end
        #       end
        #     end
        #   end
        # end

        before do
          @doc = Nokogiri::XML("<root><a1>First node</a1><a2>Second node</a2><a3>Third <bx />node</a3></root>")
          @doc2 = @doc.dup
          @fragment_string = "<b1>foo</b1><b2>bar</b2>"
          @fragment = Nokogiri::XML::DocumentFragment.parse(@fragment_string)
          @node_set = Nokogiri::XML("<root><b1>foo</b1><b2>bar</b2></root>").xpath("/root/node()")
        end

        {
          :add_child => { target: "/root/a1", returns_self: false, children_tags: ["text", "b1", "b2"] },
          :<< => { target: "/root/a1", returns_self: true, children_tags: ["text", "b1", "b2"] },

          :replace => { target: "/root/a1/node()", returns_self: false, children_tags: ["b1", "b2"] },
          :swap => { target: "/root/a1/node()", returns_self: true, children_tags: ["b1", "b2"] },

          :children= => { target: "/root/a1", children_tags: ["b1", "b2"] },
          :inner_html= => { target: "/root/a1", children_tags: ["b1", "b2"] },

          :add_previous_sibling => { target: "/root/a1/text()", returns_self: false, children_tags: ["b1", "b2", "text"] },
          :previous= => { target: "/root/a1/text()", children_tags: ["b1", "b2", "text"] },
          :before => { target: "/root/a1/text()", returns_self: true, children_tags: ["b1", "b2", "text"] },

          :add_next_sibling => { target: "/root/a1/text()", returns_self: false, children_tags: ["text", "b1", "b2"] },
          :next= => { target: "/root/a1/text()", children_tags: ["text", "b1", "b2"] },
          :after => { target: "/root/a1/text()", returns_self: true, children_tags: ["text", "b1", "b2"] },
        }.each do |method, params|
          describe "##{method}" do
            describe "passed a Node" do
              [:current, :another].each do |which|
                describe "passed a Node in the #{which} document" do
                  before do
                    @other_doc = which == :current ? @doc : @doc2
                    @other_node = @other_doc.at_xpath("/root/a2")
                  end

                  it "unlinks the Node from its previous position" do
                    @doc.at_xpath(params[:target]).send(method, @other_node)
                    result = @other_doc.at_xpath("/root/a2")
                    assert_nil(result)
                  end

                  it "inserts the Node in the proper position" do
                    @doc.at_xpath(params[:target]).send(method, @other_node)
                    result = @doc.at_xpath("/root/a1/a2")
                    refute_nil(result)
                  end

                  it "returns the expected value" do
                    sendee = @doc.at_xpath(params[:target])
                    result = sendee.send(method, @other_node)
                    if !params.key?(:returns_self)
                      assert(method.to_s.end_with?("="))
                    elsif params[:returns_self]
                      assert_equal(sendee, result)
                    else
                      assert_equal(@other_node, result)
                    end
                  end
                end
              end
            end
            describe "passed a markup string" do
              it "inserts the fragment roots in the proper position" do
                @doc.at_xpath(params[:target]).send(method, @fragment_string)
                result = @doc.xpath("/root/a1/node()").collect(&:name)
                assert_equal(params[:children_tags], result)
              end

              it "returns the expected value" do
                sendee = @doc.at_xpath(params[:target])
                result = sendee.send(method, @fragment_string)
                if !params.key?(:returns_self)
                  assert(method.to_s.end_with?("="))
                elsif params[:returns_self]
                  assert_equal(sendee, result)
                else
                  assert_kind_of(Nokogiri::XML::NodeSet, result)
                  assert_equal(@fragment_string, result.to_html)
                end
              end
            end
            describe "passed a fragment" do
              it "inserts the fragment roots in the proper position" do
                @doc.at_xpath(params[:target]).send(method, @fragment)
                result = @doc.xpath("/root/a1/node()").collect(&:name)
                assert_equal(params[:children_tags], result)
              end
            end
            describe "passed a document" do
              it "raises an exception" do
                assert_raises(ArgumentError) { @doc.at_xpath("/root/a1").send(method, @doc2) }
              end
            end
            describe "passed a non-Node" do
              it "raises an exception" do
                assert_raises(ArgumentError) { @doc.at_xpath("/root/a1").send(method, 42) }
              end
            end
            describe "passed a NodeSet" do
              it "inserts each member of the NodeSet in the proper order" do
                @doc.at_xpath(params[:target]).send(method, @node_set)
                result = @doc.xpath("/root/a1/node()").collect(&:name)
                assert_equal(params[:children_tags], result)
              end
            end
          end
        end

        describe "text node merging" do
          describe "#add_child" do
            it "merges the Text node with adjacent Text nodes" do
              @doc.at_xpath("/root/a1").add_child(Nokogiri::XML::Text.new("hello", @doc))
              result = @doc.at_xpath("/root/a1/text()").content
              assert_equal("First nodehello", result)
            end
          end

          describe "#replace" do
            it "merges the Text node with adjacent Text nodes" do
              @doc.at_xpath("/root/a3/bx").replace(Nokogiri::XML::Text.new("hello", @doc))
              result = @doc.at_xpath("/root/a3/text()").content
              assert_equal("Third hellonode", result)
            end
          end
        end

        describe "in-context parsing" do
          specs = {
            :add_child => :self,
            :<< => :self,

            :replace => :parent,
            :swap => :parent,

            :children= => :self,
            :inner_html= => :self,

            :add_previous_sibling => :parent,
            :previous= => :parent,
            :before => :parent,

            :add_next_sibling => :parent,
            :next= => :parent,
            :after => :parent,
          }

          specs.each do |method, which|
            describe "##{method} parsing input" do
              let(:xml) do
                <<~EOF
                  <root>
                    <parent><context></context></parent>
                  </root>
                EOF
              end

              let(:doc) { Nokogiri::XML::Document.parse(xml) }
              let(:context_node) { doc.at_css("context") }

              describe "with a parent" do
                let(:expected_callee) do
                  if which == :self
                    context_node
                  elsif which == :parent
                    context_node.parent
                  else
                    raise("unable to discern what the test means by #{which}")
                  end
                end

                before do
                  class << expected_callee
                    attr_reader :coerce_was_called

                    def coerce(data)
                      @coerce_was_called = true
                      super
                    end
                  end
                end

                it "in context of #{which}" do
                  context_node.__send__(method, "<child>content</child>")

                  assert expected_callee.coerce_was_called, "expected coerce to be called on #{which}"
                end
              end

              if which == :parent
                describe "without a parent" do
                  before { context_node.unlink }

                  it "raises an exception" do
                    ex = assert_raises(RuntimeError) do
                      context_node.__send__(method, "<child>content</child>")
                    end
                    assert_match(/no parent/, ex.message)
                  end
                end
              end
            end
          end
        end
      end

      describe "ad hoc node reparenting behavior" do
        describe "#<<" do
          it "allows chaining" do
            doc = Nokogiri::XML::Document.new
            root = Nokogiri::XML::Element.new("root", doc)
            doc.root = root

            child1 = Nokogiri::XML::Element.new("child1", doc)
            child2 = Nokogiri::XML::Element.new("child2", doc)

            doc.root << child1 << child2

            assert_equal [child1, child2], doc.root.children.to_a
          end
        end

        describe "#add_child" do
          describe "given a new node with a namespace" do
            it "keeps the namespace" do
              doc = Nokogiri::XML::Document.new
              item = Nokogiri::XML::Element.new("item", doc)
              doc.root = item

              entry = Nokogiri::XML::Element.new("entry", doc)
              entry.add_namespace("tlm", "http://tenderlovemaking.com")
              assert_equal "http://tenderlovemaking.com", entry.namespaces["xmlns:tlm"]
              item.add_child(entry)
              assert_equal "http://tenderlovemaking.com", entry.namespaces["xmlns:tlm"]
            end
          end

          describe "given the new document is empty" do
            it "adds the node to the new document" do
              doc1 = Nokogiri::XML.parse("<value>3</value>")
              doc2 = Nokogiri::XML::Document.new
              node = doc1.at_xpath("//value")
              node.remove
              doc2.add_child(node)
              assert_match(%r{<value>3</value>}, doc2.to_xml)
            end
          end

          describe "given a parent node with a default namespace" do
            before do
              @doc = Nokogiri::XML(<<~eoxml)
                <root xmlns="http://tenderlovemaking.com/">
                  <first>
                  </first>
                </root>
              eoxml
            end

            it "inserts a node that inherits the default namespace" do
              assert node = @doc.at("//xmlns:first")
              child = Nokogiri::XML::Node.new("second", @doc)
              node.add_child(child)
              assert @doc.at("//xmlns:second")
            end

            describe "and a child node was added to a new doc with the a different namespace using the same prefix" do
              before do
                @doc = Nokogiri::XML(%{<root xmlns:bar="http://tenderlovemaking.com/"><bar:first/></root>})
                new_doc = Nokogiri::XML(%{<newroot xmlns:bar="http://flavorjon.es/"/>})
                assert node = @doc.at("//tenderlove:first", tenderlove: "http://tenderlovemaking.com/")
                new_doc.root.add_child(node)
                @doc = new_doc
              end

              it "serializes the doc with the proper default namespace" do
                assert_match(%r{<bar:first\ xmlns:bar="http://tenderlovemaking.com/"/>}, @doc.to_xml)
              end
            end

            describe "and a child node was added to a new doc with the same default namespaces" do
              before do
                new_doc = Nokogiri::XML(%{<newroot xmlns="http://tenderlovemaking.com/"/>})
                assert node = @doc.at("//tenderlove:first", tenderlove: "http://tenderlovemaking.com/")
                new_doc.root.add_child(node)
                @doc = new_doc
              end

              it "serializes the doc with the proper default namespace" do
                assert_match(/<first>/, @doc.to_xml)
              end
            end

            describe "and a child node was added to a new doc without any default namespaces" do
              before do
                new_doc = Nokogiri::XML("<newroot/>")
                assert node = @doc.at("//tenderlove:first", tenderlove: "http://tenderlovemaking.com/")
                new_doc.root.add_child(node)
                @doc = new_doc
              end

              it "serializes the doc with the proper default namespace" do
                assert_match(%r{<first xmlns=\"http://tenderlovemaking.com/\">}, @doc.to_xml)
              end
            end

            describe "and a child node became the root of a new doc" do
              before do
                new_doc = Nokogiri::XML::Document.new
                assert node = @doc.at("//tenderlove:first", tenderlove: "http://tenderlovemaking.com/")
                new_doc.root = node
                @doc = new_doc
              end

              it "serializes the doc with the proper default namespace" do
                assert_match(%r{<first xmlns=\"http://tenderlovemaking.com/\">}, @doc.to_xml)
              end
            end

            describe "and a child node has a namespaced attribute" do
              # https://github.com/sparklemotion/nokogiri/issues/2228
              it "should not lose attribute namespace" do
                source_doc = Nokogiri::XML::Document.parse(<<~EOXML)
                  <pre1:root xmlns:pre1="ns1" xmlns:pre2="ns2">
                    <pre1:child pre2:attr="attrval">
                  </pre1:root>
                EOXML
                assert(source_node = source_doc.at_xpath("//pre1:child", { "pre1" => "ns1" }))
                assert_equal("attrval", source_node.attribute_with_ns("attr", "ns2")&.value)

                dest_doc = Nokogiri::XML::Document.parse(<<~EOXML)
                  <pre1:root xmlns:pre1="ns1" xmlns:pre2="ns2">
                  </pre1:root>
                EOXML
                assert(dest_node = dest_doc.at_xpath("//pre1:root", { "pre1" => "ns1" }))

                inserted = dest_node.add_child(source_node)

                assert_equal(
                  "attrval",
                  inserted.attribute_with_ns("attr", "ns2")&.value,
                  "inserted node attribute should be namespaced",
                )
              end
            end
          end

          describe "given a parent node with a default and non-default namespace" do
            before do
              @doc = Nokogiri::XML(<<~eoxml)
                <root xmlns="http://tenderlovemaking.com/" xmlns:foo="http://flavorjon.es/">
                  <first>
                  </first>
                </root>
              eoxml
              assert @node = @doc.at("//xmlns:first")
              @child = Nokogiri::XML::Node.new("second", @doc)
            end

            describe "and a child with a namespace matching the parent's default namespace" do
              describe "and as the default prefix" do
                before do
                  @ns = @child.add_namespace(nil, "http://tenderlovemaking.com/")
                  @child.namespace = @ns
                end

                it "inserts a node that inherits the parent's default namespace" do
                  @node.add_child(@child)
                  assert reparented = @doc.at("//bar:second", "bar" => "http://tenderlovemaking.com/")
                  assert_empty reparented.namespace_definitions
                  assert_equal @doc.root.namespace, reparented.namespace
                  assert_equal(
                    {
                      "xmlns" => "http://tenderlovemaking.com/",
                      "xmlns:foo" => "http://flavorjon.es/",
                    },
                    reparented.namespaces,
                  )
                end
              end

              describe "but with a different prefix" do
                before do
                  @ns = @child.add_namespace("baz", "http://tenderlovemaking.com/")
                  @child.namespace = @ns
                end

                it "inserts a node that uses its own namespace" do
                  @node.add_child(@child)
                  assert reparented = @doc.at("//bar:second", "bar" => "http://tenderlovemaking.com/")
                  assert_includes reparented.namespace_definitions, @ns
                  assert_equal @ns, reparented.namespace
                  assert_equal(
                    {
                      "xmlns" => "http://tenderlovemaking.com/",
                      "xmlns:foo" => "http://flavorjon.es/",
                      "xmlns:baz" => "http://tenderlovemaking.com/",
                    },
                    reparented.namespaces,
                  )
                end
              end
            end

            describe "and a child with a namespace matching the parent's non-default namespace" do
              before do
                @root_ns = @doc.root.namespace_definitions.detect { |x| x.prefix == "foo" }
              end

              describe "set by #namespace=" do
                before do
                  @child.namespace = @root_ns
                end

                it "inserts a node that inherits the matching parent namespace" do
                  @node.add_child(@child)
                  assert reparented = @doc.at("//bar:second", "bar" => "http://flavorjon.es/")
                  assert_empty reparented.namespace_definitions
                  assert_equal @root_ns, reparented.namespace
                  assert_equal(
                    {
                      "xmlns" => "http://tenderlovemaking.com/",
                      "xmlns:foo" => "http://flavorjon.es/",
                    },
                    reparented.namespaces,
                  )
                end
              end

              describe "with the same prefix" do
                before do
                  @ns = @child.add_namespace("foo", "http://flavorjon.es/")
                  @child.namespace = @ns
                end

                it "inserts a node that uses the parent's namespace" do
                  @node.add_child(@child)
                  assert reparented = @doc.at("//bar:second", "bar" => "http://flavorjon.es/")
                  assert_empty reparented.namespace_definitions
                  assert_equal @root_ns, reparented.namespace
                  assert_equal(
                    {
                      "xmlns" => "http://tenderlovemaking.com/",
                      "xmlns:foo" => "http://flavorjon.es/",
                    },
                    reparented.namespaces,
                  )
                end
              end

              describe "as the default prefix" do
                before do
                  @ns = @child.add_namespace(nil, "http://flavorjon.es/")
                  @child.namespace = @ns
                end

                it "inserts a node that keeps its namespace" do
                  @node.add_child(@child)
                  assert reparented = @doc.at("//bar:second", "bar" => "http://flavorjon.es/")
                  assert_includes reparented.namespace_definitions, @ns
                  assert_equal @ns, reparented.namespace
                  assert_equal(
                    {
                      "xmlns" => "http://flavorjon.es/",
                      "xmlns:foo" => "http://flavorjon.es/",
                    },
                    reparented.namespaces,
                  )
                end
              end

              describe "but with a different prefix" do
                before do
                  @ns = @child.add_namespace("baz", "http://flavorjon.es/")
                  @child.namespace = @ns
                end

                it "inserts a node that keeps its namespace" do
                  @node.add_child(@child)
                  assert reparented = @doc.at("//bar:second", "bar" => "http://flavorjon.es/")
                  assert_includes reparented.namespace_definitions, @ns
                  assert_equal @ns, reparented.namespace
                  assert_equal(
                    {
                      "xmlns" => "http://tenderlovemaking.com/",
                      "xmlns:foo" => "http://flavorjon.es/",
                      "xmlns:baz" => "http://flavorjon.es/",
                    },
                    reparented.namespaces,
                  )
                end
              end
            end

            describe "and a child node with a default namespace not matching the parent's default namespace and a namespace matching a parent namespace but with a different prefix" do
              before do
                @ns = @child.add_namespace(nil, "http://example.org/")
                @child.namespace = @ns
                @ns2 = @child.add_namespace("baz", "http://tenderlovemaking.com/")
              end

              it "inserts a node that keeps its namespace" do
                @node.add_child(@child)
                assert reparented = @doc.at("//bar:second", "bar" => "http://example.org/")
                assert_includes reparented.namespace_definitions, @ns
                assert_includes reparented.namespace_definitions, @ns2
                assert_equal @ns, reparented.namespace
                assert_equal(
                  {
                    "xmlns" => "http://example.org/",
                    "xmlns:foo" => "http://flavorjon.es/",
                    "xmlns:baz" => "http://tenderlovemaking.com/",
                  },
                  reparented.namespaces,
                )
              end
            end
          end

          describe "given a parent node with a non-default namespace" do
            let(:doc) do
              Nokogiri::XML(<<~EOF)
                <root xmlns:foo="http://nokogiri.org/default_ns/test/foo">
                  <foo:parent>
                  </foo:parent>
                </root>
              EOF
            end
            let(:parent) { doc.at_xpath("//foo:parent", "foo" => "http://nokogiri.org/default_ns/test/foo") }

            describe "and namespace_inheritance is off" do
              it "inserts a child node that does not inherit the parent's namespace" do
                refute(doc.namespace_inheritance)
                child = parent.add_child("<child></child>").first
                assert_nil(child.namespace)
              end
            end

            describe "and namespace_inheritance is on" do
              it "inserts a child node that inherits the parent's namespace" do
                doc.namespace_inheritance = true
                child = parent.add_child("<child></child>").first
                refute_nil(child.namespace)
                assert_equal("http://nokogiri.org/default_ns/test/foo", child.namespace.href)
              end
            end
          end
        end

        describe "#add_previous_sibling" do
          it "should not merge text nodes during the operation" do
            xml = Nokogiri::XML(%(<root>text node</root>))
            replacee = xml.root.children.first
            replacee.add_previous_sibling("foo <p></p> bar")
            assert_equal "foo <p></p> bartext node", xml.root.children.to_html
          end

          it "should remove the child node after the operation" do
            fragment = Nokogiri::HTML4::DocumentFragment.parse("a<a>b</a>")
            node = fragment.children.last
            node.add_previous_sibling(node.children)
            assert_empty node.children, "should have no childrens"
          end

          describe "with a text node before" do
            it "should not defensively dup the 'before' text node" do
              xml = Nokogiri::XML(%(<root>before<p></p>after</root>))
              pivot = xml.at_css("p")
              before = xml.root.children.first
              after = xml.root.children.last
              pivot.add_previous_sibling("x")

              assert_equal "after", after.content
              refute_nil after.parent, "unrelated node should not be affected"

              assert_equal "before", before.content
              refute_nil before.parent, "no need to reparent"
            end
          end
        end

        describe "#add_next_sibling" do
          it "should not merge text nodes during the operation" do
            xml = Nokogiri::XML(%(<root>text node</root>))
            replacee = xml.root.children.first
            replacee.add_next_sibling("foo <p></p> bar")
            assert_equal "text nodefoo <p></p> bar", xml.root.children.to_html
          end

          it "should append a text node before an existing non text node" do
            xml = Nokogiri::XML(%(<root><p>foo</p><p>bar</p></root>))
            p = xml.at_css("p")
            p.add_next_sibling("a")
            assert_equal "<root><p>foo</p>a<p>bar</p></root>", xml.root.to_s
          end

          it "should append a text node before an existing text node" do
            xml = Nokogiri::XML(%(<root><p>foo</p>after</root>))
            p = xml.at_css("p")
            p.add_next_sibling("x")
            assert_equal "<root><p>foo</p>xafter</root>", xml.root.to_s
          end

          describe "with a text node after" do
            it "should not defensively dup the 'after' text node" do
              xml = Nokogiri::XML(%(<root>before<p></p>after</root>))
              pivot = xml.at_css("p")
              before = xml.root.children.first
              after = xml.root.children.last
              pivot.add_next_sibling("x")

              assert_equal "before", before.content
              refute_nil before.parent, "unrelated node should not be affected"

              assert_equal "after", after.content
              refute_nil after.parent
            end
          end
        end

        describe "#replace" do
          describe "a text node with a text node" do
            it "should not merge text nodes during the operation" do
              xml = Nokogiri::XML(%(<root>text node</root>))
              replacee = xml.root.children.first

              replacee.replace("new text node")

              assert_equal "new text node", xml.root.children.first.content
            end
          end

          it "can replace with a comment node" do
            doc = Nokogiri::XML(%{<parent><child>text})
            replacee = doc.at_css("child")
            replacer = doc.create_comment("<b>text</b>")

            replacee.replace(replacer)

            assert_equal 1, doc.root.children.length
            assert_equal replacer, doc.root.children.first
          end

          it "can replace with a CDATA node" do
            doc = Nokogiri::XML(%{<parent><child>text})
            replacee = doc.at_css("child")
            replacer = doc.create_cdata("<b>text</b>")

            replacee.replace(replacer)

            assert_equal 1, doc.root.children.length
            assert_equal replacer, doc.root.children.first
          end

          it "replacing a child should not dup sibling text nodes" do
            # https://github.com/sparklemotion/nokogiri/issues/2916
            xml = "<root><parent>asdf</parent>qwer</root>"
            doc = Nokogiri::XML.parse(xml)
            nodes = doc.root.children
            parent = nodes.first
            sibling = parent.next

            parent.inner_html = "foo"

            assert_same(sibling, parent.next)
          end

          describe "when a document has a default namespace" do
            before do
              @fruits = Nokogiri::XML(<<~eoxml)
                <fruit xmlns="http://fruits.org">
                  <apple />
                </fruit>
              eoxml
            end

            it "inserts a node with default namespaces" do
              apple = @fruits.css("apple").first

              orange = Nokogiri::XML::Node.new("orange", @fruits)
              apple.replace(orange)

              assert_equal orange, @fruits.css("orange").first
            end
          end
        end

        describe "unlinking a node and then reparenting it" do
          it "should not cause illegal memory access during GC" do
            skip_unless_libxml2("valgrind tests should only run with libxml2")

            refute_valgrind_errors do
              # see http://github.com/sparklemotion/nokogiri/issues#issue/22
              doc = Nokogiri::XML(<<~EOHTML)
                <root>
                  <a>
                    <b/>
                    <c/>
                  </a>
                </root>
              EOHTML

              assert root = doc.at("root")
              assert a = root.at("a")
              assert b = a.at("b")
              assert c = a.at("c")
              a.add_next_sibling(b.unlink)
              c.unlink
            end
          end
        end

        describe "replace-merging text nodes" do
          [
            ["<root>a<br/></root>", "afoo"],
            ["<root>a<br/>b</root>", "afoob"],
            ["<root><br/>b</root>", "foob"],
          ].each do |xml, result|
            it "doesn't blow up on #{xml}" do
              doc = Nokogiri::XML.parse(xml)
              saved_nodes = doc.root.children
              doc.at_xpath("/root/br").replace(Nokogiri::XML::Text.new("foo", doc))
              saved_nodes.each(&:inspect) # try to cause a crash
              assert_equal result, doc.at_xpath("/root/text()").inner_text
            end
          end
        end

        describe "reparenting and preserving a reference to the original ns" do
          it "should not cause illegal memory access" do
            skip_unless_libxml2("valgrind tests should only run with libxml2")

            refute_valgrind_errors do
              # this test will only cause a failure in valgrind. it
              # drives out the reason why we can't call xmlFreeNs in
              # relink_namespace and instead have to root the nsdef.
              doc = Nokogiri::XML('<root xmlns="http://flavorjon.es/"><envelope /></root>')
              elem = doc.create_element("package", { "xmlns" => "http://flavorjon.es/" })
              ns = elem.namespace_definitions
              doc.at_css("envelope").add_child(elem)
              ns.inspect
            end
          end
        end

        describe "reparenting into another document" do
          it "correctly sets default namespace of a reparented node" do
            # issue described in #391
            # thanks to Nick Canzoneri @nickcanz for this test case!
            source_doc = Nokogiri::XML(<<~EOX)
              <?xml version="1.0" encoding="utf-8"?>
              <Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
                  <Product>
                      <Package />
                      <Directory Id="TARGETDIR" Name="SourceDir">
                          <Component>
                              <File />
                          </Component>
                      </Directory>
                  </Product>
              </Wix>
            EOX

            dest_doc = Nokogiri::XML(<<~EOX)
              <?xml version="1.0" encoding="utf-8"?>
              <Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
                <Fragment Id='MSIComponents'>
                    <DirectoryRef Id='InstallDir'>
                    </DirectoryRef>
                </Fragment>
              </Wix>
            EOX

            stuff = source_doc.at_css("Directory[Id='TARGETDIR']")
            insert_point = dest_doc.at_css("DirectoryRef[Id='InstallDir']")
            insert_point.children = stuff.children

            refute_match(/default:/, insert_point.children.to_xml)
            assert_match(/<Component>/, insert_point.children.to_xml)
          end
        end

        describe "creating a cycle in the graph" do
          it "raises an exception" do
            doc = Nokogiri::XML("<root><a><b/></a></root>")
            a = doc.at_css("a")
            b = doc.at_css("b")
            exception = assert_raises(RuntimeError) do
              a.parent = b
            end
            if Nokogiri.jruby?
              assert_match(/HIERARCHY_REQUEST_ERR/, exception.message)
            else
              assert_match(/cycle detected/, exception.message)
            end
          end
        end

        # https://github.com/sparklemotion/nokogiri/issues/3459
        describe "reparenting with duplicate namespace prefixes" do
          it "stitches together ok" do
            doc = Nokogiri::XML(<<~XML)
              <dnd:adventure xmlns:dnd="http://www.w3.org/dungeons#">
                <dnd:party xmlns:dnd="http://www.w3.org/dragons#">
                  <dnd:members>
                  </dnd:members>
                </dnd:party>
              </dnd:adventure>
            XML

            dungeons_ns = doc.root.namespace_definitions.find { |ns| ns.prefix == "dnd" }
            parent = doc.xpath("//ns:members", ns: "http://www.w3.org/dragons#").first

            node = doc.create_element("character")
            node.namespace = dungeons_ns
            parent.add_child(node)

            assert_includes(doc.to_xml, %{<dnd:character xmlns:dnd="http://www.w3.org/dungeons#"/>})
          end
        end
      end
    end
  end
end
