require File.join(File.dirname(__FILE__), '..', 'helper')

include Nokogiri::XML

describe Nokogiri::XML::Reader do
  
  it "should return the correct local_names" do
    xml = <<-oexml
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
    </x>
    oexml
    r = Nokogiri::XML::Reader.from_memory(xml)
    r.should_not be_nil
    r.local_name.should be_nil
    r.map{|x| x.local_name}.should == ["x","#text","foo","#text","foo","#text","x"]
  end

  it "should return the correct names" do
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:edi='http://ecommerce.example.org/schema'>
      <edi:foo>hello</edi:foo>
    </x>
    eoxml
    reader.should_not be_nil
    reader.name.should be_nil
    reader.map{|x| x.name}.should == ["x", "#text", "edi:foo", "#text", "edi:foo", "#text", "x"]
  end

  it "should set io as source when called from_io method" do
    io = StringIO.new(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
    </x>
    eoxml
    reader = Nokogiri::XML::Reader.from_io(io)
    reader.source.should be_equal(io)
  end

  it "should raise ArgumentError if nil is passed" do
    lambda{
      Nokogiri::XML::Reader.from_memory(nil)
    }.should raise_error(ArgumentError)
    lambda{
      Nokogiri::XML::Reader.from_io(nil)
    }.should raise_error(ArgumentError)
  end

  it "should parse from_io" do
    io = StringIO.new(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
    </x>
    eoxml
    reader = Nokogiri::XML::Reader.from_io(io)
    reader.should_not be_default
    reader.map{ |x| x.default? }.should == [false, false, false, false, false, false, false]
  end

  it "should parse when passed an io object" do
    io = StringIO.new(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
    </x>
    eoxml
    reader = Nokogiri::XML::Reader(io)
    reader.should_not be_default
    reader.map{ |x| x.default? }.should == [false, false, false, false, false, false, false]
  end

  it "should set string as source when called from_memory" do
    xml = <<-eoxml
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
    </x>
    eoxml
    reader = Nokogiri::XML::Reader(xml)
    reader.source.should be_equal(xml)
  end

  it "should return false for default" do # Sorry for the description. Couldn't avoid to.
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
    </x>
    eoxml
    reader.should_not be_default
    reader.map { |x| x.default? }.should == [false, false, false, false, false, false, false]
  end

  it "should return the correct boolean value when asked for value?" do
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
    </x>
    eoxml

    reader.value?.should == false # Look for how should I do this in RSpec.
    reader.map {|x| x.value? }.should == [false, true, false, true, false, true, false]
  end

  it "should be able to deal with errors" do
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
      <foo>
    </x>
    eoxml

    reader.errors.should have(0).items

    lambda {
      reader.each { |node| }
    }.should raise_error(Nokogiri::XML::SyntaxError)
 
    reader.errors.should have(1).item
  end

  it "should retrieve the right arguments" do
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'
       xmlns='http://mothership.connection.com/'
    >
      <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
    </x>
    eoxml
    reader.attributes.should be_empty
    reader.map { |x| x.attributes }.should == [{'xmlns:tenderlove'=>'http://tenderlovemaking.com/',
						'xmlns'=>'http://mothership.connection.com/'},
					       {}, {"awesome"=>"true"}, {}, {"awesome"=>"true"}, {},
					       {'xmlns:tenderlove'=>'http://tenderlovemaking.com/',
						'xmlns'=>'http://mothership.connection.com/'}]
  end

  it "should be able to acces the same attribute through both attribute and attributes method" do
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'
       xmlns='http://mothership.connection.com/'
      >
      <tenderlove:foo awesome='true' size='giant'>snuggles!</tenderlove:foo>
    </x>
    eoxml
    
    reader.attribute(nil).should be_nil
    
    reader.each do |node|
      node.attributes.each do |key, value|
	node.attribute(key).should == value
      end
    end
  end

  it "should be able to retrieve an attribute given an index" do
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
    </x>
    eoxml

    reader.attribute_at(nil).should be_nil
    reader.attribute_at(0).should be_nil

    reader.map {|x| x.attribute_at(0) }.should == ['http://tenderlovemaking.com/', nil, 'true', nil, 'true', nil, 'http://tenderlovemaking.com/']
  end

  it "should be able to access an attribute value by its name" do # I should get this test for free
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
    </x>
    eoxml

    reader.attribute(nil).should be_nil
    reader.attribute('awesome').should be_nil
    
    reader.map {|x| x.attribute('awesome') }.should ==[nil, nil, 'true', nil, 'true', nil, nil]
  end

  it "should retrieve the correct number of attributes" do
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
    </x>
    eoxml

    reader.attribute_count.should == 0
    reader.map {|x| x.attribute_count}.should == [1, 0, 1, 0, 0, 0, 0]
  end

  it "should return the depth of the current node" do
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo>snuggles!</tenderlove:foo>
    </x>
    eoxml

    reader.depth.should == 0

    reader.map {|x| x.depth}.should == [0,1,1,2,1,1,0]
  end

  it "should return the right encoding" do
    string = <<-eoxml
    <awesome>
      <p xml:lang="en">The quick brown fox jumps over the lazy dog.</p>
      <p xml:lang="ja">日本語が上手です</p>
    </awesome>
    eoxml
    reader = Nokogiri::XML::Reader.from_memory(string, nil, 'UTF-8')
    reader.map { |x| x.encoding }.uniq.should == ['UTF-8']
  end

  it "should return the right xml version" do
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo>snuggles!</tenderlove:foo>
    </x>
    eoxml

    reader.xml_version.should be_nil

    reader.map { |x| x.xml_version }.uniq.should == ['1.0']
  end

  it "should retrieve the correct lang" do
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <awesome>
      <p xml:lang="en">The quick brown fox jumps over the lazy dog.</p>
      <p xml:lang="ja">日本語が上手です</p>
    </awesome>
    eoxml

    reader.lang.should be_nil
   
    reader.map {|x| x.lang}.should == [nil, nil, "en", "en", "en", nil, "ja", "ja", "ja", nil, nil]
  end

  it "should retrieve the correct value" do
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo>snuggles!</tenderlove:foo>
    </x>
    eoxml

    reader.value.should be_nil

    reader.map {|x| x.value }.should == [nil, "\n      ", nil, "snuggles!", nil, "\n    ", nil]
  end

  it "should return the node's prefix" do
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:edi='http://ecommerce.example.org/schema'>
      <edi:foo>hello</edi:foo>
    </x>
    eoxml

    reader.prefix.should be_nil

    reader.map { |n| n.prefix }.should == [nil, nil, "edi", nil, "edi", nil, nil]
  end

  it "should return the reader state, whatever it is" do
    reader = Nokogiri::XML::Reader.from_memory('<foo>bar</bar>')
    reader.state.should_not be_nil
  end

  it "should return the namespace's uri" do
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:edi='http://ecommerce.example.org/schema'>
      <edi:foo>hello</edi:foo>
    </x>
    eoxml
    reader.namespace_uri.should be_nil

    reader.map { |n| n.namespace_uri }.should == [nil,
                                                  nil,
                                                  "http://ecommerce.example.org/schema",
                                                  nil,
                                                  "http://ecommerce.example.org/schema",
                                                  nil,
                                                  nil]
  end

  it "should return the node's local_name" do
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:edi='http://ecommerce.example.org/schema'>
      <edi:foo>hello</edi:foo>
    </x>
    eoxml

    reader.local_name.should be_nil

    reader.map {|n| n.local_name }.should == ["x", "#text", "foo", "#text", "foo", "#text", "x"]
  end

  it "should return node's name" do
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:edi='http://ecommerce.example.org/schema'>
      <edi:foo>hello</edi:foo>
    </x>
    eoxml

    reader.name.should be_nil

    reader.map { |n| n.name }.should ==["x", "#text", "edi:foo", "#text", "edi:foo", "#text", "x"]
  end
end