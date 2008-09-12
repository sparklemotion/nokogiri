require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TestDocument < Nokogiri::TestCase
  def setup
    @xml = Nokogiri::XML.parse(File.read(XML_FILE))
  end

  def test_xml?
    assert @xml.xml?
  end
end
