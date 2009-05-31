require 'rspec'
require 'nokogiri'

describe Reader do
  
  it "should match the following nodes given that xml" do
    xml = <<-oexml
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
    </x>
    oexml
    reader = Nokogiri::XML::Reader(xml)
    ["x", "#text", "foo", "#text", "foo", "#text", "x"].each do |local_name|
      reader.read.local_name.should == local_name
    end
  end
end
