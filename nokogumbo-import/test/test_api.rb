require 'nokogumbo'
require 'minitest/autorun'

class TestAPI < Minitest::Test
  def test_parse_convenience_methods
    html = '<!DOCTYPE html><p>hi'.freeze
    base = Nokogiri::HTML5::Document.parse(html)
    html5_parse = Nokogiri::HTML5.parse(html)
    html5 = Nokogiri::HTML5(html)
    str = base.to_html
    assert_equal str, html5_parse.to_html
    assert_equal str, html5.to_html
  end

  def test_fragment_convenience_methods
    frag = '<div><p>hi</div>'.freeze
    base = Nokogiri::HTML5::DocumentFragment.parse(frag)
    html5_fragment = Nokogiri::HTML5.fragment(frag)
    assert_equal base.to_html, html5_fragment.to_html
  end

  def test_url
    html = '<p>hi'
    url = 'http://example.com'
    doc = Nokogiri::HTML5::Document.parse(html, url, max_errors: 1)
    assert_equal url, doc.errors[0].file

    doc = Nokogiri::HTML5.parse(html, url, max_errors: 1)
    assert_equal url, doc.errors[0].file

    doc = Nokogiri::HTML5(html, url, max_errors: 1)
    assert_equal url, doc.errors[0].file
  end

  def test_parse_encoding
    utf8 = '<!DOCTYPE html><body><p>おはようございます'
    shift_jis = utf8.encode(Encoding::SHIFT_JIS)
    raw = shift_jis.dup
    raw.force_encoding(Encoding::ASCII_8BIT)

    assert_match(/おはようございます/, Nokogiri::HTML5(utf8).to_s)
    assert_match(/おはようございます/, Nokogiri::HTML5(shift_jis).to_s)
    refute_match(/おはようございます/, Nokogiri::HTML5(raw).to_s)

    assert_match(/おはようございます/, Nokogiri::HTML5(raw, nil, Encoding::SHIFT_JIS).to_s)
    assert_match(/おはようございます/, Nokogiri::HTML5.parse(raw, nil, Encoding::SHIFT_JIS).to_s)
    assert_match(/おはようございます/, Nokogiri::HTML5::Document.parse(raw, nil, Encoding::SHIFT_JIS).to_s)
  end

  def test_fragment_encoding
    utf8 = '<div><p>おはようございます</div>'
    shift_jis = utf8.encode(Encoding::SHIFT_JIS)
    raw = shift_jis.dup
    raw.force_encoding(Encoding::ASCII_8BIT)

    assert_match(/おはようございます/, Nokogiri::HTML5.fragment(utf8).to_s)
    assert_match(/おはようございます/, Nokogiri::HTML5.fragment(shift_jis).to_s)
    refute_match(/おはようございます/, Nokogiri::HTML5.fragment(raw).to_s)

    assert_match(/おはようございます/, Nokogiri::HTML5.fragment(raw, Encoding::SHIFT_JIS).to_s)
    assert_match(/おはようございます/, Nokogiri::HTML5::DocumentFragment.parse(raw, Encoding::SHIFT_JIS).to_s)
  end

  def test_fragment_serialization_encoding
    frag = Nokogiri::HTML5.fragment('<span>아는 길도 물어가라</span>')
    html = frag.serialize(encoding: 'US-ASCII')
    assert_equal '<span>&#xc544;&#xb294; &#xae38;&#xb3c4; &#xbb3c;&#xc5b4;&#xac00;&#xb77c;</span>', html
    frag = Nokogiri::HTML5.fragment(html)
    assert_equal '<span>아는 길도 물어가라</span>', frag.serialize
  end

  def test_serialization_encoding
    html = '<!DOCUMENT html><span>ฉันไม่พูดภาษาไทย</span>'
    doc = Nokogiri::HTML5(html)
    span = doc.at('/html/body/span')
    serialized = span.inner_html(encoding: 'US-ASCII')
    assert_match(/^(?:&#(?:\d+|x\h+);)*$/, serialized)
    assert_equal('ฉันไม่พูดภาษาไทย'.each_char.map(&:ord),
                 serialized.scan(/&#(\d+|x\h+);/).map do |s|
        s = s.first
        if s.start_with? 'x'
          s[1..-1].to_i(16)
        else
          s.to_i
        end
      end
    )

    doc2 = Nokogiri::HTML5(doc.serialize(encoding: 'Big5'))
    html2 = doc2.serialize(encoding: 'UTF-8')
    assert_match 'ฉันไม่พูดภาษาไทย', html2
  end

  %w[pre listing textarea].each do |tag|
    define_method("test_serialize_preserve_newline_#{tag}".to_sym) do
      doc = Nokogiri::HTML5("<!DOCTYPE html><#{tag}>\n\nContent</#{tag}>")
      html = doc.at("/html/body/#{tag}").serialize(preserve_newline: true)
      assert_equal "<#{tag}>\n\nContent</#{tag}>", html
    end

    define_method("test_inner_html_preserve_newline_#{tag}".to_sym) do
      doc = Nokogiri::HTML5("<!DOCTYPE html><#{tag}>\n\nContent</#{tag}>")
      html = doc.at("/html/body/#{tag}").inner_html(preserve_newline: true)
      assert_equal "\n\nContent", html
    end
  end

  def test_document_io
    html = StringIO.new('<!DOCTYPE html><span>test</span>', 'r')
    doc = Nokogiri::HTML5::Document.read_io(html)
    refute_nil doc.at_xpath('/html/body/span')
  end

  def test_document_memory
    html = '<!DOCTYPE html><span>test</span>'
    doc = Nokogiri::HTML5::Document.read_memory(html)
    refute_nil doc
    refute_nil doc.at_xpath('/html/body/span')
  end

  def test_document_io_failure
    html = '<!DOCTYPE html><span>test</span>'
    assert_raises(ArgumentError) { Nokogiri::HTML5::Document.read_io(html) }
  end

  def test_document_memory_failure
    html = StringIO.new('<!DOCTYPE html><span>test</span>', 'r')
    assert_raises(ArgumentError) { Nokogiri::HTML5::Document.read_memory(html) }
  end

  def test_document_parse_failure
    html = ['Neither a string, nor I/O']
    assert_raises(ArgumentError) { Nokogiri::HTML5::Document.parse(html) }
  end

  def test_ownership
    # Test that we don't change the passed in string, even if we need to
    # re-encode it.
    html = '<!DOCTYPE html><html></html>'.freeze
    refute_nil Nokogiri::HTML5.parse(html)

    iso8859_1 = html.encode(Encoding::ISO_8859_1).freeze
    refute_nil Nokogiri::HTML5.parse(iso8859_1)

    ascii_8bit = html.encode(Encoding::ASCII_8BIT).freeze
    refute_nil Nokogiri::HTML5.parse(ascii_8bit)
  end

  def test_fragment_from_node
    doc = Nokogiri.HTML5('<!DOCTYPE html><form><span></span></form>')
    span = doc.at_xpath('/html/body/form/span')
    refute_nil span
    frag = span.fragment('<form>Nested forms should be ignored</form>')
    assert frag.is_a?(Nokogiri::HTML5::DocumentFragment)
    assert_equal 1, frag.children.length
    nested_form = frag.at_xpath('form')
    assert_nil nested_form
    assert frag.children[0].text?
  end

  def test_fragment_from_node_no_form
    doc = Nokogiri.HTML5('<!DOCTYPE html><span></span></form>')
    span = doc.at_xpath('/html/body/span')
    refute_nil span
    frag = span.fragment('<form><span>Form should not be ignored</span></form>')
    assert frag.is_a?(Nokogiri::HTML5::DocumentFragment)
    assert_equal 1, frag.children.length
    form = frag.at_xpath('form')
    refute_nil form
  end

  def test_empty_fragment
    doc = Nokogiri.HTML5('<!DOCTYPE html><body>')
    frag = doc.fragment
    assert frag.is_a?(Nokogiri::HTML5::DocumentFragment)
    assert frag.children.empty?
  end
end
