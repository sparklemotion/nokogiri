require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TestDocument < Nokogiri::TestCase
  def setup
    @xml = Nokogiri::XML.parse(File.read(XML_FILE))
    @html = Nokogiri::HTML.parse(File.read(HTML_FILE))
  end

  def test_xml?
    assert @xml.xml?
  end

  def test_html?
    assert @html.html?
  end
end
