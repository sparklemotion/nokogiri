require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))
require File.join(File.dirname(__FILE__),"load_files")

class TestParser < Nokogiri::TestCase
  include Nokogiri
  # normally, the link tags are empty HTML tags.
  # contributed by laudney.
  def test_normally_empty
    doc = Nokogiri::XML("<rss><channel><title>this is title</title><link>http://fake.com</link></channel></rss>")
    assert_equal "this is title", (doc/:rss/:channel/:title).text
    assert_equal "http://fake.com", (doc/:rss/:channel/:link).text
  end

  # make sure XML doesn't get downcased
  def test_casing
    doc = Nokogiri::XML(TestFiles::WHY)

    ### Modified.
    # I don't want to differentiate pseudo classes from namespaces.  If
    # you're parsing xml, use XPath.  That's what its for.  :-P
    assert_equal "hourly", (doc.at "//sy:updatePeriod").content
    assert_equal 1, (doc/"guid[@isPermaLink]").length
  end

  # be sure tags named "text" are ok
  def test_text_tags
    doc = Nokogiri::XML("<feed><title>City Poisoned</title><text>Rita Lee has poisoned Brazil.</text></feed>")
    assert_equal "City Poisoned", (doc/"title").text
  end
end
