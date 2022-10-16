# frozen_string_literal: true

require "helper"

describe "compaction" do
  describe Nokogiri::XML::Node do
    it "compacts safely" do # https://github.com/sparklemotion/nokogiri/pull/2579
      skip unless GC.respond_to?(:verify_compaction_references)

      big_doc = "<root>" + ("a".."zz").map { |x| "<#{x}>#{x}</#{x}>" }.join + "</root>"
      doc = Nokogiri.XML(big_doc)

      # ensure a bunch of node objects have been wrapped
      doc.root.children.each(&:inspect)

      # compact the heap and try to get the node wrappers to move
      GC.verify_compaction_references(double_heap: true, toward: :empty)

      # access the node wrappers and make sure they didn't move
      doc.root.children.each(&:inspect)
    end
  end

  describe Nokogiri::XML::Namespace do
    it "namespace_scopes" do
      skip unless GC.respond_to?(:verify_compaction_references)

      doc = Nokogiri::XML(<<~EOF)
        <root xmlns="http://example.com/root" xmlns:bar="http://example.com/bar">
          <first/>
          <second xmlns="http://example.com/child"/>
          <third xmlns:foo="http://example.com/foo"/>
        </root>
      EOF

      doc.at_xpath("//root:first", "root" => "http://example.com/root").namespace_scopes.inspect

      GC.verify_compaction_references(double_heap: true, toward: :empty)

      doc.at_xpath("//root:first", "root" => "http://example.com/root").namespace_scopes.inspect
    end
  end
end
