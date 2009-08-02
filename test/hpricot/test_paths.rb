require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))
require File.join(File.dirname(__FILE__),"load_files")

class TestParser < Nokogiri::TestCase
  include Nokogiri

  def test_roundtrip
    @basic = Nokogiri.parse(TestFiles::BASIC)
    %w[link link[2] body #link1 a p.ohmy].each do |css_sel|
      ele = @basic.at(css_sel)
      assert_equal ele, @basic.at(ele.css_path), ele.css_path
      assert_equal ele, @basic.at(ele.path), ele.xpath
    end
  end
end
