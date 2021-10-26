# frozen_string_literal: true

require "helper"

module Nokogiri
  module HTML
    class TestNamedCharacters < Nokogiri::TestCase
      def test_named_character
        copy = NamedCharacters.get("copy")
        assert_equal(169, NamedCharacters["copy"])
        assert_equal(copy.value, NamedCharacters["copy"])
        assert(copy.description)
      end

      def test_named_character2
        # this test, identical to the previous one, is only here to trigger failure during
        # NOKOGIRI_TEST_GC_LEVEL=verify if we regress on registering the address of
        # cNokogiriHtmlEntityDescription in html_entity_lookup.c.
        #
        # if we ever write a second meaningful test for anything that calls EntityLookup#get then we
        # can remove this test.
        copy = NamedCharacters.get("copy")
        assert_equal(169, NamedCharacters["copy"])
        assert_equal(copy.value, NamedCharacters["copy"])
        assert(copy.description)
      end
    end
  end
end
