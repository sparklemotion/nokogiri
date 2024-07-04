# encoding: utf-8
# frozen_string_literal: true

require "English"
require "helper"

class TestHtml5TreeConstructionBase < Nokogiri::TestCase
  def assert_equal_or_nil(exp, act)
    if exp.nil?
      assert_nil(act)
    else
      assert_equal(exp, act)
    end
  end

  def compare_nodes(node, ng_node)
    case ng_node.type
    when Nokogiri::XML::Node::ELEMENT_NODE
      assert_equal(:element, node[:type])
      if node[:ns]
        refute_nil(ng_node.namespace)
        assert_equal(node[:ns], ng_node.namespace.prefix)
      end
      assert_equal(node[:tag], ng_node.name)
      attributes = ng_node.attributes
      assert_equal(node[:attributes].length, attributes.length)
      node[:attributes].each do |attr|
        value = if attr[:ns]
          ng_node["#{attr[:ns]}:#{attr[:name]}"]
        else
          attributes[attr[:name]].value
        end
        assert_equal(attr[:value], value, "expected #{attr}[:value] to equal #{value.inspect}")
      end
      assert_equal(
        node[:children].length,
        ng_node.children.length,
        [
          "Element <#{node[:tag]}> has wrong number of children #{ng_node.children.map(&:name)}",
          "   Input: #{@test[:data]}",
          "Expected: #{@test[:raw].join("\n          ")}",
          "  Parsed: #{ng_node.to_html}",
        ].join("\n"),
      )
    when Nokogiri::XML::Node::TEXT_NODE, Nokogiri::XML::Node::CDATA_SECTION_NODE
      # We preserve the CDATA in the tree, but the tests represent it as text.
      assert_equal(:text, node[:type])
      assert_equal(node[:contents], ng_node.content)
    when Nokogiri::XML::Node::COMMENT_NODE
      assert_equal(:comment, node[:type])
      assert_equal(node[:contents], ng_node.content)
    when Nokogiri::XML::Node::HTML_DOCUMENT_NODE
      assert_equal(:document, node[:type])
      assert_equal(node[:children].length, ng_node.children.length)
    when Nokogiri::XML::Node::DOCUMENT_FRAG_NODE
      assert_equal(:fragment, node[:type])
      assert_equal(
        node[:children].length,
        ng_node.children.length,
        "Fragment node has wrong number of children #{ng_node.children.map(&:name)} in #{@test[:data]}",
      )
    when Nokogiri::XML::Node::DTD_NODE
      assert_equal(:doctype, node[:type])
      assert_equal(node[:name], ng_node.name)
      assert_equal_or_nil(node[:public_id], ng_node.external_id)
      assert_equal_or_nil(node[:system_id], ng_node.system_id)
    else
      flunk("Unknown node type #{ng_node.type} (expected #{node[:type]})")
    end
  end

  def run_test
    options = {
      max_errors: -1,
      parse_noscript_content_as_text: @test_script_on,
    }

    if @test[:context]
      # this is a fragment test
      if @test_context_node
        # run the test using a context Element
        if @test[:context].length > 1
          # the test is in a foreign context
          doc = Nokogiri::HTML5::Document.parse("<!DOCTYPE html><math></math><svg></svg>")
          foreign_el = doc.at_css(@test[:context].first)
          context_node_name = @test[:context].last
          context_node = foreign_el.add_child("<#{context_node_name}></#{context_node_name}>").first
        else
          # the test is not in a foreign context
          doc = Nokogiri::HTML5::Document.new
          context_node = doc.create_element(@test[:context].first)
        end
        doc = Nokogiri::HTML5::DocumentFragment.new(doc, @test[:data], context_node, **options)
      else
        # run the test using a tag name
        ctx = @test[:context].join(":")
        doc = Nokogiri::HTML5::Document.new
        doc = Nokogiri::HTML5::DocumentFragment.new(doc, @test[:data], ctx, **options)
      end
    else
      doc = Nokogiri::HTML5.parse(@test[:data], **options)
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
      next unless exp_child.key?(:children)

      exp_nodes << exp_child
      act_nodes << act_child
      children << 0
    end

    # Test the errors.
    errpayload = doc.errors.map(&:to_s).join("\n")
    assert_equal(
      @test[:errors].length,
      doc.errors.length,
      "Expected #{@test[:errors].length} errors for #{@test[:data]}, found:\n#{errpayload}",
    )

    # The new, standardized tokenizer errors live in @test[:new_errors]. Let's
    # match each one to exactly one error in doc.errors. Unfortunately, the
    # tests specify the column the error is detected, _not_ the column of the
    # start of the problematic HTML (e.g., the start of a character reference
    # or <![CDATA[) the way gumbo does. So check that Gumbo's column is no
    # later than the error's column.
    errors = doc.errors.map { |err| { line: err.line, column: err.column, code: err.str1 } }
    errors.reject! { |err| err[:code] == "generic-parser" }
    error_regex = /^\((?<line>\d+):(?<column>\d+)(?:-\d+:\d+)?\) (?<code>.*)$/
    @test[:new_errors].each do |err|
      assert_match(error_regex, err, "New error format does not match: #{mu_pp(err)}")
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
      # refute_nil(idx, "Expected to find error #{code} at #{line}:#{column}")
      assert_equal(0, idx, "Expected to find error #{code} at #{line}:#{column} in #{@test[:data]}")
      errors.delete_at(idx)
    end
  end
end

module Html5libTestCaseParser
  class BadHtml5libFormat < RuntimeError; end

  def self.parse_test(test_data)
    test = { script: :both }
    index = /(?:^#errors\n|\n#errors\n)/ =~ test_data
    raise(BadHtml5libFormat, "Expected #errors in\n#{test_data}") if index.nil?

    skip_amount = $LAST_MATCH_INFO[0].length
    # Omit the final new line
    test[:data] = test_data[0...index]

    # Process the rest line by line
    lines = test_data[index + skip_amount..-1].split("\n")
    index = lines.find_index do |line|
      line == "#document-fragment" ||
        line == "#document" ||
        line == "#script-off" ||
        line == "#script-on" ||
        line == "#new-errors"
    end
    raise(BadHtml5libFormat, "Expected #document") if index.nil?

    test[:errors] = lines[0...index]
    test[:new_errors] = []
    if lines[index] == "#new-errors"
      index += 1
      until ["#document-fragment", "#document", "#script-off", "#script-on"].include?(lines[index])
        test[:new_errors] << lines[index]
        index += 1
      end
    end

    if lines[index] == "#document-fragment"
      test[:context] = lines[index + 1].chomp.split(" ", 2)
      index += 2
    end
    raise(BadHtml5libFormat, "failed to find fragment: #{index}: #{lines[index]}") if test_data.include?("#document-fragment") && test[:context].nil?

    if lines[index] =~ /#script-(on|off)/
      test[:script] = $LAST_MATCH_INFO[1].to_sym
      index += 1
    end

    raise(BadHtml5libFormat, "Expected #document, got #{lines[index]}") unless lines[index] == "#document"

    index += 1

    document = {
      type: test[:context] ? :fragment : :document,
      children: [],
    }
    open_nodes = [document]
    test[:raw] = []
    while index < lines.length
      raise(BadHtml5libFormat, "Expected '| ' but got #{lines[index]}") unless /^\| ( *)([^ ].*$)/ =~ lines[index]

      test[:raw] << lines[index]

      depth = $LAST_MATCH_INFO[1].length
      if depth.odd?
        raise(BadHtml5libFormat, "Invalid nesting depth")
      else
        depth /= 2
      end
      raise(BadHtml5libFormat, "Too deep") if depth >= open_nodes.length

      node = {}
      node_text = $LAST_MATCH_INFO[2]
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
        node[:name] = $LAST_MATCH_INFO[1]
        node[:public_id] = $LAST_MATCH_INFO[2].nil? || $LAST_MATCH_INFO[2].empty? ? nil : $LAST_MATCH_INFO[2]
        node[:system_id] = $LAST_MATCH_INFO[3].nil? || $LAST_MATCH_INFO[3].empty? ? nil : $LAST_MATCH_INFO[3]
      elsif node_text.start_with?("<!-- ")
        loop do
          break if lines[index].end_with?(" -->")

          index += 1
          node_text << "\n" + lines[index]
        end
        node[:type] = :comment
        node[:contents] = node_text[5..-5]
      elsif /^<(svg |math )?(.+)>$/ =~ node_text
        node[:type] = :element
        node[:ns] = $LAST_MATCH_INFO[1].nil? ? nil : $LAST_MATCH_INFO[1].rstrip
        node[:tag] = $LAST_MATCH_INFO[2]
        node[:attributes] = []
        node[:children] = []
      elsif /^([^ ]+ )?([^=]+)="(.*)"$/ =~ node_text
        node[:type] = :attribute
        node[:ns] = $LAST_MATCH_INFO[1].nil? ? nil : $LAST_MATCH_INFO[1].rstrip
        node[:name] = $LAST_MATCH_INFO[2]
        node[:value] = $LAST_MATCH_INFO[3]
      elsif node_text == "content"
        node[:type] = :template
      else
        raise(BadHtml5libFormat, "Unexpected node_text: #{node_text}")
      end

      if node[:type] == :attribute
        raise(BadHtml5libFormat, "depth #{depth} != #{open_nodes.length}") unless depth == open_nodes.length - 1
        raise(BadHtml5libFormat, "type :#{open_nodes[-1][:type]} != :element") unless open_nodes[-1][:type] == :element
        raise(BadHtml5libFormat, "element has children") unless open_nodes[-1][:children].empty?

        open_nodes[-1][:attributes] << node
      elsif node[:type] == :template
        raise(BadHtml5libFormat, "depth #{depth} != #{open_nodes.length}") unless depth == open_nodes.length - 1
        raise(BadHtml5libFormat, "type :#{open_nodes[-1][:type]} != :element") unless open_nodes[-1][:type] == :element
        raise(BadHtml5libFormat, "tag :#{open_nodes[-1][:tag]} != template") unless open_nodes[-1][:tag] == "template"
        raise(BadHtml5libFormat, "template has children before the 'content'") unless open_nodes[-1][:children].empty?

        # Hack. We want the children of this template node to be reparented as
        # children of the template element.
        # XXX: Template contents are _not_ supposed to be children of the
        # template, but we currently mishandle this.
        open_nodes << open_nodes[-1]
      else
        open_nodes[depth][:children] << node
        open_nodes[depth + 1..-1] = []
        if node[:type] == :element
          open_nodes << node
        end
      end
      index += 1
    end
    test[:document] = document
    test
  end

  def self.generate_tests
    tc_path = File.expand_path("../../html5lib-tests/tree-construction", __FILE__)
    Dir[File.join(tc_path, "*.dat")].each do |path|
      test_name = "TestHtml5TreeConstruction" + File.basename(path, ".dat")
        .split(/[_-]/)
        .map(&:capitalize)
        .join("")
      tests = []
      File.open(path, "r", encoding: "UTF-8") do |f|
        f.each("\n\n#data\n") do |test_data|
          if test_data.start_with?("#data\n")
            test_data = test_data[6..-1]
          end
          if test_data.end_with?("\n\n#data\n")
            test_data = test_data[0..-9]
          end
          begin
            tests << parse_test(test_data)
          rescue BadHtml5libFormat => e
            warn("WARNING: #{path} is an invalid format: #{e.message}")
          end
        end
      end

      klass = Class.new(TestHtml5TreeConstructionBase) do
        tests.each_with_index do |test, index|
          if test[:script] == :both || test[:script] == :off
            define_method "test_#{index}__script_off" do
              @test = test
              @index = index
              @test_script_on = false
              @test_context_node = false
              run_test
            end
          end

          if test[:script] == :both || test[:script] == :on
            define_method "test_#{index}__script_on" do
              @test = test
              @index = index
              @test_script_on = true
              @test_context_node = false
              run_test
            end
          end

          if test[:context]
            if test[:script] == :both || test[:script] == :off
              define_method "test_#{index}__script_off__with_node" do
                @test = test
                @index = index
                @test_script_on = false
                @test_context_node = true
                run_test
              end
            end

            if test[:script] == :both || test[:script] == :on
              define_method "test_#{index}__script_on__with_node" do
                @test = test
                @index = index
                @test_script_on = true
                @test_context_node = true
                run_test
              end
            end
          end
        end
      end
      Object.const_set(test_name, klass)
    end
  end
end

Html5libTestCaseParser.generate_tests if Nokogiri.uses_gumbo?
