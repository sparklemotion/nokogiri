# encoding: utf-8
require 'nokogumbo'
require 'minitest/autorun'

def parse_test(test_data)
  test = { script: :both }
  index = /(?:^#errors\n|\n#errors\n)/ =~ test_data
  abort "Expected #errors in\n#{test_data}" if index.nil?
  skip_amount = $~[0].length
  # Omit the final new line
  test[:data] = test_data[0...index]

  # Process the rest line by line
  lines = test_data[index+skip_amount..-1].split("\n")
  index = lines.find_index do |line|
    line == '#document-fragment' ||
      line == '#document' ||
      line == '#script-off' ||
      line == '#script-on' ||
      line == '#new-errors'
  end
  abort 'Expected #document' if index.nil?
  test[:errors] = lines[0...index]
  test[:new_errors] = []
  if lines[index] == '#new-errors'
    index += 1
    while !%w[#document-fragment #document #script-off #script-on].include?(lines[index])
      test[:new_errors] << lines[index]
      index += 1
    end
  end

  if lines[index] == '#document-fragment'
    test[:context] = lines[index+1].chomp.split(' ', 2)
    index += 2
  end
  abort "failed to find fragment: #{index}: #{lines[index]}" if test_data.include?("#document-fragment") && test[:context].nil?

  if lines[index] =~ /#script-(on|off)/
    test[:script] = $~[1].to_sym
    index += 1
  end

  abort "Expected #document, got #{lines[index]}" unless lines[index] == '#document'
  index += 1

  document = {
    type: test[:context] ? :fragment : :document,
    children: []
  }
  open_nodes = [document]
  while index < lines.length
    abort "Expected '| ' but got #{lines[index]}" unless /^\| ( *)([^ ].*$)/ =~ lines[index]
    depth = $~[1].length
    if depth.odd?
      abort "Invalid nesting depth"
    else
      depth = depth / 2
    end
    abort "Too deep" if depth >= open_nodes.length

    node = {}
    node_text = $~[2]
    if node_text[0] == '"'
      if node_text == '"' || node_text[-1] != '"'
        loop do
          index += 1
          node_text << "\n" + lines[index]
          break if node_text[-1] == '"'
        end
      end
      node[:type] = :text
      node[:contents] = node_text[1..-2]
    elsif /^<!DOCTYPE ([^ >]*)(?: "([^"]*)" "(.*)")?>$/ =~ node_text
      node[:type] = :doctype
      node[:name] = $~[1]
      node[:public_id] = $~[2].nil? || $~[2].empty? ? nil : $~[2]
      node[:system_id] = $~[3].nil? || $~[3].empty? ? nil : $~[3]
    elsif /^<!-- (.*) -->$/ =~ node_text
      node[:type] = :comment
      node[:contents] = $~[1]
    elsif /^<(svg |math )?(.+)>$/ =~ node_text
      node[:type] = :element
      node[:ns] = $~[1].nil? ? nil : $~[1].rstrip
      node[:tag] = $~[2]
      node[:attributes] = []
      node[:children] = []
    elsif /^([^ ]+ )?([^=]+)="(.*)"$/ =~ node_text
      node[:type] = :attribute
      node[:ns] = $~[1].nil? ? nil : $~[1].rstrip
      node[:name] = $~[2]
      node[:value] = $~[3]
    elsif node_text == 'content'
      node[:type] = :template
    else
      abort "Unexpected node_text: #{node_text}"
    end

    if node[:type] == :attribute
      abort "depth #{depth} != #{open_nodes.length}" unless depth == open_nodes.length - 1
      abort "type :#{open_nodes[-1][:type]} != :element" unless open_nodes[-1][:type] == :element
      abort "element has children" unless open_nodes[-1][:children].empty?
      open_nodes[-1][:attributes] << node
    elsif node[:type] == :template
      abort "depth #{depth} != #{open_nodes.length}" unless depth == open_nodes.length - 1
      abort "type :#{open_nodes[-1][:type]} != :element" unless open_nodes[-1][:type] == :element
      abort "tag :#{open_nodes[-1][:tag]} != template" unless open_nodes[-1][:tag] == 'template'
      abort "template has children before the 'content'" unless open_nodes[-1][:children].empty?
      # Hack. We want the children of this template node to be reparented as
      # children of the template element.
      # XXX: Template contents are _not_ supposed to be children of the
      # template, but we currently mishandle this.
      open_nodes << open_nodes[-1]
    else
      open_nodes[depth][:children] << node
      open_nodes[depth+1..-1] = []
      if node[:type] == :element
        open_nodes << node
      end
    end
    index += 1
  end
  test[:document] = document
  test
end

class TestTreeConstructionBase < Minitest::Test
  def assert_equal_or_nil(exp, act)
    if exp.nil?
      assert_nil act
    else
      assert_equal exp, act
    end
  end

  def compare_nodes(node, ng_node)
    case ng_node.type
    when Nokogiri::XML::Node::ELEMENT_NODE
      assert_equal node[:type], :element
      if node[:ns]
        refute_nil ng_node.namespace
        assert_equal node[:ns], ng_node.namespace.prefix
      end
      assert_equal node[:tag], ng_node.name
      attributes = ng_node.attributes
      assert_equal node[:attributes].length, attributes.length
      node[:attributes].each do |attr|
        if attr[:ns]
          value = ng_node["#{attr[:ns]}:#{attr[:name]}"]
        else
          value = attributes[attr[:name]].value
        end
        assert_equal attr[:value], value
      end
      assert_equal node[:children].length, ng_node.children.length,
        "Element <#{node[:tag]}> has wrong number of children: #{ng_node.children.map { |c| c.name }}"
    when Nokogiri::XML::Node::TEXT_NODE, Nokogiri::XML::Node::CDATA_SECTION_NODE
      # We preserve the CDATA in the tree, but the tests represent it as text.
      assert_equal node[:type], :text
      assert_equal node[:contents], ng_node.content
    when Nokogiri::XML::Node::COMMENT_NODE
      assert_equal node[:type], :comment
      assert_equal node[:contents], ng_node.content
    when Nokogiri::XML::Node::HTML_DOCUMENT_NODE
      assert_equal node[:type], :document
      assert_equal node[:children].length, ng_node.children.length
    when Nokogiri::XML::Node::DOCUMENT_FRAG_NODE
      assert_equal node[:type], :fragment
      assert_equal node[:children].length, ng_node.children.length
    when Nokogiri::XML::Node::DTD_NODE
      assert_equal node[:type], :doctype
      assert_equal node[:name], ng_node.name
      assert_equal_or_nil node[:public_id], ng_node.external_id
      assert_equal_or_nil node[:system_id], ng_node.system_id
    else
      flunk "Unknown node type #{ng_node.type} (expected #{node[:type]})"
    end
  end

  def run_test
    if @test[:context]
      ctx = @test[:context].join(':')
      doc = Nokogiri::HTML5::Document.new
      doc = Nokogiri::HTML5::DocumentFragment.new(doc, @test[:data], ctx, max_errors: @test[:errors].length + 10)
    else
      doc = Nokogiri::HTML5.parse(@test[:data], max_errors: @test[:errors].length + 10)
    end
    # Walk the tree.
    exp_nodes = [@test[:document]]
    act_nodes = [doc]
    children = [0]
    compare_nodes(exp_nodes[0], doc)
    while children.any?
      child_index = children[-1]
      exp = exp_nodes[-1]
      act = act_nodes[-1]
      if child_index == exp[:children].length
        exp_nodes.pop
        act_nodes.pop
        children.pop
        next
      end
      exp_child = exp[:children][child_index]
      act_child = act.children[child_index]
      compare_nodes(exp_child, act_child)
      children[-1] = child_index + 1
      if exp_child.has_key?(:children)
        exp_nodes << exp_child
        act_nodes << act_child
        children << 0
      end
    end

    # Test the errors.
    assert_equal @test[:errors].length, doc.errors.length

    # The new, standardized tokenizer errors live in @test[:new_errors]. Let's
    # match each one to exactly one error in doc.errors. Unfortunately, the
    # tests specify the column the error is detected, _not_ the column of the
    # start of the problematic HTML (e.g., the start of a character reference
    # or <![CDATA[) the way gumbo does. So check that Gumbo's column is no
    # later than the error's column.
    errors = doc.errors.map { |err| { line: err.line, column: err.column, code: err.str1 } }
    errors.reject! { |err| err[:code] == 'generic-parser' }
    error_regex = /^\((?<line>\d+):(?<column>\d+)(?:-\d+:\d+)?\) (?<code>.*)$/
    @test[:new_errors].each do |err|
      assert_match(error_regex, err)
      m = err.match(error_regex)
      line = m[:line].to_i
      column = m[:column].to_i
      code = m[:code]
      idx = errors.index do |e|
        e[:line] == line &&
          e[:code] == code &&
          e[:column] <= column
      end
      # This error should be the first error in the list.
      #refute_nil(idx, "Expected to find error #{code} at #{line}:#{column}")
      assert_equal(0, idx, "Expected to find error #{code} at #{line}:#{column}")
      errors.delete_at(idx)
    end
  end
end

tc_path = File.expand_path('../html5lib-tests/tree-construction', __FILE__)
Dir[File.join(tc_path, '*.dat')].each do |path|
  test_name = "TestTreeConstruction" + File.basename(path, '.dat')
    .split(/[_-]/)
    .map { |s| s.capitalize }
    .join('')
  tests = []
  File.open(path, "r", encoding: 'UTF-8') do |f|
    f.each("\n\n#data\n") do |test_data|
      if test_data.start_with?("#data\n")
        test_data = test_data[6..-1]
      end
      if test_data.end_with?("\n\n#data\n")
        test_data = test_data[0..-9]
      end
      tests << parse_test(test_data)
    end
  end

  klass = Class.new(TestTreeConstructionBase) do
    tests.each_with_index do |test, index|
      next if test[:script] == :on;
      define_method "test_#{index}".to_sym do
        @test = test
        @index = index
        run_test
      end
    end
  end
  Object.const_set test_name, klass
end

# vim: set sw=2 sts=2 ts=8 et:
