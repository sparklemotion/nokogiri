# encoding: utf-8
require 'nokogumbo'
require 'minitest/autorun'

class TestNokogumbo < Minitest::Test
  def test_element_text
    doc = Nokogiri::HTML5(buffer)
    assert_equal "content", doc.at('span').text
  end

  def test_element_cdata_textarea
    doc = Nokogiri::HTML5(buffer)
    assert_equal "foo<x>bar", doc.at('textarea').text.strip
  end

  def test_element_cdata_script
    doc = Nokogiri::HTML5.fragment(buffer)
    assert_equal true, doc.document.html?
    assert_equal "<script> if (a < b) alert(1) </script>", doc.at('script').to_s
  end

  def test_attr_value
    doc = Nokogiri::HTML5(buffer)
    assert_equal "utf-8", doc.at('meta')['charset']
  end

  def test_comment
    doc = Nokogiri::HTML5(buffer)
    assert_equal " test comment ", doc.xpath('//comment()').text
  end

  def test_unknown_element
    doc = Nokogiri::HTML5(buffer)
    assert_equal "main", doc.at('main').name
  end

  def test_IO
    require 'stringio'
    doc = Nokogiri::HTML5(StringIO.new(buffer))
    assert_equal 'textarea', doc.at('form').element_children.first.name
  end

  def test_nil
    doc = Nokogiri::HTML5(nil)
    assert_equal 1, doc.search('body').count
  end

  def test_html5_doctype
    doc = Nokogiri::HTML5.parse("<!DOCTYPE html><html></html>")
    assert_match(/<!DOCTYPE html>/, doc.to_html)
  end

  def test_fragment_no_errors
    doc = Nokogiri::HTML5.fragment("no missing DOCTYPE errors", max_errors: 10)
    assert_equal 0, doc.errors.length
  end

  # This should be deleted when `:max_parse_errors` is removed.
  def test_fragment_max_parse_errors
    doc = Nokogiri::HTML5.fragment("testing deprecated :max_parse_errors", max_parse_errors: 10)
    assert_equal 0, doc.errors.length
  end

  def test_fragment_head
    doc = Nokogiri::HTML5.fragment(buffer[/<head>(.*?)<\/head>/m, 1])
    assert_equal "hello world", doc.xpath('title').text
    assert_equal "utf-8", doc.xpath('meta').first['charset']
  end

  def test_fragment_body
    doc = Nokogiri::HTML5.fragment(buffer[/<body>(.*?)<\/body>/m, 1])
    assert_equal '<span>content</span>', doc.xpath('main/span').to_xml
    assert_equal " test comment ", doc.xpath('comment()').text
  end

  def test_xlink_attribute
    source = <<-EOF.gsub(/^ {6}/, '')
      <!DOCTYPE html>
      <svg xmlns="http://www.w3.org/2000/svg">
        <a xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="#s1"/>
      </svg>
    EOF
    doc = Nokogiri::HTML5.parse(source)
    a = doc.at_xpath('/html/body/svg:svg/svg:a')
    refute_nil a
    refute_nil a['xlink:href']
    refute_nil a['xmlns:xlink']
  end

  def test_xlink_attribute_fragment
    source = <<-EOF.gsub(/^ {6}/, '')
      <svg xmlns="http://www.w3.org/2000/svg">
        <a xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="#s1"/>
      </svg>
    EOF
    doc = Nokogiri::HTML5.fragment(source)
    a = doc.at_xpath('svg:svg/svg:a')
    refute_nil a
    refute_nil a['xlink:href']
    refute_nil a['xmlns:xlink']
  end

  def test_template
    source = <<-EOF.gsub(/^ {6}/, '')
      <template id="productrow">
        <tr>
          <td class="record"></td>
          <td></td>
        </tr>
      </template>
    EOF
    doc = Nokogiri::HTML5.fragment(source)
    template = doc.at('template')
    assert_equal "productrow", template['id']
    assert_equal "record", template.at('td')['class']
  end

  def test_root_comments
    doc = Nokogiri::HTML5("<!DOCTYPE html><!-- start --><html></html><!-- -->")
    assert_equal ["html", "comment", "html", "comment"], doc.children.map(&:name)
  end

  def test_parse_errors
    doc = Nokogiri::HTML5("<!DOCTYPE html><html><!-- -- --></a>", max_errors: 10)
    assert_equal doc.errors.length, 2
    doc = Nokogiri::HTML5("<!DOCTYPE html><html>", max_errors: 10)
    assert_empty doc.errors
  end

  def test_max_errors
    # This document contains 2 parse errors, but we force limit to 1.
    doc = Nokogiri::HTML5("<!DOCTYPE html><html><!-- -- --></a>", max_errors: 1)
    assert_equal 1, doc.errors.length
    doc = Nokogiri::HTML5("<!DOCTYPE html><html>", max_errors: 1)
    assert_empty doc.errors
  end

  def test_default_max_errors
    # This document contains 200 parse errors, but default limit is 0.
    doc = Nokogiri::HTML5("<!DOCTYPE html><html>" + "</p>" * 200)
    assert_equal 0, doc.errors.length
  end

  def test_parse_fragment_errors
    doc = Nokogiri::HTML5.fragment("<\r\n", max_errors: 10)
    refute_empty doc.errors
  end

  def test_fragment_max_errors
    # This fragment contains 3 parse errors, but we force limit to 1.
    doc = Nokogiri::HTML5.fragment("<!-- -- --></a>", max_errors: 1)
    assert_equal 1, doc.errors.length
  end

  def test_fragment_default_max_errors
    # This fragment contains 200 parse errors, but default limit is 0.
    doc = Nokogiri::HTML5.fragment("</p>" * 200)
    assert_equal 0, Nokogumbo::DEFAULT_MAX_ERRORS
    assert_equal 0, doc.errors.length
  end

  def test_default_max_depth_parse
    assert_raises ArgumentError do
      depth = Nokogumbo::DEFAULT_MAX_TREE_DEPTH + 1
      Nokogiri::HTML5('<!DOCTYPE html><html><body>' + '<div>' * (depth - 2))
    end
  end

  def test_default_max_depth_fragment
    assert_raises ArgumentError do
      depth = Nokogumbo::DEFAULT_MAX_TREE_DEPTH + 1
      Nokogiri::HTML5.fragment('<div>' * depth)
    end
  end

  def test_max_depth_parse
    depth = 10
    html = '<!DOCTYPE html><html><body>' + '<div>' * (depth - 2)
    assert_raises ArgumentError do
      Nokogiri::HTML5(html, max_tree_depth: depth - 1)
    end

    begin
      Nokogiri::HTML5(html, max_tree_depth: depth)
      pass
    rescue ArgumentError
      flunk "Expected document parse to succeed"
    end
  end

  def test_max_depth_fragment
    depth = 10
    html = '<div>' * depth
    assert_raises ArgumentError do
      Nokogiri::HTML5.fragment(html, max_tree_depth: depth - 1)
    end

    begin
      Nokogiri::HTML5.fragment(html, max_tree_depth: depth)
      pass
    rescue ArgumentError
      flunk "Expected fragment parse to succeed"
    end
  end


  def test_document_encoding
    html = <<-TEXT
      <html>
        <head>
          <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        </head>
        <body>
          Кирилические символы
        </body>
      </html>
    TEXT
    doc = Nokogiri::HTML5.parse(html)
    assert_equal "UTF-8", doc.encoding
    assert_equal "Кирилические символы", doc.at('body').text.gsub(/\n\s+/,'')
  end

  def test_line_numbers
    doc = Nokogiri::HTML5(buffer)
    assert_includes [0, 8], doc.at('h1').line
    assert_includes [0, 10], doc.at('span').line
  end

private

  def buffer
    <<-EOF.gsub(/^      /, '')
      <html>
        <head>
          <meta charset="utf-8"/>
          <title>hello world</title>
          <script> if (a < b) alert(1) </script>
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
  end

end
