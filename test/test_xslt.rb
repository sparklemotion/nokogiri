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
    assert_match(/<td>EMP0001<\/td>/, result)
  end

  def test_substitue_entities=
    xslt = Nokogiri::XSLT.parse(File.read(XSLT_FILE))
    Nokogiri::XML.substitute_entities = true
    Nokogiri::XML.load_external_subsets = true
    result = xslt.apply_to(@xml)
    assert result
    assert_match(/<td>EMP0001<\/td>/, result)
  end
end
