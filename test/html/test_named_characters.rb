require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

module Nokogiri
  module HTML
    class TestNamedCharacters < Nokogiri::TestCase
      def test_named_character
        copy = NamedCharacters.get('copy')
        assert_equal 169, NamedCharacters['copy']
        assert_equal copy.value, NamedCharacters['copy']
        assert copy.description
      end
    end
  end
end
