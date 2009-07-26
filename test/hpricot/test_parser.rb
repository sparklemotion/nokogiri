require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))
require File.join(File.dirname(__FILE__),"load_files")

class TestParser < Nokogiri::TestCase
  include Nokogiri

  def test_set_attr
    @basic = Nokogiri.parse(TestFiles::BASIC)
    @basic.search('//p').set('class', 'para')
    assert_equal 4, @basic.search('//p').length
    assert_equal 4, @basic.search('//p').find_all { |x| x['class'] == 'para' }.length
  end

  def test_filter_by_attr
    @boingboing = Nokogiri.parse(TestFiles::BOINGBOING)

    # this link is escaped in the doc
    link = 'http://www.youtube.com/watch?v=TvSNXyNw26g&search=chris%20ware'
    assert_equal link, @boingboing.at("a[@href='#{link}']")['href']
  end

  def test_filter_contains
    @basic = Nokogiri.parse(TestFiles::BASIC)
    assert_equal '<title>Sample XHTML</title>', @basic.search("title:contains('Sample')").to_s.chomp
  end

  def test_get_element_by_id
    @basic = Nokogiri.parse(TestFiles::BASIC)
    assert_equal 'link1', @basic.at('#link1')['id']
    assert_equal 'link1', @basic.at('#body1').at('#link1')['id']
  end

  def test_get_element_by_tag_name
    @basic = Nokogiri.parse(TestFiles::BASIC)
    assert_equal 'link1', @basic.at('a')['id']
    assert_equal 'link1', @basic.at('body').at('#link1')['id']
  end

  def test_output_basic
    @basic = Nokogiri.parse(TestFiles::BASIC)
    @basic2 = Nokogiri.parse(@basic.inner_html)
    scan_basic @basic2
  end

  def test_scan_basic
    @basic = Nokogiri.parse(TestFiles::BASIC)
    scan_basic @basic
  end

  def scan_basic doc
    assert_not_equal doc.children.first.to_s, doc.children[1].to_s
    assert_equal 'link1', doc.at('#link1')['id']
    assert_equal 'link1', doc.at("p a")['id']
    assert_equal 'link1', (doc/:p/:a).first['id']
    assert_equal 'link1', doc.search('p').at('a')['id']

    assert_equal 'link2', (doc/'p').css('.ohmy').search('a').first['id']
    assert_equal((doc/'p')[2], (doc/'p').css('[text()="The third paragraph"]')[0])
    assert_equal 3, (doc/'p:not(.ohmy)').length

    assert_equal 'last final', (doc/'p[@class~="final"]').first.get_attribute('class')
    assert_equal 2, (doc/'p > a').length
    assert_equal 1, (doc/'p.ohmy > a').length
    assert_equal 2, (doc/'p / a').length
    assert_equal 2, (doc/'link ~ link').length
    assert_equal 3, (doc/'title ~ link').length
    assert_equal 5, (doc/"//p/text()").length
    assert_equal 6, (doc/"//p[a]//text()").length
    assert_equal 2, (doc/"//p/a/text()").length
  end

  def test_positional
    h = Nokogiri( "<div><br/><p>one</p><p>two</p></div>" )
    assert_equal "<p>one</p>", h.search("div/p:eq(1)").to_s.chomp # MODIFIED: eq(0) -> eq(1), and removed initial '//'
    assert_equal "<p>one</p>", h.search("div/p:first").to_s.chomp # MODIFIED: removed initial '//'
    assert_equal "<p>one</p>", h.search("div/p:first()").to_s.chomp # MODIFIED: removed initial '//'
  end

  def test_pace
    doc = Nokogiri(TestFiles::PACE_APPLICATION)
    assert_equal 'get', doc.at('form[@name=frmSect11]')['method']
  end

  def test_scan_boingboing
    @boingboing = Nokogiri.HTML(TestFiles::BOINGBOING)
    assert_equal 60, (@boingboing/'p.posted').length
    assert_equal 1, @boingboing.search("//a[@name='027906']").length
    assert_equal 3, @boingboing.search("a[text()*='Boing']").length
    assert_equal 1, @boingboing.search(
      "//h3[normalize-space(text())='College kids reportedly taking more smart drugs']"
    ).length
    assert_equal 0, @boingboing.search("h3[text()='College']").length
    assert_equal 60, @boingboing.search("h3").length
    assert_equal 59, @boingboing.search("//h3[normalize-space(text())!='College kids reportedly taking more smart drugs']").length
    assert_equal 211, @boingboing.search("p").length
  end

  def test_reparent
    doc = Nokogiri(%{<div id="blurb_1"></div>})
    div1 = doc.search('#blurb_1')
    div1.before('<div id="blurb_0"></div>')

    div0 = doc.search('#blurb_0')
    div0.before('<div id="blurb_a"></div>')

    assert_equal 'div', doc.at('#blurb_1').name
  end

  def test_siblings
    @basic = Nokogiri.parse(TestFiles::BASIC)
    t = @basic.at(:title)
    e = t.next_sibling
    assert_equal 'test1.css', e['href']
    assert_equal 'title', e.previous_sibling.name
  end

  def test_css_negation
    @basic = Nokogiri.parse(TestFiles::BASIC)
    assert_equal 3, (@basic/'p:not(.final)').length
  end

  def test_remove_attribute
    @basic = Nokogiri.parse(TestFiles::BASIC)
    (@basic/:p).each { |ele| ele.remove_attribute('class') }
    assert_equal 0, (@basic/'p[@class]').length
  end

  def test_abs_xpath
    @boingboing = Nokogiri.parse(TestFiles::BOINGBOING)
    assert_equal 60, @boingboing.search("/html/body//p[@class='posted']").length
    assert_equal 60, @boingboing.search("/*/body//p[@class='posted']").length
    assert_equal 18, @boingboing.search("//script").length
    divs = @boingboing.search("//script/../div")
    assert_equal 2,  divs.length
    imgs = @boingboing.search('//div/p/a/img')
    assert_equal 12, imgs.length
    assert_equal 16, @boingboing.search('//div').search('p/a/img').length
    assert imgs.all? { |x| x.name == 'img' }
  end

  def test_predicates
    @boingboing = Nokogiri.parse(TestFiles::BOINGBOING)
    assert_equal 2, @boingboing.search('//link[@rel="alternate"]').length
    p_imgs = @boingboing.search('//div/p[/a/img]')
    #assert_equal 15, p_imgs.length
    assert p_imgs.all? { |x| x.name == 'p' }
    p_imgs = @boingboing.search('//div/p[a/img]')
    assert_equal 12, p_imgs.length
    assert p_imgs.all? { |x| x.name == 'p' }
    assert_equal 1, @boingboing.search('//input[@checked]').length
  end

  def test_tag_case
    @tenderlove = Nokogiri.parse(TestFiles::TENDERLOVE)
    assert_equal 2, @tenderlove.search('//a').length
    assert_equal 3, @tenderlove.search('//area').length
    assert_equal 2, @tenderlove.search('//meta').length
  end

  def test_alt_predicates
    @boingboing = Nokogiri.parse(TestFiles::BOINGBOING)
    assert_equal 2, @boingboing.search('table/tr:last').length

    @basic = Nokogiri.parse(TestFiles::BASIC)
    assert_equal "<p>The third paragraph</p>",
        @basic.search('p:eq(3)').to_html.chomp
        @basic.search('p:last').to_html.gsub(/\s+/,' ').gsub(/>\s*</, '><')
    assert_equal 'last final', @basic.search('p:last-of-type').first.get_attribute('class')
  end

  def test_insert_after # ticket #63
    doc = Nokogiri('<html><body><div id="a-div"></div></body></html>')
    (doc/'div').each do |element|
      element.after('<p>Paragraph 1</p><p>Paragraph 2</p>')
    end
    assert_match '<div id="a-div"></div><p>Paragraph 1</p><p>Paragraph 2</p>',
      doc.to_html.gsub(/\n/, '').gsub(/>\s*</, '><')
  end

  def test_insert_before # ticket #61
    doc = Nokogiri.HTML('<html><body><div id="a-div"></div></body></html>')
    (doc/'div').each do |element|
      element.before('<p>Paragraph 1</p><p>Paragraph 2</p>')
    end
    assert_match '<p>Paragraph 1</p><p>Paragraph 2</p><div id="a-div"></div>',
      doc.to_html.gsub(/\n/, '').gsub(/>\s*</, '><')
  end

  def test_many_paths
    @boingboing = Nokogiri.parse(TestFiles::BOINGBOING)
    assert_equal 62, @boingboing.search('p.posted, link[@rel="alternate"]').length
  end

  def test_class_search
    doc = Nokogiri.HTML("<div class=xyz '>abc</div>")
    assert_equal 1, doc.search(".xyz").length

    doc = Nokogiri.HTML("<div class=xyz>abc</div><div class=abc>xyz</div>")
    assert_equal 1, doc.search(".xyz").length
    assert_equal 4, doc.search("*").length
  end

  def test_kleene_star
    # bug noticed by raja bhatia
    doc = Nokogiri.HTML("<span class='small'>1</span><div class='large'>2</div><div class='small'>3</div><span class='blue large'>4</span>")
    assert_equal 2, doc.search("*[@class*='small']").length
    assert_equal 2, doc.search("*.small").length
    assert_equal 2, doc.search(".small").length
    assert_equal 2, doc.search(".large").length
  end

  def test_empty_comment
    doc = Nokogiri.HTML("<p><!----></p>")
    doc = doc.search('//body').first
    assert doc.children[0].children[0].comment?

    doc = Nokogiri.HTML("<p><!-- --></p>")
    doc = doc.search('//body').first
    assert doc.children[0].children[0].comment?
  end

  def test_body_newlines
    @immob = Nokogiri.parse(TestFiles::IMMOB)
    body = @immob.at(:body)
    {'background' => '', 'bgcolor' => '#ffffff', 'text' => '#000000', 'marginheight' => '10',
     'marginwidth' => '10', 'leftmargin' => '10', 'topmargin' => '10', 'link' => '#000066',
     'alink' => '#ff6600', 'hlink' => "#ff6600", 'vlink' => "#000000"}.each do |k, v|
        assert_equal v, body[k]
    end
  end

  def test_nested_twins
    @doc = Nokogiri("<div>Hi<div>there</div></div>")
    assert_equal 1, (@doc/"div div").length
  end

  def test_wildcard
    @basic = Nokogiri::HTML.parse(TestFiles::BASIC)
    assert_equal 3, (@basic/"*[@id]").length
    assert_equal 3, (@basic/"//*[@id]").length
  end

  def test_javascripts
    @immob = Nokogiri::HTML.parse(TestFiles::IMMOB)
    assert_equal 3, (@immob/:script)[0].inner_html.scan(/<LINK/).length
  end

  ####
  # Modified.  This test passes with later versions of libxml
  def test_nested_scripts
    @week9 = Nokogiri.parse(TestFiles::WEEK9)
    unless Nokogiri::LIBXML_VERSION == '2.6.16'
      assert_equal 14, (@week9/"a").find_all { |x| x.inner_html.include? "GameCenter" }.length
    end
  end

  def test_uswebgen
    @uswebgen = HTML.parse(TestFiles::USWEBGEN)
    # sent by brent beardsley, nokogiri 0.3 had problems with all the links.
    assert_equal 67, (@uswebgen/:a).length
  end

  def test_mangled_tags
    [%{<html><form name='loginForm' method='post' action='/units/a/login/1,13088,779-1,00.html'?URL=></form></html>},
     %{<html><form name='loginForm' ?URL= method='post' action='/units/a/login/1,13088,779-1,00.html'></form></html>},
     %{<html><form name='loginForm'?URL= ?URL= method='post' action='/units/a/login/1,13088,779-1,00.html'?URL=></form></html>},
     %{<html><form name='loginForm' method='post' action='/units/a/login/1,13088,779-1,00.html' ?URL=></form></html>}].
    each do |str|
      doc = Nokogiri(str)
      assert_equal 1, (doc/:form).length
      assert_equal '/units/a/login/1,13088,779-1,00.html', doc.at("form")['action']
    end
  end

  ####
  # Modified.  Added question.  Don't care.
  def test_procins
    doc = Nokogiri.HTML("<?php print('hello') ?>\n<?xml blah='blah'?>")
    assert_equal "php", doc.children[1].name
    assert_equal "blah='blah'?", doc.children[2].content #"# quote added so emacs ruby-mode parser doesn't barf
  end

  ####
  # Altered...  libxml does not get a buffer error
  def test_buffer_error
    assert_nothing_raised {
      Nokogiri(%{<p>\n\n<input type="hidden" name="__VIEWSTATE"  value="#{(("X" * 2000) + "\n") * 22}" />\n\n</p>})
    }
  end

  def test_youtube_attr
    str = <<-edoc
    <html><body>
    Lorem ipsum. Jolly roger, ding-dong sing-a-long 
    <object width="425" height="350">
      <param name="movie" value="http://www.youtube.com/v/NbDQ4M_cuwA"></param>
      <param name="wmode" value="transparent"></param>
        <embed src="http://www.youtube.com/v/NbDQ4M_cuwA" 
          type="application/x-shockwave-flash" wmode="transparent" width="425" height="350">
        </embed>
    </object>
    Check out my posting, I have bright mice in large clown cars.
    <object width="425" height="350">
      <param name="movie" value="http://www.youtube.com/v/foobar"></param>
      <param name="wmode" value="transparent"></param>
        <embed src="http://www.youtube.com/v/foobar" 
          type="application/x-shockwave-flash" wmode="transparent" width="425" height="350">
        </embed>
    </object>
    </body></html?
    edoc
    doc = Nokogiri(str)
    assert_equal "http://www.youtube.com/v/NbDQ4M_cuwA",
      doc.at("//object/param[@value='http://www.youtube.com/v/NbDQ4M_cuwA']")['value']
  end

  # ticket #84 by jamezilla
  def test_screwed_xmlns
    doc = Nokogiri(<<-edoc)
      <?xml:namespace prefix = cwi />
      <html><body>HAI</body></html>
    edoc
    assert_equal "HAI", doc.at("body").inner_text
  end

  def test_filters
    @basic = Nokogiri.parse(TestFiles::BASIC)
    assert_equal 1, (@basic/"title:parent").size
    assert_equal 4, (@basic/"p:parent").size
    assert_equal 0, (@basic/"title:empty").size
    assert_equal 3, (@basic/"link:empty").size
  end

  def test_keep_cdata
    str = %{<script> /*<![CDATA[*/
    /*]]>*/ </script>}
    # MODIFIED: if you want the cdata, to_xml it
    assert_match str, Nokogiri(str).to_xml
  end

  def test_namespace
    chunk = <<-END
    <a xmlns:t="http://www.nexopia.com/dev/template">
      <t:sam>hi </t:sam>
    </a>
    END
    doc = Nokogiri::XML(chunk)
    assert((doc/"//t:sam").size > 0)
  end
end
