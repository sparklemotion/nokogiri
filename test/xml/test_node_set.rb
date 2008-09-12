require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module XML
    class TestNodeSet < Nokogiri::TestCase
      def setup
        @xml = Nokogiri::XML.parse(File.read(XML_FILE), XML_FILE)
      end

      def test_node_set_fetches_private_data
        assert path_ctx = @xml.search('//employee')
        assert path_ctx.node_set

        set = path_ctx.node_set
        assert_equal(set[0], set[0])
      end
    end
  end
end
