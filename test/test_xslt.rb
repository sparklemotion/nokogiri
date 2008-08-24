require 'helper'

class TestXSLT < Nokogiri::TestCase
  def setup
    @xml = Nokogiri::XML.parse(File.read(XML_FILE))
    assert @xml.xml?
  end

  def test_parse
    xslt = nil
    assert_nothing_raised {
      xslt = Nokogiri::XSLT.parse(File.read(XSLT_FILE))
    }
    assert_not_nil(xslt)
  end

  def test_apply
    xslt = Nokogiri::XSLT.parse(File.read(XSLT_FILE))
    result = xslt.apply_to(@xml)
    assert result
  end
end
