require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestEntityReference < Nokogiri::TestCase
      def setup
        @xml = Nokogiri::XML(File.open(XML_FILE), XML_FILE)
      end

      def test_new
        assert ref = EntityReference.new(@xml, 'ent4')
        assert_instance_of EntityReference, ref
      end
    end
  end
end
