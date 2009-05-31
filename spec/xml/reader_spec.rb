require 'rubygems'
require 'nokogiri'

include Nokogiri::XML

describe Nokogiri::XML::Reader do
  
  it "should return the correct local_names" do
    xml = <<-oexml
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
    </x>
    oexml
    r = Reader.from_memory(xml)
    r.map{|x| x.local_name}.should == ["x","#text","foo","#text","foo","#text","x"]
  end
end
