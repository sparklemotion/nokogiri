require 'helper'

class TestNokogiri < Nokogiri::TestCase
  def test_xml?
    doc = Nokogiri.parse(File.read(XML_FILE))
    assert doc.xml?
    assert !doc.html?
  end

  def test_html?
    Nokogiri.parse(File.read(HTML_FILE)) do |doc|
      assert doc.html?
      assert !doc.xml?
    end
  end

  def test_read_memory
    assert Nokogiri.parse('<html><body></body></html>')
  end

  def test_root
    html_doc = Nokogiri.parse('<html><head><meta name=keywords content=nasty></head><body>Hello<br>World</html>')

    root = html_doc.root
    assert root
    assert_equal 'html', root.name
    head = root.child
    assert_equal 'head', head.name
    meta = head.child
    assert_equal 'meta', meta.name
    assert_equal 'keywords', meta[:name]
    assert_nil meta[:foo]

    body = head.next
    assert_equal 'body', body.name

    hello = body.child
    hello = hello.child if hello.name == 'p'
    assert_equal 'Hello', hello.content

    br = hello.next
    assert br
    assert_equal 'br', br.name

    world = br.next
    assert_equal 'World', world.content
  end
end
