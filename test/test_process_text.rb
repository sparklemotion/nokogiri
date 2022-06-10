# frozen_string_literal: true

require "helper"

module Nokogiri
  module XML
    class TestProcessText < Nokogiri::TestCase

      def doc
        Nokogiri::HTML(<<EOT)
    <div class="b-comment-reply__main">
        <div class="b-comment-reply__row">
            <div class="b-comment-reply__body">
                <bbb>1<bbb>2</bbb>3</bbb>
                <bbb>4</bbb>
            </div>
        </div>
    </div>
EOT
      end

      def test_process_text_for_0_node
        node_for_xpath = doc.xpath("//div[@class='b-comment-reply__body']/fff")
        node_for_at = doc.at("//div[@class='b-comment-reply__body']/fff")

        assert_equal(nil, node_for_xpath.process_text)
        assert_equal(nil, node_for_at&.process_text)
      end

      def test_process_text_for_1_node
        node_for_xpath = doc.xpath("//div[@class='b-comment-reply__body']")
        node_for_at = doc.at("//div[@class='b-comment-reply__body']")

        assert_equal("1 2 3 4", node_for_xpath.process_text)
        assert_equal("1 2 3 4", node_for_at&.process_text)
      end

      def test_process_text_for_2_node
        node_for_xpath = doc.xpath("//div[@class='b-comment-reply__body']/bbb")
        node_for_at = doc.at("//div[@class='b-comment-reply__body']/bbb")

        assert_equal("1 2 3 4", node_for_xpath.process_text)
        assert_equal("1 2 3", node_for_at&.process_text)
      end

      def test_process_text_and_text
        node_for_xpath = doc.xpath("//div[@class='b-comment-reply__body']/bbb")

        assert_equal("1 2 3 4", node_for_xpath.process_text)
        assert_equal("1234", node_for_xpath.text)
      end

      def test_process_text_for_raise
        node_for_xpath = doc.xpath("//div[@class='b-comment-reply__body']/fff")

        assert_raises do
          node_for_xpath.process_text!
        end
      end
    end
  end
end
