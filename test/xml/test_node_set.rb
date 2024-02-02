# frozen_string_literal: true

require "helper"

module Nokogiri
  module XML
    class TestNodeSet < Nokogiri::TestCase
      describe Nokogiri::XML::NodeSet do
        describe "namespaces" do
          let(:ns_xml) { Nokogiri.XML('<foo xmlns:n0="http://example.com" />') }
          let(:ns_list) { ns_xml.xpath("//namespace::*") }
          let(:new_ns) { ns_xml.root.add_namespace_definition("n1", "http://example.com/n1") }

          specify "#include?" do
            assert_includes(ns_list, ns_list.first, "list should have item")
          end

          specify "#push" do
            expected_length = ns_list.length + 1
            ns_list.push(new_ns)
            assert_equal(expected_length, ns_list.length)
          end

          specify "#delete" do
            expected_length = ns_list.length
            ns_list.push(new_ns)
            ns_list.delete(new_ns)
            assert_equal(expected_length, ns_list.length)
          end

          it "doesn't free namespace nodes when deleted" do
            ns = ns_list.find { |node| node.prefix == "n0" }
            ns_list.delete(ns)
            assert_equal("http://example.com", ns.href)
          end
        end

        let(:xml) { Nokogiri::XML(File.read(XML_FILE), XML_FILE) }
        let(:list) { xml.css("employee") }

        describe "#filter" do
          it "finds all nodes that match the expression" do
            list = xml.css("address").filter('*[domestic="Yes"]')
            assert_equal(["Yes"] * 4, list.map { |n| n["domestic"] })
          end
        end

        specify "#remove_attr" do
          list.each { |x| x["class"] = "blah" }
          assert_equal(list, list.remove_attr("class"))
          list.each { |x| assert_nil(x["class"]) }
        end

        specify "#remove_attribute" do
          list.each { |x| x["class"] = "blah" }
          assert_equal(list, list.remove_attribute("class"))
          list.each { |x| assert_nil(x["class"]) }
        end

        specify "#add_class" do
          assert_equal(list, list.add_class("bar"))
          list.each { |x| assert_equal("bar", x["class"]) }

          list.add_class("bar")
          list.each { |x| assert_equal("bar", x["class"]) }

          list.add_class("baz")
          list.each { |x| assert_equal("bar baz", x["class"]) }
        end

        specify "#append_class" do
          assert_equal(list, list.append_class("bar"))
          list.each { |x| assert_equal("bar", x["class"]) }

          list.append_class("bar")
          list.each { |x| assert_equal("bar bar", x["class"]) }

          list.append_class("baz")
          list.each { |x| assert_equal("bar bar baz", x["class"]) }
        end

        describe "#remove_class" do
          it "removes the attribute when no classes remain" do
            assert_equal(list, list.remove_class("bar"))
            list.each { |e| assert_nil(e["class"]) }

            list.each { |e| e["class"] = "" }
            assert_equal(list, list.remove_class("bar"))
            list.each { |e| assert_nil(e["class"]) }
          end

          it "leaves the remaining classes" do
            list.each { |e| e["class"] = "foo bar" }

            assert_equal(list, list.remove_class("bar"))
            list.each { |e| assert_equal("foo", e["class"]) }
          end

          it "removes the class attribute when passed no arguments" do
            list.each { |e| e["class"] = "foo" }

            assert_equal(list, list.remove_class)
            list.each { |e| assert_nil(e["class"]) }
          end
        end

        [:attribute, :attr, :set].each do |method|
          describe "##{method}" do
            it "sets the attribute value" do
              list.each { |e| assert_nil(e["foo"]) }

              list.send(method, "foo", "bar")
              list.each { |e| assert_equal("bar", e["foo"]) }
            end

            it "sets the attribute value given a block" do
              list.each { |e| assert_nil(e["foo"]) }

              list.send(method, "foo") { |e| e.at_css("employeeId").text }
              list.each { |e| assert_equal(e.at_css("employeeId").text, e["foo"]) }
            end

            it "sets the attribute value given a hash" do
              list.each { |e| assert_nil(e["foo"]) }

              list.send(method, { "foo" => "bar" })
              list.each { |e| assert_equal("bar", e["foo"]) }
            end
          end
        end

        it "#attribute with no args gets attribute from first node" do
          list.first["foo"] = "bar"
          assert_equal(list.first.attribute("foo"), list.attribute("foo"))
        end

        it "#attribute with no args on empty set" do
          set = Nokogiri::XML::NodeSet.new(Nokogiri::XML::Document.new)
          assert_nil(set.attribute("foo"))
        end

        describe "searching" do
          it "an empty node set returns no results" do
            set = Nokogiri::XML::NodeSet.new(Nokogiri::XML::Document.new)
            assert_equal(0, set.css("foo").length)
            assert_equal(0, set.xpath(".//foo").length)
            assert_equal(0, set.search("foo").length)
          end

          it "with multiple queries" do
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
            set = Nokogiri::XML(xml).xpath(".//thing")
            assert_kind_of(Nokogiri::XML::NodeSet, set)

            assert_equal(3, set.xpath("./div", "./p").length)
            assert_equal(3, set.css(".title", ".content", "p").length)
            assert_equal(3, set.search("./div", "p.blah").length)
          end

          it "with a custom selector" do
            set = xml.xpath("//staff")

            [
              [:xpath,  "//*[nokogiri:awesome(.)]"],
              [:search, "//*[nokogiri:awesome(.)]"],
              [:css,    "*:awesome"],
              [:search, "*:awesome"],
            ].each do |method, query|
              callback_handler = Class.new do
                def awesome(ns)
                  ns.select { |n| n.name == "employee" }
                end
              end.new
              custom_employees = set.send(method, query, callback_handler)

              assert_equal(
                xml.xpath("//employee"),
                custom_employees,
                "using #{method} with custom selector '#{query}'",
              )
            end
          end

          it "with variable bindings" do
            set = xml.xpath("//staff")

            assert_equal(
              4,
              set.xpath("//address[@domestic=$value]", nil, value: "Yes").length,
              "using #xpath with variable binding",
            )

            assert_equal(
              4,
              set.search("//address[@domestic=$value]", nil, value: "Yes").length,
              "using #search with variable binding",
            )
          end

          it "context search returns itself" do
            set = xml.xpath("//staff")
            assert_equal(set.to_a, set.search(".").to_a)
          end

          it "css searches match self" do
            html = Nokogiri::HTML("<html><body><div class='a'></div></body></html>")
            set = html.xpath("/html/body/div")
            assert_equal(set.first, set.css(".a").first)
            assert_equal(set.first, set.search(".a").first)
          end

          it "css search with namespace" do
            fragment = Nokogiri::XML.fragment(<<~eoxml)
              <html xmlns="http://www.w3.org/1999/xhtml">
              <head></head>
              <body></body>
              </html>
            eoxml
            assert(fragment.children.search("body", { "xmlns" => "http://www.w3.org/1999/xhtml" }))
          end

          it "xmlns is automatically registered" do
            doc = Nokogiri::XML(<<~eoxml)
              <root xmlns="http://tenderlovemaking.com/">
                <foo>
                  <bar/>
                </foo>
              </root>
            eoxml
            set = doc.css("foo")
            assert_equal(1, set.css("xmlns|bar").length)
            assert_equal(0, set.css("|bar").length)
            assert_equal(1, set.xpath("//xmlns:bar").length)
            assert_equal(1, set.search("xmlns|bar").length)
            assert_equal(1, set.search("//xmlns:bar").length)
            assert(set.at("//xmlns:bar"))
            assert(set.at("xmlns|bar"))
            assert(set.at("bar"))
          end

          it "#search accepts a namespace" do
            xml = Nokogiri::XML.parse(<<~eoxml)
              <root>
                <car xmlns:part="http://general-motors.com/">
                  <part:tire>Michelin Model XGV</part:tire>
                </car>
                <bicycle xmlns:part="http://schwinn.com/">
                  <part:tire>I'm a bicycle tire!</part:tire>
                </bicycle>
              </root>
            eoxml
            set = xml / "root"
            assert_equal(1, set.length)
            bike_tire = set.search("//bike:tire", "bike" => "http://schwinn.com/")
            assert_equal(1, bike_tire.length)
          end

          specify "#search" do
            assert(node_set = xml.search("//employee"))
            assert(sub_set = node_set.search(".//name"))
            assert_equal(node_set.length, sub_set.length)
          end

          it "returns an empty node set when no results were found" do
            assert(node_set = xml.search("//asdkfjhasdlkfjhaldskfh"))
            assert_equal(0, node_set.length)
          end
        end

        describe "#==" do
          it "checks for equality of contents" do
            assert(node_set_one = xml.xpath("//employee"))
            assert(node_set_two = xml.xpath("//employee"))

            refute_same(node_set_one, node_set_two)
            refute_same(node_set_one, node_set_two)

            assert_operator(node_set_one, :==, node_set_two) # rubocop:disable Minitest/AssertEqual
          end

          it "handles comparison to a string" do
            node_set_one = xml.xpath("//employee")
            refute_operator(node_set_one, :==, "asdfadsf") # rubocop:disable Minitest/RefuteEqual
          end

          it "returns false if same elements are out of order" do
            one = xml.xpath("//employee")
            two = xml.xpath("//employee")
            two.push(two.shift)
            refute_operator(one, :==, two) # rubocop:disable Minitest/RefuteEqual
          end

          it "returns false if one is a subset of the other" do
            node_set_one = xml.xpath("//employee")
            node_set_two = xml.xpath("//employee")
            node_set_two.delete(node_set_two.first)

            refute_operator(node_set_one, :==, node_set_two) # rubocop:disable Minitest/RefuteEqual
            refute_operator(node_set_two, :==, node_set_one) # rubocop:disable Minitest/RefuteEqual
          end
        end

        describe "#pop" do
          it "returns the last element and mutates the set" do
            set = xml.xpath("//employee")
            last = set.last
            assert_equal(last, set.pop)
          end

          it "returns nil for an empty set" do
            set = Nokogiri::XML::NodeSet.new(xml)
            assert_nil(set.pop)
          end
        end

        describe "#shift" do
          it "returns the first element and mutates the set" do
            set = xml.xpath("//employee")
            first = set.first
            assert_equal(first, set.shift)
          end

          it "returns nil for an empty set" do
            set = Nokogiri::XML::NodeSet.new(xml)
            assert_nil(set.shift)
          end
        end

        describe "#first" do
          it "returns the first node" do
            node_set = xml.xpath("//employee")
            node = xml.at_xpath("//employee")
            assert_equal(node, node_set.first)
          end

          it "returns the first n nodes" do
            assert(node_set = xml.xpath("//employee"))
            assert_equal(2, node_set.first(2).length)
          end

          it "returns all the nodes if arguments are longer than the set" do
            assert(node_set = xml.xpath("//employee[position() < 3]"))
            assert_equal(2, node_set.length)
            assert_equal(2, node_set.first(5).length)
          end
        end

        [:dup, :clone].each do |method_name|
          specify "##{method_name}" do
            assert node_set = xml.xpath("//employee")
            duplicate = node_set.send(method_name)
            assert_equal node_set.length, duplicate.length
            node_set.zip(duplicate).each do |a, b|
              assert_equal a, b
            end
          end
        end

        specify "test_dup_should_not_copy_singleton_class" do
          # https://github.com/sparklemotion/nokogiri/issues/316
          m = Module.new do
            def foo; end
          end

          set = Nokogiri::XML::Document.parse("<root/>").css("root")
          set.extend(m)

          assert_respond_to(set, :foo)
          refute_respond_to(set.dup, :foo)
        end

        specify "test_clone_should_copy_singleton_class" do
          # https://github.com/sparklemotion/nokogiri/issues/316
          m = Module.new do
            def foo; end
          end

          set = Nokogiri::XML::Document.parse("<root/>").css("root")
          set.extend(m)

          assert_respond_to(set, :foo)
          assert_respond_to(set.clone, :foo)
        end

        specify "#dup on empty set" do
          empty_set = Nokogiri::XML::NodeSet.new(xml, [])
          assert_equal(0, empty_set.dup.length) # this shouldn't raise null pointer exception
        end

        it "Document#children node set has a document reference" do
          set = xml.root.children
          assert_instance_of(NodeSet, set)
          assert_equal(xml, set.document)
        end

        it "length and size are aliases" do
          assert(node_set = xml.search("//employee"))
          assert_equal(node_set.length, node_set.size)
        end

        it "to_xml" do
          assert(node_set = xml.search("//employee"))
          assert(node_set.to_xml)
        end

        it "inner_html" do
          doc = Nokogiri::HTML(<<~eohtml)
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
          assert(html = doc.css("div").inner_html)
          assert_match("<a>one</a>", html)
          assert_match("<a>two</a>", html)
        end

        it "searches direct children of nodes with :>" do
          xml = <<~XML
            <root>
              <wrap>
                <div class="section header" id="1">
                  <div class="subsection header">sub 1</div>
                  <div class="subsection header">sub 2</div>
                </div>
              </wrap>
              <wrap>
                <div class="section header" id="2">
                  <div class="subsection header">sub 3</div>
                  <div class="subsection header">sub 4</div>
                </div>
              </wrap>
            </root>
          XML
          node_set = Nokogiri::XML::Document.parse(xml).xpath("/root/wrap")
          result = (node_set > "div.header")
          assert_equal(2, result.length)
          assert_equal(["1", "2"], result.map { |n| n["id"] })

          assert_empty(node_set > ".no-such-match")
        end

        it "at_performs_a_search_with_css" do
          assert(node_set = xml.search("//employee"))
          assert_equal(node_set.first.first_element_child, node_set.at("employeeId"))
          assert_equal(node_set.first.first_element_child, node_set.%("employeeId"))
        end

        it "at_performs_a_search_with_xpath" do
          assert(node_set = xml.search("//employee"))
          assert_equal(node_set.first.first_element_child, node_set.at("./employeeId"))
          assert_equal(node_set.first.first_element_child, node_set.%("./employeeId"))
        end

        it "at_with_integer_index" do
          assert(node_set = xml.search("//employee"))
          assert_equal(node_set.first, node_set.at(0))
          assert_equal(node_set.first, node_set % 0)
        end

        it "at_xpath" do
          assert(node_set = xml.search("//employee"))
          assert_equal(node_set.first.first_element_child, node_set.at_xpath("./employeeId"))
        end

        it "at_css" do
          assert(node_set = xml.search("//employee"))
          assert_equal(node_set.first.first_element_child, node_set.at_css("employeeId"))
        end

        it "to_ary" do
          assert(node_set = xml.search("//employee"))
          foo = []
          foo += node_set
          assert_equal(node_set.length, foo.length)
        end

        specify "#push" do
          node = Nokogiri::XML::Node.new("foo", xml)
          node.content = "bar"

          assert(node_set = xml.search("//employee"))
          node_set.push(node)

          assert_includes(node_set, node)
        end

        describe "#delete" do
          it "raises ArgumentError when given an invalid argument" do
            employees = xml.search("//employee")
            positions = xml.search("//position")

            assert_raises(ArgumentError) { employees.delete(positions) }
          end

          it "deletes the element when present and returns the deleted element" do
            employees = xml.search("//employee")
            wally = employees.first
            assert_includes(employees, wally) # testing setup
            length = employees.length

            result = employees.delete(wally)
            assert_equal(result, wally)
            refute_includes(employees, wally)
            assert_equal(length - 1, employees.length)
          end

          it "does nothing and returns nil when not present" do
            employees = xml.search("//employee")
            phb = xml.search("//position").first
            refute_includes(employees, phb) # testing setup
            length = employees.length

            result = employees.delete(phb)
            assert_nil(result)
            assert_equal(length, employees.length)
          end

          it "does nothing and returns nil when sent to and empty set" do
            empty_set = Nokogiri::XML::NodeSet.new(xml, [])
            employee  = xml.at_xpath("//employee")
            assert_nil(empty_set.delete(employee))
          end
        end

        specify "#unlink" do
          xml = Nokogiri::XML.parse(<<~eoxml)
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
          set = xml.xpath("//a")
          set.unlink
          set.each do |node|
            refute(node.parent)
            # assert !node.document
            refute(node.previous_sibling)
            refute(node.next_sibling)
          end
          refute_match(/Hello world/, xml.to_s)
        end

        it "new_nodeset" do
          node_set = Nokogiri::XML::NodeSet.new(xml)
          assert_equal(0, node_set.length)
          node = Nokogiri::XML::Node.new("form", xml)
          node_set << node
          assert_equal(1, node_set.length)
          assert_equal(node, node_set.last)
        end

        describe "#wrap" do
          it "wraps each node within a reified copy of the tag passed" do
            employees = xml.css("employee")
            rval = employees.wrap("<wrapper/>")
            wrappers = xml.css("wrapper")

            assert_equal(rval, employees)
            assert_equal(employees.length, wrappers.length)
            employees.each do |employee|
              assert_equal("wrapper", employee.parent.name)
            end
            wrappers.each do |wrapper|
              assert_equal("staff", wrapper.parent.name)
              assert_equal(1, wrapper.children.length)
              assert_equal("employee", wrapper.children.first.name)
            end
          end

          it "wraps each node within a dup of the Node argument" do
            employees = xml.css("employee")
            rval = employees.wrap(xml.create_element("wrapper"))
            wrappers = xml.css("wrapper")

            assert_equal(rval, employees)
            assert_equal(employees.length, wrappers.length)
            employees.each do |employee|
              assert_equal("wrapper", employee.parent.name)
            end
            wrappers.each do |wrapper|
              assert_equal("staff", wrapper.parent.name)
              assert_equal(1, wrapper.children.length)
              assert_equal("employee", wrapper.children.first.name)
            end
          end

          it "handles various node types and handles recursive reparenting" do
            doc = Nokogiri::XML("<root><foo>contents</foo></root>")
            nodes = doc.at_css("root").xpath(".//* | .//*/text()") # foo and "contents"
            nodes.wrap("<wrapper/>")
            wrappers = doc.css("wrapper")

            assert_equal("root", wrappers.first.parent.name)
            assert_equal("foo", wrappers.first.children.first.name)
            assert_equal("foo", wrappers.last.parent.name)
            assert_predicate(wrappers.last.children.first, :text?)
            assert_equal("contents", wrappers.last.children.first.text)
          end

          it "works for nodes in a fragment" do
            frag = Nokogiri::XML::DocumentFragment.parse(<<~EOXML)
              <employees>
                <employee>hello</employee>
                <employee>goodbye</employee>
              </employees>
            EOXML
            employees = frag.css("employee")
            employees.wrap("<wrapper/>")
            assert_equal("wrapper", employees[0].parent.name)
            assert_equal("employee", frag.at(".//wrapper").children.first.name)
          end

          it "preserves document structure" do
            assert_equal(
              "employeeId",
              xml.at_xpath("//employee").children.detect { |j| !j.text? }.name,
            )
            xml.xpath("//employeeId[text()='EMP0001']").wrap("<wrapper/>")
            assert_equal(
              "wrapper",
              xml.at_xpath("//employee").children.detect { |j| !j.text? }.name,
            )
          end
        end

        [:+, :|].each do |method|
          describe "##{method}" do
            let(:names) { xml.search("name") }
            let(:positions) { xml.search("position") }

            it "raises an exception when the rhs type isn't a NodeSet" do
              assert_raises(ArgumentError) { names.send(method, positions.first) }
              assert_raises(ArgumentError) { names.send(method, 3) }
            end

            it "returns the setwise union" do
              names_len = names.length
              positions_len = positions.length

              result = names.send(method, positions)
              assert_equal(names_len, names.length)
              assert_equal(positions_len, positions.length)
              assert_equal(names_len + positions_len, result.length)
            end

            it "ignores duplicates" do
              names = xml.search("name")

              assert_equal(names.length, (names + xml.search("name")).length)
            end
          end
        end

        it "#+=" do
          names = xml.search("name")
          positions = xml.search("positions")
          expected_length = names.length + positions.length
          names += positions
          assert_equal(expected_length, names.length)
        end

        it "#-" do
          employees = xml.search("//employee")
          women = xml.search("//employee[gender[text()='Female']]")

          employees_len = employees.length
          women_len = women.length

          assert_raises(ArgumentError) { employees - women.first }

          result = employees - women
          assert_equal(employees_len, employees.length)
          assert_equal(women_len, women.length)
          assert_equal(employees.length - women.length, result.length)

          employees -= women
          assert_equal(result.length, employees.length)
        end

        describe "#[]" do
          it "negative_index_works" do
            assert(node_set = xml.search("//employee"))
            assert_equal(node_set.last, node_set[-1])
          end

          it "large_negative_index_returns_nil" do
            assert(node_set = xml.search("//employee"))
            assert_nil(node_set[-1 * (node_set.length + 1)])
          end

          it "array_index" do
            employees = xml.search("//employee")
            other = xml.search("//position").first

            assert_equal(3, employees.index(employees[3]))
            assert_nil(employees.index(other))
            assert_equal(3, employees.index { |employee| employee.search("employeeId/text()").to_s == "EMP0004" })
            assert_nil(employees.index { |employee| employee.search("employeeId/text()").to_s == "EMP0000" })
          end

          it "slice_too_far" do
            employees = xml.search("//employee")
            assert_equal(employees.length, employees[0, employees.length + 1].length)
            assert_equal(employees.length, employees[0, employees.length].length)
          end

          it "slice_on_empty_node_set" do
            empty_set = Nokogiri::XML::NodeSet.new(xml, [])
            assert_nil(empty_set[99])
            assert_nil(empty_set[99..101])
            assert_nil(empty_set[99, 2])
          end

          it "slice_waaaaaay_off_the_end" do
            xml = Nokogiri::XML::Builder.new do
              root { 100.times { div } }
            end.doc
            nodes = xml.css("div")
            assert_equal(1, nodes.slice(99,  100_000).length)
            assert_equal(0, nodes.slice(100, 100_000).length)
          end

          it "array_slice_with_start_and_end" do
            employees = xml.search("//employee")
            assert_equal([employees[1], employees[2], employees[3]], employees[1, 3].to_a)
          end

          it "array_index_bracket_equivalence" do
            employees = xml.search("//employee")
            assert_equal([employees[1], employees[2], employees[3]], employees[1, 3].to_a)
            assert_equal([employees[1], employees[2], employees[3]], employees.slice(1, 3).to_a)
          end

          it "array_slice_with_negative_start" do
            employees = xml.search("//employee")
            assert_equal([employees[2]],                    employees[-3, 1].to_a)
            assert_equal([employees[2], employees[3]],      employees[-3, 2].to_a)
          end

          it "array_slice_with_invalid_args" do
            employees = xml.search("//employee")
            assert_nil(employees[99, 1]) # large start
            assert_nil(employees[1, -1]) # negative len
            assert_empty(employees[1, 0].to_a) # zero len
          end

          it "array_slice_with_range" do
            employees = xml.search("//employee")
            assert_equal([employees[1], employees[2], employees[3]], employees[1..3].to_a)
            assert_equal([employees[0], employees[1], employees[2], employees[3]], employees[0..3].to_a)
          end

          it "raises a TypeError if param is not an integer or range" do
            employees = xml.search("//employee")
            assert_raises(TypeError) do
              employees["foo"]
            end
          end
        end

        describe "#& intersection" do
          it "with no overlap returns an empty set" do
            employees = xml.search("//employee")
            positions = xml.search("//position")

            assert_equal(0, (employees & positions).length)
          end

          it "with an empty set returns an empty set" do
            empty_set = Nokogiri::XML::NodeSet.new(xml)
            employees = xml.search("//employee")
            assert_equal(0, (empty_set & employees).length)
            assert_equal(0, (employees & empty_set).length)
          end

          it "returns the intersection" do
            employees = xml.search("//employee")
            first_set = employees[0..2]
            second_set = employees[2..4]

            assert_equal([employees[2]], (first_set & second_set).to_a)
          end
        end

        describe "#include?" do
          it "returns true or false appropriately" do
            employees = xml.search("//employee")
            yes = employees.first
            no = xml.search("//position").first

            assert_includes(employees, yes)
            refute_includes(employees, no)
          end

          it "returns false on empty set" do
            empty_set = Nokogiri::XML::NodeSet.new(xml, [])
            employee  = xml.at_xpath("//employee")
            refute_includes(empty_set, employee)
          end
        end

        describe "#each" do
          it "supports break" do
            assert_equal(7, xml.root.elements.each { |_x| break 7 })
          end

          it "returns an enumerator given no block" do
            skip("enumerators confuse valgrind") if i_am_running_in_valgrind
            skip("enumerators confuse ASan") if i_am_running_with_asan
            skip("https://bugs.ruby-lang.org/issues/20085") if RUBY_DESCRIPTION.include?("aarch64") && RUBY_VERSION == "3.3.0"

            employees = xml.search("//employee")
            enum = employees.each
            assert_instance_of(Enumerator, enum)
            assert_equal(enum.next, employees[0])
            assert_equal(enum.next, employees[1])
          end

          it "returns self given a block" do
            node_set1 = xml.css("address")
            node_set2 = node_set1.each {}
            assert_same(node_set1, node_set2)
          end
        end

        specify "#children" do
          employees = xml.search("//employee")
          count = 0
          employees.each do |employee|
            count += employee.children.length
          end
          set = employees.children
          assert_equal(count, set.length)
        end

        specify "#inspect" do
          employees = xml.search("//employee")
          inspected = employees.inspect

          assert_equal(
            "[#{employees.map(&:inspect).join(", ")}]",
            inspected,
          )
        end

        it "should_not_splode_when_accessing_namespace_declarations_in_a_node_set" do
          2.times do
            xml = Nokogiri::XML("<foo></foo>")
            node_set = xml.xpath("//namespace::*")
            assert_equal(1, node_set.size)
            node = node_set.first
            node.to_s # segfaults in 1.4.0 and earlier

            # if we haven't segfaulted, let's make sure we handled it correctly
            assert_instance_of(Nokogiri::XML::Namespace, node)
          end
        end

        it "should_not_splode_when_arrayifying_node_set_containing_namespace_declarations" do
          xml = Nokogiri::XML("<foo></foo>")
          node_set = xml.xpath("//namespace::*")
          assert_equal(1, node_set.size)

          node_array = node_set.to_a
          node = node_array.first
          node.to_s # segfaults in 1.4.0 and earlier

          # if we haven't segfaulted, let's make sure we handled it correctly
          assert_instance_of(Nokogiri::XML::Namespace, node)
        end

        it "should_not_splode_when_unlinking_node_set_containing_namespace_declarations" do
          xml = Nokogiri::XML("<foo></foo>")
          node_set = xml.xpath("//namespace::*")
          assert_equal(1, node_set.size)

          node_set.unlink
        end

        specify "#reverse" do
          xml = Nokogiri::XML("<root><a />b<c />d<e /></root>")
          children = xml.root.children
          assert_instance_of(Nokogiri::XML::NodeSet, children)

          reversed = children.reverse
          assert_equal(reversed[0], children[4])
          assert_equal(reversed[1], children[3])
          assert_equal(reversed[2], children[2])
          assert_equal(reversed[3], children[1])
          assert_equal(reversed[4], children[0])

          assert_equal(children, children.reverse.reverse)
        end

        it "node_set_dup_result_has_document_and_is_decorated" do
          x = Module.new do
            def awesome!; end
          end
          util_decorate(xml, x)
          node_set = xml.css("address")
          new_set  = node_set.dup
          assert_equal(node_set.document, new_set.document)
          assert_respond_to(new_set, :awesome!)
        end

        it "node_set_union_result_has_document_and_is_decorated" do
          x = Module.new do
            def awesome!; end
          end
          util_decorate(xml, x)
          node_set1 = xml.css("address")
          node_set2 = xml.css("address")
          new_set = node_set1 | node_set2
          assert_equal(node_set1.document, new_set.document)
          assert_respond_to(new_set, :awesome!)
        end

        it "node_set_intersection_result_has_document_and_is_decorated" do
          x = Module.new do
            def awesome!; end
          end
          util_decorate(xml, x)
          node_set1 = xml.css("address")
          node_set2 = xml.css("address")
          new_set = node_set1 & node_set2
          assert_equal(node_set1.document, new_set.document)
          assert_respond_to(new_set, :awesome!)
        end

        it "node_set_difference_result_has_document_and_is_decorated" do
          x = Module.new do
            def awesome!; end
          end
          util_decorate(xml, x)
          node_set1 = xml.css("address")
          node_set2 = xml.css("address")
          new_set = node_set1 - node_set2
          assert_equal(node_set1.document, new_set.document)
          assert_respond_to(new_set, :awesome!)
        end

        it "node_set_slice_result_has_document_and_is_decorated" do
          x = Module.new do
            def awesome!; end
          end
          util_decorate(xml, x)
          node_set = xml.css("address")
          new_set  = node_set[0..-1]
          assert_equal(node_set.document, new_set.document)
          assert_respond_to(new_set, :awesome!)
        end

        describe "adding nodes from different documents to the same NodeSet" do
          # see https://github.com/sparklemotion/nokogiri/issues/1952
          it "should not segfault" do
            skip_unless_libxml2("valgrind tests should only run with libxml2")

            node_set = refute_valgrind_errors do
              xml = <<~EOF
                <?xml version="1.0" encoding="UTF-8"?>
                <container></container>
              EOF

              Nokogiri::XML::Document.parse(xml).css("container") + Nokogiri::XML::Document.parse(xml).css("container")
            end

            # see if everything's still there
            node_set.to_s
          end

          it "should handle this case just fine" do
            doc1 = Nokogiri::XML::Document.parse("<div class='doc1'></div>")
            doc2 = Nokogiri::XML::Document.parse("<div class='doc2'></div>")
            node_set = doc1.css("div")
            assert_equal(doc1, node_set.document)
            node_set += doc2.css("div")
            assert_equal(2, node_set.length)
            assert_equal(doc1, node_set[0].document)
            assert_equal(doc2, node_set[1].document)
          end
        end

        describe "empty sets" do
          it "#to_html returns an empty string" do
            assert_equal("", NodeSet.new(xml, []).to_html)
          end
        end
      end
    end
  end
end
