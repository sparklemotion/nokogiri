require 'helper'

class NodeTest < Nokogiri::TestCase
  def setup
    @xml = Nokogiri::XML.parse(File.read(XML_FILE))
    assert @xml.xml?
  end

  def test_equal
    employees = @xml.search('//employee')
    employee = employees[0]
    first_employee = employees.first
    assert_equal(first_employee, employee)
  end
end
