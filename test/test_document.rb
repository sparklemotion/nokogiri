require 'helper'

class DocumentTest < Nokogiri::TestCase
  def setup
    @xml = Nokogiri::XML.parse(File.read(XML_FILE))
    @html = Nokogiri::HTML.parse(File.read(HTML_FILE))
    assert @xml.xml?
    assert @html.html?
  end

  def test_search
    employees = @xml.search('//employee')
    assert_equal(5, employees.length)
  end

  def test_new
    xml = Nokogiri::Document.new
    assert xml.xml?

    html = Nokogiri::Document.new(:html)
    assert html.html?
  end

  def test_add_root_node
    html = Nokogiri::Document.new(:html)
    assert html.html?
    assert_nil html.root

    node = Nokogiri::Node.new('form')
    assert_nil node.root

    html.root = node
    assert_equal(node, html.root)
    assert_equal(node.root, node)
  end
end
