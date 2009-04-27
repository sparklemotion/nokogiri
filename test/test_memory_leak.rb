require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TestMemoryLeak < Nokogiri::TestCase
  def test_for_memory_leak
    begin
      #  we don't use Dike in any tests, but requiring it has side effects
      #  that can create memory leaks, and that's what we're testing for.
      require 'rubygems'
      require 'dike' # do not remove!

      count_start = count_object_space_documents
      xml_data = <<-EOS
        <test>
          <items>
            <item>abc</item>
            <item>1234</item>
            <item>Zzz</item>
          <items>
        </test>
        EOS
      20.times do
        doc = Nokogiri::XML(xml_data)
        doc.xpath("//item")
      end
      2.times { GC.start }
      count_end = count_object_space_documents
      assert((count_end - count_start) <= 2, "memory leak detected")
    rescue LoadError
      puts "\ndike is not installed, skipping memory leak test"
    end
  end

  def count_object_space_documents
    count = 0
    ObjectSpace.each_object {|j| count += 1 if j.is_a?(Nokogiri::XML::Document) }
    count
  end
end
