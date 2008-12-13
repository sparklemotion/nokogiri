require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TestXsltTransforms < Nokogiri::TestCase
  def test_transform
    assert doc = Nokogiri::XML.parse(File.read(XML_FILE))
    assert doc.xml?

    assert style = Nokogiri::XSLT.parse(File.read(XSLT_FILE))

    assert result = style.apply_to(doc, ['title', '"Booyah"'])
    assert_match %r{<h1>Booyah</h1>}, result
    assert_match %r{<th.*Employee ID</th>}, result
    assert_match %r{<th.*Name</th>}, result
    assert_match %r{<th.*Position</th>}, result
    assert_match %r{<th.*Salary</th>}, result
    assert_match %r{<td>EMP0003</td>}, result
    assert_match %r{<td>Margaret Martin</td>}, result
    assert_match %r{<td>Computer Specialist</td>}, result
    assert_match %r{<td>100,000</td>}, result
    assert_no_match %r{Dallas|Texas}, result
    assert_no_match %r{Female}, result

    assert result = style.apply_to(doc, ['title', '"Grandma"'])
    assert_match %r{<h1>Grandma</h1>}, result

    assert result = style.apply_to(doc)
    assert_match %r{<h1></h1>}, result
  end
  
  def test_exslt
    assert doc = Nokogiri::XML.parse(File.read(EXML_FILE))
    assert doc.xml?
    
    assert style = Nokogiri::XSLT.parse(File.read(EXSLT_FILE))
    result_doc = Nokogiri::XML.parse(style.apply_to(doc))
    
    assert_equal 'func-result', result_doc.at('/root/function').content
    assert_equal 3, result_doc.at('/root/max').content.to_i
    assert_match(
      /\d{4}-\d\d-\d\d-\d\d:\d\d/, 
      result_doc.at('/root/date').content
      )
  end
end
