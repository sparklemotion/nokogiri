require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))
require File.join(File.dirname(__FILE__),"load_files")

class TestPreserved < Nokogiri::TestCase
  def assert_roundtrip str
    doc = Nokogiri.Hpricot(str)
    yield doc if block_given?
    str2 = doc.to_original_html
    [*str].zip([*str2]).each do |s1, s2|
      assert_equal s1, s2
    end
  end

  def assert_html str1, str2
    doc = Nokogiri.Hpricot(str2)
    yield doc if block_given?
    assert_equal str1, doc.to_original_html
  end

  ####
  # Not supporting to_original_html
  #def test_simple
  #  str = "<p>Hpricot is a <b>you know <i>uh</b> fine thing.</p>"
  #  assert_html str, str
  #  assert_html "<p class=\"new\">Hpricot is a <b>you know <i>uh</b> fine thing.</p>", str do |doc|
  #    (doc/:p).set('class', 'new')
  #  end
  #end

  ####
  # Not supporting to_original_html
  #def test_parent
  #  str = "<html><base href='/'><head><title>Test</title></head><body><div id='wrap'><p>Paragraph one.</p><p>Paragraph two.</p></div></body></html>"
  #  assert_html str, str
  #  assert_html "<html><base href='/'><body><div id=\"all\"><div><p>Paragraph one.</p></div><div><p>Paragraph two.</p></div></div></body></html>", str do |doc|
  #    (doc/:head).remove
  #    (doc/:div).set('id', 'all')
  #    (doc/:p).wrap('<div></div>')
  #  end
  #end

  # Not really a valid test.  If libxml can figure out the encoding of the file,
  # it will use that encoding, otherwise it uses the &#xwhatever so that no data
  # is lost.
  #
  # libxml on OSX can't figure out the encoding, so this tests passes.  linux
  # can figure out the encoding, so it fails.
  #def test_escaping_of_contents
  #  doc = Nokogiri.Hpricot(TestFiles::BOINGBOING)
  #  assert_equal "Fukuda&#x2019;s Automatic Door opens around your body as you pass through it. The idea is to save energy and keep the room clean.", doc.at("img[@alt='200606131240']").next.to_s.strip
  #end

  ####
  # Modified.  No.
  #def test_files
  #  assert_roundtrip TestFiles::BASIC
  #  assert_roundtrip TestFiles::BOINGBOING
  #  assert_roundtrip TestFiles::CY0
  #end

  ####
  # Modified..  When calling "to_html" on the document, proper html/doc tags
  # are produced too.
  def test_escaping_of_attrs
    # ampersands in URLs
    str = %{<a href="http://google.com/search?q=nokogiri&amp;l=en">Google</a>}
    link = (doc = Nokogiri.Hpricot(str)).at(:a)
    assert_equal "http://google.com/search?q=nokogiri&l=en", link['href']
    assert_equal "http://google.com/search?q=nokogiri&l=en", link.get_attribute('href')
    assert_equal "http://google.com/search?q=nokogiri&l=en", link.raw_attributes['href']
    assert_equal str, link.to_html

    # alter the url
    link['href'] = "javascript:alert(\"AGGA-KA-BOO!\")"
    assert_equal %{<a href="javascript:alert(&quot;AGGA-KA-BOO!&quot;)">Google</a>}, link.to_html.gsub(/%22/, '&quot;')
  end
end
