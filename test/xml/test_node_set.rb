require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestNodeSet < Nokogiri::TestCase
      def setup
        super
        @xml = Nokogiri::XML(File.read(XML_FILE), XML_FILE)
      end

      def test_search_empty_node_set
        set = Nokogiri::XML::NodeSet.new(Nokogiri::XML::Document.new)
        assert_equal 0, set.css('foo').length
        assert_equal 0, set.xpath('.//foo').length
        assert_equal 0, set.search('foo').length
      end

      def test_css_searches_match_self
        html = Nokogiri::HTML("<html><body><div class='a'></div></body></html>")
        set = html.xpath("/html/body/div")
        assert_equal set.first, set.css(".a").first
      end

      def test_search_with_css_matches_self
        html = Nokogiri::HTML("<html><body><div class='a'></div></body></html>")
        set = html.xpath("/html/body/div")
        assert_equal set.first, set.search(".a").first
      end

      def test_double_equal
        assert node_set_one = @xml.xpath('//employee')
        assert node_set_two = @xml.xpath('//employee')

        assert_not_equal node_set_one.object_id, node_set_two.object_id

        assert_equal node_set_one, node_set_two
      end

      def test_node_set_not_equal_to_string
        node_set_one = @xml.xpath('//employee')
        assert_not_equal node_set_one, "asdfadsf"
      end

      def test_out_of_order_not_equal
        one = @xml.xpath('//employee')
        two = @xml.xpath('//employee')
        two.push two.shift
        assert_not_equal one, two
      end

      def test_shorter_is_not_equal
        node_set_one = @xml.xpath('//employee')
        node_set_two = @xml.xpath('//employee')
        node_set_two.delete(node_set_two.first)

        assert_not_equal node_set_one, node_set_two
      end

      def test_pop
        set = @xml.xpath('//employee')
        last = set.last
        assert_equal last, set.pop
      end

      def test_shift
        set = @xml.xpath('//employee')
        first = set.first
        assert_equal first, set.shift
      end

      def test_shift_empty
        set = Nokogiri::XML::NodeSet.new(@xml)
        assert_nil set.shift
      end

      def test_pop_empty
        set = Nokogiri::XML::NodeSet.new(@xml)
        assert_nil set.pop
      end

      def test_first_takes_arguments
        assert node_set = @xml.xpath('//employee')
        assert_equal 2, node_set.first(2).length
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

      def test_children_has_document
        set = @xml.root.children
        assert_instance_of(NodeSet, set)
        assert_equal @xml, set.document
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
      
      def test_percent
        assert node_set = @xml.search('//employee')
        assert_equal node_set.first, node_set % 0
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

      def test_delete_with_invalid_argument
        employees = @xml.search("//employee")
        positions = @xml.search("//position")

        assert_raises(ArgumentError) { employees.delete(positions) }
      end

      def test_delete_when_present
        employees = @xml.search("//employee")
        wally = employees.first
        assert employees.include?(wally) # testing setup
        length = employees.length

        result = employees.delete(wally)
        assert_equal result, wally
        assert ! employees.include?(wally)
        assert length-1, employees.length
      end

      def test_delete_when_not_present
        employees = @xml.search("//employee")
        phb = @xml.search("//position").first
        assert ! employees.include?(phb) # testing setup
        length = employees.length

        result = employees.delete(phb)
        assert_nil result
        assert length, employees.length
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

      def test_plus_operator
        names = @xml.search("name")
        positions = @xml.search("position")

        names_len = names.length
        positions_len = positions.length

        assert_raises(ArgumentError) { result = names + positions.first }

        result = names + positions
        assert_equal names_len,                         names.length
        assert_equal positions_len,                     positions.length
        assert_equal names.length + positions.length,   result.length

        names += positions
        assert_equal result.length, names.length
      end

      def test_minus_operator
        employees = @xml.search("//employee")
        females = @xml.search("//employee[gender[text()='Female']]")

        employees_len = employees.length
        females_len = females.length

        assert_raises(ArgumentError) { result = employees - females.first }

        result = employees - females
        assert_equal employees_len,                     employees.length
        assert_equal females_len,                       females.length
        assert_equal employees.length - females.length, result.length

        employees -= females
        assert_equal result.length, employees.length
      end

      def test_array_index
        employees = @xml.search("//employee")
        other = @xml.search("//position").first

        assert_equal 3, employees.index(employees[3])
        assert_nil employees.index(other)
      end

      def test_array_slice_with_start_and_end
        employees = @xml.search("//employee")
        assert_equal [employees[1], employees[2], employees[3]], employees[1,3].to_a
      end

      def test_array_index_bracket_equivalence
        employees = @xml.search("//employee")
        assert_equal [employees[1], employees[2], employees[3]], employees[1,3].to_a
        assert_equal [employees[1], employees[2], employees[3]], employees.slice(1,3).to_a
      end

      def test_array_slice_with_negative_start
        employees = @xml.search("//employee")
        assert_equal [employees[2]],                    employees[-3,1].to_a
        assert_equal [employees[2], employees[3]],      employees[-3,2].to_a
      end

      def test_array_slice_with_invalid_args
        employees = @xml.search("//employee")
        assert_nil employees[99, 1] # large start
        assert_nil employees[1, -1] # negative len
        assert_equal [], employees[1, 0].to_a # zero len
      end

      def test_array_slice_with_range
        employees = @xml.search("//employee")
        assert_equal [employees[1], employees[2], employees[3]], employees[1..3].to_a
        assert_equal [employees[0], employees[1], employees[2], employees[3]], employees[0..3].to_a
      end

      def test_intersection_with_no_overlap
        employees = @xml.search("//employee")
        positions = @xml.search("//position")

        assert_equal [], (employees & positions).to_a
      end

      def test_intersection
        employees = @xml.search("//employee")
        first_set = employees[0..2]
        second_set = employees[2..4]

        assert_equal [employees[2]], (first_set & second_set).to_a
      end

      def test_include?
        employees = @xml.search("//employee")
        yes = employees.first
        no = @xml.search("//position").first

        assert employees.include?(yes)
        assert ! employees.include?(no)
      end

    end
  end
end
