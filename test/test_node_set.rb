require 'helper'

class NodeSetTest < Nokogiri::TestCase
  def setup
    @xml = Nokogiri::XML.parse(File.read(XML_FILE))
    assert @xml.xml?
  end

  def test_each
    employees = @xml.search('//employee')
    assert_equal(5, employees.length)
    employees.each do |employee|
      assert_equal('employee', employee.name)
    end
  end

  def test_search
    employees = @xml.search('//employee')
    assert_equal(5, employees.length)
    position = employees.search('//position')
    assert_equal(employees.length, position.length)

    position.each do |pos|
      assert_equal('position', pos.name)
    end
  end
end
