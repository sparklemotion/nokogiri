require 'helper'

class DocumentTest < Nokogiri::TestCase
  def setup
    @xml = Nokogiri::XML.parse(File.read(XML_FILE))
    @html = Nokogiri::HTML.parse(File.read(HTML_FILE))
    assert @xml.xml?
    assert @html.html?
  end

  #def test_search
  #  @xml.search('//employee')
  #end
end
