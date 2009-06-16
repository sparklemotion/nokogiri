# -*- coding: utf-8 -*-
require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TestReader < Nokogiri::TestCase
  def test_from_io_sets_io_as_source
    io = File.open SNUGGLES_FILE
    reader = Nokogiri::XML::Reader.from_io(io)
    assert_equal io, reader.source
  end

  def test_reader_takes_block
    options = nil
    Nokogiri::XML::Reader(File.read(XML_FILE), XML_FILE) do |cfg|
      options = cfg
      options.nonet.nowarning.dtdattr
    end
    assert options.nonet?
    assert options.nowarning?
    assert options.dtdattr?
  end

  def test_nil_raises
    assert_raises(ArgumentError) {
      Nokogiri::XML::Reader.from_memory(nil)
    }
    assert_raises(ArgumentError) {
      Nokogiri::XML::Reader.from_io(nil)
    }
  end

  def test_from_io
    io = File.open SNUGGLES_FILE
    reader = Nokogiri::XML::Reader.from_io(io)
    assert_equal false, reader.default?
    assert_equal [false, false, false, false, false, false, false],
      reader.map { |x| x.default? }
  end

  def test_io
    io = File.open SNUGGLES_FILE
    reader = Nokogiri::XML::Reader(io)
    assert_equal false, reader.default?
    assert_equal [false, false, false, false, false, false, false],
      reader.map { |x| x.default? }
  end

  def test_string_io
    io = StringIO.new(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
    </x>
    eoxml
    reader = Nokogiri::XML::Reader(io)
    assert_equal false, reader.default?
    assert_equal [false, false, false, false, false, false, false],
      reader.map { |x| x.default? }
  end

  def test_in_memory
    reader = Nokogiri::XML::Reader(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
    </x>
    eoxml
  end

  def test_reader_holds_on_to_string
    xml = <<-eoxml
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
    </x>
    eoxml
    reader = Nokogiri::XML::Reader(xml)
    if Nokogiri.ffi?
      assert_not_nil reader.source
      assert reader.source.is_a?(FFI::MemoryPointer)
    else
      assert_equal xml, reader.source
    end
  end

  def test_default?
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
    </x>
    eoxml
    assert_equal false, reader.default?
    assert_equal [false, false, false, false, false, false, false],
      reader.map { |x| x.default? }
  end

  def test_value?
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
    </x>
    eoxml
    assert_equal false, reader.value?
    assert_equal [false, true, false, true, false, true, false],
      reader.map { |x| x.value? }
  end

  def test_read_error_document
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
      <foo>
    </x>
    eoxml
    error_happened = false
    begin
      reader.each { |node| }
    rescue Nokogiri::XML::SyntaxError => ex
      error_happened = true
    end
    assert error_happened
    assert 1, reader.errors.length
  end

  def test_attributes?
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
    </x>
    eoxml
    assert_equal false, reader.attributes?
    assert_equal [true, false, true, false, true, false, true],
      reader.map { |x| x.attributes? }
  end

  def test_attributes
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'
       xmlns='http://mothership.connection.com/'
       >
      <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
    </x>
    eoxml
    assert_equal({}, reader.attributes)
    assert_equal [{'xmlns:tenderlove'=>'http://tenderlovemaking.com/',
                   'xmlns'=>'http://mothership.connection.com/'},
                  {}, {"awesome"=>"true"}, {}, {"awesome"=>"true"}, {},
                  {'xmlns:tenderlove'=>'http://tenderlovemaking.com/',
                   'xmlns'=>'http://mothership.connection.com/'}],
      reader.map { |x| x.attributes }
  end

  def test_attribute_roundtrip
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'
       xmlns='http://mothership.connection.com/'
       >
      <tenderlove:foo awesome='true' size='giant'>snuggles!</tenderlove:foo>
    </x>
    eoxml
    reader.each do |node|
      node.attributes.each do |key, value|
        assert_equal value, node.attribute(key)
      end
    end
  end

  def test_attribute_at
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
    </x>
    eoxml
    assert_nil reader.attribute_at(nil)
    assert_nil reader.attribute_at(0)
    assert_equal ['http://tenderlovemaking.com/', nil, 'true', nil, 'true', nil, 'http://tenderlovemaking.com/'],
      reader.map { |x| x.attribute_at(0) }
  end

  def test_attribute
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
    </x>
    eoxml
    assert_nil reader.attribute(nil)
    assert_nil reader.attribute('awesome')
    assert_equal [nil, nil, 'true', nil, 'true', nil, nil],
      reader.map { |x| x.attribute('awesome') }
  end

  def test_attribute_length
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
    </x>
    eoxml
    assert_equal 0, reader.attribute_count
    assert_equal [1, 0, 1, 0, 0, 0, 0], reader.map { |x| x.attribute_count }
  end

  def test_depth
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo>snuggles!</tenderlove:foo>
    </x>
    eoxml
    assert_equal 0, reader.depth
    assert_equal [0, 1, 1, 2, 1, 1, 0], reader.map { |x| x.depth }
  end

  def test_encoding
    string = <<-eoxml
    <awesome>
      <p xml:lang="en">The quick brown fox jumps over the lazy dog.</p>
      <p xml:lang="ja">日本語が上手です</p>
    </awesome>
    eoxml
    reader = Nokogiri::XML::Reader.from_memory(string, nil, 'UTF-8')
    assert_equal ['UTF-8'], reader.map { |x| x.encoding }.uniq
  end

  def test_xml_version
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo>snuggles!</tenderlove:foo>
    </x>
    eoxml
    assert_nil reader.xml_version
    assert_equal ['1.0'], reader.map { |x| x.xml_version }.uniq
  end

  def test_lang
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <awesome>
      <p xml:lang="en">The quick brown fox jumps over the lazy dog.</p>
      <p xml:lang="ja">日本語が上手です</p>
    </awesome>
    eoxml
    assert_nil reader.lang
    assert_equal [nil, nil, "en", "en", "en", nil, "ja", "ja", "ja", nil, nil],
      reader.map { |x| x.lang }
  end

  def test_value
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:tenderlove='http://tenderlovemaking.com/'>
      <tenderlove:foo>snuggles!</tenderlove:foo>
    </x>
    eoxml
    assert_nil reader.value
    assert_equal [nil, "\n      ", nil, "snuggles!", nil, "\n    ", nil],
      reader.map { |x| x.value }
  end

  def test_prefix
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:edi='http://ecommerce.example.org/schema'>
      <edi:foo>hello</edi:foo>
    </x>
    eoxml
    assert_nil reader.prefix
    assert_equal [nil, nil, "edi", nil, "edi", nil, nil],
      reader.map { |n| n.prefix }
  end

  def test_state
    reader = Nokogiri::XML::Reader.from_memory('<foo>bar</bar>')
    assert reader.state
  end

  def test_ns_uri
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:edi='http://ecommerce.example.org/schema'>
      <edi:foo>hello</edi:foo>
    </x>
    eoxml
    assert_nil reader.namespace_uri
    assert_equal([nil,
                  nil,
                  "http://ecommerce.example.org/schema",
                  nil,
                  "http://ecommerce.example.org/schema",
                  nil,
                  nil],
                  reader.map { |n| n.namespace_uri })
  end

  def test_local_name
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:edi='http://ecommerce.example.org/schema'>
      <edi:foo>hello</edi:foo>
    </x>
    eoxml
    assert_nil reader.local_name
    assert_equal(["x", "#text", "foo", "#text", "foo", "#text", "x"],
                 reader.map { |n| n.local_name })
  end

  def test_name
    reader = Nokogiri::XML::Reader.from_memory(<<-eoxml)
    <x xmlns:edi='http://ecommerce.example.org/schema'>
      <edi:foo>hello</edi:foo>
    </x>
    eoxml
    assert_nil reader.name
    assert_equal(["x", "#text", "edi:foo", "#text", "edi:foo", "#text", "x"],
                 reader.map { |n| n.name })
  end

  def test_read_from_memory
    called = false
    reader = Nokogiri::XML::Reader.from_memory('<foo>bar</foo>')
    reader.each do |node|
      called = true
      assert node
    end
    assert called
  end
end
