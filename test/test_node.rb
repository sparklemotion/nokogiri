require 'helper'

class NodeTest < Nokogiri::TestCase
  def setup
    @xml = Nokogiri::XML.parse(File.read(XML_FILE))
    assert @xml.xml?
  end

  def test_find_non_existant
    assert_nil @xml.search('/akjdhflkajsdhf').first
  end

  def test_has_attribute?
    address = @xml.search('//address').first
    assert address
    assert address.has_attribute?('domestic')
    assert !address.has_attribute?('asdfasdf')
  end

  def test_path
    employee = @xml.search('//employee').first
    assert employee.path
    assert_equal('/staff/employee[1]', employee.path)
  end

  def test_equal
    employees = @xml.search('//employee')
    employee = employees[0]
    first_employee = employees.first
    assert_equal(first_employee, employee)
  end

  def test_search
    employee = @xml.search('//employee').first
    salaries = employee.search('//salary')
    assert_equal(1, salaries.length)
  end
end
