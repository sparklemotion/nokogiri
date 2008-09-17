require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TestNokogiri < Nokogiri::TestCase
  def test_xml?
    doc = Nokogiri.parse(File.read(XML_FILE))
    assert doc.xml?
    assert !doc.html?
  end

  def test_html?
    doc = Nokogiri.parse(File.read(HTML_FILE))
    assert !doc.xml?
    assert doc.html?
  end

  def test_nokogiri_method_with_html
    doc1 = Nokogiri(File.read(HTML_FILE))
    doc2 = Nokogiri.parse(File.read(HTML_FILE))
    assert_equal doc1.serialize, doc2.serialize
  end

  def test_nokogiri_method_with_block
    doc = Nokogiri { b "bold tag" }
    assert_equal('<b>bold tag</b>', doc.to_html.chomp)
  end

  def test_make_with_html
    doc = Nokogiri.make("<b>bold tag</b>")
    assert_equal('<b>bold tag</b>', doc.to_html.chomp)
  end

  def test_make_with_block
    doc = Nokogiri.make { b "bold tag" }
    assert_equal('<b>bold tag</b>', doc.to_html.chomp)
  end
end
