# frozen_string_literal: true

require "helper"

describe "compaction" do
  it "https://github.com/sparklemotion/nokogiri/pull/2579" do
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
