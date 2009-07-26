require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

class TestBuilder < Nokogiri::TestCase
  ####
  # Modified
  def test_escaping_text
    doc = Nokogiri() { b "<a\"b>" }
    assert_match "<b>&lt;a\"b&gt;</b>", doc.to_html.chomp
    assert_equal %{&lt;a\"b&gt;}, doc.at("text()").to_s
  end

  ####
  # Modified
  def test_no_escaping_text
    doc = Nokogiri() { div.test.me! { text "<a\"b>" } }
    assert_match %{<div class="test" id="me">&lt;a"b&gt;</div>},
      doc.to_html.chomp
    assert_equal %{&lt;a\"b&gt;}, doc.at("text()").to_s
  end
end
