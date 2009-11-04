require "helper"

class TestEncodingHandler < Nokogiri::TestCase
  def test_get
    assert_not_nil Nokogiri::EncodingHandler['UTF-8']
    assert_nil Nokogiri::EncodingHandler['alsdkjfhaldskjfh']
  end
end
