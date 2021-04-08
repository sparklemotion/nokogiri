# encoding: utf-8
require 'nokogumbo'
require 'minitest/autorun'

class TestAPI < Minitest::Test
  # https://github.com/web-platform-tests/wpt/blob/master/html/syntax/serializing-html-fragments/initial-linefeed-pre.html
  def initial_linefeed_pre
    @initial_linefeed_pre ||= begin
      html = <<-EOF.gsub(/^        /, '').freeze
        <!DOCTYPE html>
        <div id="outer">
        <div id="inner">
        <pre id="pre1">
        x</pre>
        <pre id="pre2">
        
        x</pre>
        <textarea id="textarea1">
        x</textarea>
        <textarea id="textarea2">
        
        x</textarea>
        <listing id="listing1">
        x</listing>
        <listing id="listing2">
        
        x</listing>
        </div>
        </div>
        EOF
      Nokogiri::HTML5(html)
    end
    @initial_linefeed_pre
  end

  def test_initial_linefeed_pre_outer
    expected = %{\n<div id="inner">\n<pre id="pre1">x</pre>\n<pre id="pre2">\nx</pre>\n<textarea id="textarea1">x</textarea>\n<textarea id="textarea2">\nx</textarea>\n<listing id="listing1">x</listing>\n<listing id="listing2">\nx</listing>\n</div>\n}
    outer = initial_linefeed_pre.xpath('//div[@id="outer"]')[0]
    refute_nil outer
    assert_equal expected, outer.inner_html
  end

  def test_initial_linefeed_pre_inner
    expected = %{\n<pre id="pre1">x</pre>\n<pre id="pre2">\nx</pre>\n<textarea id="textarea1">x</textarea>\n<textarea id="textarea2">\nx</textarea>\n<listing id="listing1">x</listing>\n<listing id="listing2">\nx</listing>\n}
    inner = initial_linefeed_pre.at('//div[@id="inner"]')
    refute_nil inner
    assert_equal expected, inner.inner_html
  end

  %w[pre textarea listing].each do |tag|
    define_method("test_initial_linefeed_#{tag}1".to_sym) do
      elem = initial_linefeed_pre.at("//*[@id=\"#{tag}1\"]")
      refute_nil elem
      assert_equal 'x', elem.inner_html
    end

    define_method("test_initial_linefeed_#{tag}2".to_sym) do
      elem = initial_linefeed_pre.at("//*[@id=\"#{tag}2\"]")
      refute_nil elem
      assert_equal "\nx", elem.inner_html
    end
  end

  # https://github.com/web-platform-tests/wpt/blob/master/html/syntax/serializing-html-fragments/outerHTML.html
  ELEMENTS_WITH_END_TAG = [
    "a",
    "abbr",
    "address",
    "article",
    "aside",
    "audio",
    "b",
    "bdi",
    "bdo",
    "blockquote",
    "body",
    "button",
    "canvas",
    "caption",
    "cite",
    "code",
    "colgroup",
    "command",
    "datalist",
    "dd",
    "del",
    "details",
    "dfn",
    "dialog",
    "div",
    "dl",
    "dt",
    "em",
    "fieldset",
    "figcaption",
    "figure",
    "footer",
    "form",
    "h1",
    "h2",
    "h3",
    "h4",
    "h5",
    "h6",
    "head",
    "header",
    "hgroup",
    "html",
    "i",
    "iframe",
    "ins",
    "kbd",
    "label",
    "legend",
    "li",
    "map",
    "mark",
    "menu",
    "meter",
    "nav",
    "noscript",
    "object",
    "ol",
    "optgroup",
    "option",
    "output",
    "p",
    "pre",
    "progress",
    "q",
    "rp",
    "rt",
    "ruby",
    "s",
    "samp",
    "script",
    "section",
    "select",
    "small",
    "span",
    "strong",
    "style",
    "sub",
    "summary",
    "sup",
    "table",
    "tbody",
    "td",
    "textarea",
    "tfoot",
    "th",
    "thead",
    "time",
    "title",
    "tr",
    "u",
    "ul",
    "var",
    "video",
    "data",
  ].freeze

  ELEMENTS_WITHOUT_END_TAG = [
    "area",
    "base",
    "br",
    "col",
    "embed",
    "hr",
    "img",
    "input",
    "keygen",
    "link",
    "meta",
    "param",
    "source",
    "track",
    "wbr",
  ]

  ELEMENTS_WITH_END_TAG.each do |tag|
    define_method("test_outer_html_#{tag}".to_sym) do
      doc = Nokogiri::HTML5::Document.new
      child = Nokogiri::XML::Element.new(tag, doc)
      assert_equal "<#{tag}></#{tag}>", child.serialize(save_with: 0)
    end
  end

  ELEMENTS_WITHOUT_END_TAG.each do |tag|
    define_method("test_outer_html_#{tag}".to_sym) do
      doc = Nokogiri::HTML5::Document.new
      child = Nokogiri::XML::Element.new(tag, doc)
      assert_equal "<#{tag}>", child.serialize(save_with: 0)
    end
  end

  # https://github.com/web-platform-tests/wpt/blob/master/html/syntax/serializing-html-fragments/serializing.html
  def serializing_test_data
    @serializing_test_data ||= begin
      html = <<-EOF.gsub(/        /, '')
        <!DOCTYPE html>
        <div id="test" style="display:none">
        <span></span>
        <span><a></a></span>
        <span><a b=c></a></span>
        <span><a b='c'></a></span>
        <span><a b='&'></a></span>
        <span><a b='&nbsp;'></a></span>
        <span><a b='"'></a></span>
        <span><a b="<"></a></span>
        <span><a b=">"></a></span>
        <span><svg xlink:href="a"></svg></span>
        <span><svg xmlns:svg="test"></svg></span>
        <span>a</span>
        <span>&amp;</span>
        <span>&nbsp;</span>
        <span>&lt;</span>
        <span>&gt;</span>
        <span>&quot;</span>
        <span><style><&></style></span>
        <span><script type="test"><&></script></span>
        <script type="test"><&></script>
        <span><xmp><&></xmp></span>
        <span><iframe><&></iframe></span>
        <span><noembed><&></noembed></span>
        <span><noframes><&></noframes></span>
        <span><noscript><&></noscript></span>
        <span><!--data--></span>
        <span><a><b><c></c></b><d>e</d><f><g>h</g></f></a></span>
        <span b=c></span>
        </div>
        EOF
      Nokogiri::HTML5(html).xpath('/html/body/div/*')
    end
    @serializing_test_data
  end

  EXPECTED = [
    ["", "<span></span>"],
    ["<a></a>", "<span><a></a></span>"],
    ["<a b=\"c\"></a>", "<span><a b=\"c\"></a></span>"],
    ["<a b=\"c\"></a>", "<span><a b=\"c\"></a></span>"],
    ["<a b=\"&amp;\"></a>", "<span><a b=\"&amp;\"></a></span>"],
    ["<a b=\"&nbsp;\"></a>", "<span><a b=\"&nbsp;\"></a></span>"],
    ["<a b=\"&quot;\"></a>", "<span><a b=\"&quot;\"></a></span>"],
    ["<a b=\"<\"></a>", "<span><a b=\"<\"></a></span>"],
    ["<a b=\">\"></a>", "<span><a b=\">\"></a></span>"],
    ["<svg xlink:href=\"a\"></svg>", "<span><svg xlink:href=\"a\"></svg></span>"],
    ["<svg xmlns:svg=\"test\"></svg>", "<span><svg xmlns:svg=\"test\"></svg></span>"],
    ["a", "<span>a</span>"],
    ["&amp;", "<span>&amp;</span>"],
    ["&nbsp;", "<span>&nbsp;</span>"],
    ["&lt;", "<span>&lt;</span>"],
    ["&gt;", "<span>&gt;</span>"],
    ["\"", "<span>\"</span>"],
    ["<style><&></style>", "<span><style><&></style></span>"],
    ["<script type=\"test\"><&><\/script>", "<span><script type=\"test\"><&><\/script></span>"],
    ["<&>", "<script type=\"test\"><&><\/script>"],
    ["<xmp><&></xmp>", "<span><xmp><&></xmp></span>"],
    ["<iframe><&></iframe>", "<span><iframe><&></iframe></span>"],
    ["<noembed><&></noembed>", "<span><noembed><&></noembed></span>"],
    ["<noframes><&></noframes>", "<span><noframes><&></noframes></span>"],
    ["<noscript><&></noscript>", "<span><noscript><&></noscript></span>"],
    ["<!--data-->", "<span><!--data--></span>"],
    ["<a><b><c></c></b><d>e</d><f><g>h</g></f></a>", "<span><a><b><c></c></b><d>e</d><f><g>h</g></f></a></span>"],
    ["", "<span b=\"c\"></span>"]
  ].freeze

  DOM_TESTS = [
    ['Attribute in the XML namespace',
      lambda do
        doc = Nokogiri::HTML5::Document.new
        span = Nokogiri::XML::Element.new('span', doc)
        svg = Nokogiri::XML::Element.new('svg', doc)
        span.add_child(svg)
        svg.add_namespace('xml', 'http://www.w3.org/XML/1998/namespace')
        svg['xml:foo'] = 'test'
        span
      end,
      '<svg xml:foo="test"></svg>',
      '<span><svg xml:foo="test"></svg></span>'],

    ["Attribute in the XML namespace with the prefix not set to xml:",
      lambda do
        doc = Nokogiri::HTML5::Document.new
        span = Nokogiri::XML::Element.new('span', doc)
        svg = Nokogiri::XML::Element.new('svg', doc)
        span.add_child(svg)
        svg['abc:foo'] = 'test'
        ns = svg.add_namespace('xml', 'http://www.w3.org/XML/1998/namespace')
        svg.attribute('abc:foo').namespace = ns
        span
      end,
      '<svg xml:foo="test"></svg>',
      '<span><svg xml:foo="test"></svg></span>'],

    ["Non-'xmlns' attribute in the xmlns namespace",
      lambda do
        doc = Nokogiri::HTML5::Document.new
        span = Nokogiri::XML::Element.new('span', doc)
        svg = Nokogiri::XML::Element.new('svg', doc)
        span.add_child(svg)
        svg.add_namespace('xmlns', 'http://www.w3.org/2000/xmlns/')
        svg['xmlns:foo'] = 'test'
        span
      end,
      '<svg xmlns:foo="test"></svg>',
      '<span><svg xmlns:foo="test"></svg></span>'],

    ["'xmlns' attribute in the xmlns namespace",
      lambda do
        doc = Nokogiri::HTML5::Document.new
        span = Nokogiri::XML::Element.new('span', doc)
        svg = Nokogiri::XML::Element.new('svg', doc)
        span.add_child(svg)
        svg.add_namespace('xmlns', 'http://www.w3.org/2000/xmlns/')
        svg['xmlns'] = 'test'
        span
      end,
      '<svg xmlns="test"></svg>',
      '<span><svg xmlns="test"></svg></span>'],

    ["Attribute in non-standard namespace",
      lambda do
        doc = Nokogiri::HTML5::Document.new
        span = Nokogiri::XML::Element.new('span', doc)
        svg = Nokogiri::XML::Element.new('svg', doc)
        span.add_child(svg)
        svg.add_namespace('abc', 'fake_ns')
        svg['abc:def'] = 'test'
        span
      end,
      '<svg abc:def="test"></svg>',
      '<span><svg abc:def="test"></svg></span>'],

    ["<span> starting with U+000A",
      lambda do
        doc = Nokogiri::HTML5::Document.new
        span = Nokogiri::XML::Element.new('span', doc)
        text = Nokogiri::XML::Text.new("\x0A", doc)
        span.add_child(text)
        span
      end,
      "\x0A",
      "<span>\x0A</span>"],
    #TODO: Processing instructions
  ]

  TEXT_ELEMENTS = %w[pre textarea listing]
  TEXT_TESTS = [
    ["<%text> context starting with U+000A",
      lambda do |tag|
        doc = Nokogiri::HTML5::Document.new
        elem = Nokogiri::XML::Element.new(tag, doc)
        text = Nokogiri::XML::Text.new("\x0A", doc)
        elem.add_child(text)
        elem
      end,
     "\x0A",
     "<%text>\x0A</%text>"],

    ["<%text> context not starting with U+000A",
      lambda do |tag|
        doc = Nokogiri::HTML5::Document.new
        elem = Nokogiri::XML::Element.new(tag, doc)
        text = Nokogiri::XML::Text.new("a\x0A", doc)
        elem.add_child(text)
        elem
      end,
     "a\x0A",
     "<%text>a\x0A</%text>"],

    ["<%text> non-context starting with U+000A",
      lambda do |tag|
        doc = Nokogiri::HTML5::Document.new
        elem = Nokogiri::XML::Element.new(tag, doc)
        span = Nokogiri::XML::Element.new('span', doc)
        text = Nokogiri::XML::Text.new("\x0A", doc)
        elem.add_child(text)
        span.add_child(elem)
        span
      end,
     "<%text>\x0A</%text>",
     "<span><%text>\x0A</%text></span>"],

    ["<%text> non-context not starting with U+000A",
      lambda do |tag|
        doc = Nokogiri::HTML5::Document.new
        elem = Nokogiri::XML::Element.new(tag, doc)
        span = Nokogiri::XML::Element.new('span', doc)
        text = Nokogiri::XML::Text.new("a\x0A", doc)
        elem.add_child(text)
        span.add_child(elem)
        span
      end,
     "<%text>a\x0A</%text>",
     "<span><%text>a\x0A</%text></span>"],
  ]

  VOID_ELEMENTS = [
    "area", "base", "basefont", "bgsound", "br", "col", "embed",
    "frame", "hr", "img", "input", "keygen", "link",
    "meta", "param", "source", "track", "wbr"
  ]
  VOID_TESTS = [
    ["Void context node",
      lambda do |tag|
        doc = Nokogiri::HTML5::Document.new
        Nokogiri::XML::Element.new(tag, doc)
      end,
      "",
      "<%void>"],

    ["void as first child with following siblings",
      lambda do |tag|
        doc = Nokogiri::HTML5::Document.new
        span = Nokogiri::XML::Element.new('span', doc)
        span.add_child(Nokogiri::XML::Element.new(tag, doc))
        span.add_child(Nokogiri::XML::Element.new('a', doc))
          .add_child(Nokogiri::XML::Text.new('test', doc))
        span.add_child(Nokogiri::XML::Element.new('b', doc))
        span
      end,
      "<%void><a>test</a><b></b>",
      "<span><%void><a>test</a><b></b></span>"
     ],

    ["void as second child with following siblings",
      lambda do |tag|
        doc = Nokogiri::HTML5::Document.new
        span = Nokogiri::XML::Element.new('span', doc)
        span.add_child(Nokogiri::XML::Element.new('a', doc))
          .add_child(Nokogiri::XML::Text.new('test', doc))
        span.add_child(Nokogiri::XML::Element.new(tag, doc))
        span.add_child(Nokogiri::XML::Element.new('b', doc))
        span
      end,
      "<a>test</a><%void><b></b>",
      "<span><a>test</a><%void><b></b></span>"
     ],
    ["void as last child with preceding siblings",
      lambda do |tag|
        doc = Nokogiri::HTML5::Document.new
        span = Nokogiri::XML::Element.new('span', doc)
        span.add_child(Nokogiri::XML::Element.new('a', doc))
          .add_child(Nokogiri::XML::Text.new('test', doc))
        span.add_child(Nokogiri::XML::Element.new('b', doc))
        span.add_child(Nokogiri::XML::Element.new(tag, doc))
        span
      end,
      "<a>test</a><b></b><%void>",
      "<span><a>test</a><b></b><%void></span>"
    ],
  ]


  # Generate tests
  def self.cross_map(a1, a2)
    rv = []
    a1.each do |a1_elem|
      a2.each do |a2_elem|
        rv << yield(a1_elem, a2_elem)
      end
    end
  end

  EXPECTED.each_with_index do |item, i|
    define_method("test_serializing_html_innerHTML_#{i}".to_sym) do
      assert_equal item[0], serializing_test_data[i].inner_html
    end

    define_method("test_serializing_html_outerHTML_#{i}".to_sym) do
      assert_equal item[1], serializing_test_data[i].serialize
    end
  end

  DOM_TESTS.each do |test|
    define_method("test_serializing_dom_innerHTML_#{test[0]}".to_sym) do
      elem = test[1].call
      refute_nil elem
      assert_equal test[2], elem.inner_html
    end

    define_method("test_serializing_dom_outerHTML_#{test[0]}".to_sym) do
      elem = test[1].call
      refute_nil elem
      assert_equal test[3], elem.serialize
    end
  end

  cross_map(TEXT_TESTS, TEXT_ELEMENTS) do |test_data, tag|
    define_method("test_serializing_text_innerHTML_#{test_data[0].gsub('%text', tag)}".to_sym) do
      assert_equal test_data[2].gsub('%text', tag), test_data[1].call(tag).inner_html
    end

    define_method("test_serialization_text_outerHTML_#{test_data[0].gsub('%text', tag)}".to_sym) do
      assert_equal test_data[3].gsub('%text', tag), test_data[1].call(tag).serialize
    end
  end

  cross_map(VOID_TESTS, VOID_ELEMENTS) do |test_data, tag|
    define_method("test_serializing_void_innerHTML_#{test_data[0]}_#{tag}".to_sym) do
      assert_equal test_data[2].gsub('%void', tag), test_data[1].call(tag).inner_html
    end

    define_method("test_serialization_void_outerHTML_#{test_data[0]}_#{tag}".to_sym) do
      assert_equal test_data[3].gsub('%void', tag), test_data[1].call(tag).serialize
    end
  end
end
