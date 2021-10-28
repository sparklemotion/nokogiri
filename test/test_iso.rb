# frozen_string_literal: true

require "helper"

class TestISO < Nokogiri::TestCase
  def test_iso_content_not_lacking_accents
    data = File.binread("test/files/iso-8859-1.xml")
    document = Nokogiri::XML(data)
    assert_equal("Accepté", document.at("DATA").text)
  end

  def test_iso_content_not_truncated
    data = File.binread("test/files/iso-8859-1.xml")
    document = Nokogiri::XML(data)
    assert_equal(2, document.search("DATA").count)
  end
end
