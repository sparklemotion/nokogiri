$:.push('lib', 'work')

require 'nokogumbo'
require 'test/unit'

class TestNokogumbo < Test::Unit::TestCase
  def setup
    @buffer = <<-EOF.gsub(/^    /, '')
    <html>
      <head>
        <meta charset="utf-8"/>
        <title>hello world</title>
      </head>
      <body>
        <h1>hello world</h1>
        <main>
          <span>content</span>
        </main>
        <!-- test comment -->
        <form>
          <textarea>foo<x>bar</textarea>
        </form>
      </body>
    </html>
    EOF
    @doc = Nokogiri::HTML5(@buffer)
  end

  def test_element_text
    assert_equal "content", @doc.at('span').text
  end

  def test_element_cdata
    assert_equal "foo<x>bar", @doc.at('textarea').text.strip
  end

  def test_attr_value
    assert_equal "utf-8", @doc.at('meta')['charset']
  end

  def test_comment
    assert_equal " test comment ", @doc.xpath('//comment()').text
  end

  def test_unknown_element
    assert_equal "main", @doc.at('main').name
  end

  if ''.respond_to? 'encoding'
    def test_macroman_encoding
      mac="<span>\xCA</span>".force_encoding('macroman')
      doc = Nokogiri::HTML5(mac)
      assert_equal '<span>&#xA0;</span>', doc.at('span').to_xml
    end

    def test_iso8859_encoding
      iso8859="<span>Se\xF2or</span>".force_encoding(Encoding::ASCII_8BIT)
      doc = Nokogiri::HTML5(iso8859)
      assert_equal '<span>Se&#xF2;or</span>', doc.at('span').to_xml
    end
  end

  def test_html5_doctype
    doc = Nokogumbo.parse("<!DOCTYPE html><html></html>")
    assert_match /<!DOCTYPE html>/, doc.to_html
  end
end
