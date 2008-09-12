require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TestNokogiri < Nokogiri::TestCase
  def test_xml?
    doc = Nokogiri.parse(File.read(XML_FILE))
    assert doc.xml?
    assert !doc.html?
  end
end
