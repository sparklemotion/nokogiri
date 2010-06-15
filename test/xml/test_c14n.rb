require "helper"

module Nokogiri
  module XML
    class TestC14N < Nokogiri::TestCase
      # http://www.w3.org/TR/xml-c14n#Example-OutsideDoc
      def test_3_1
        doc = Nokogiri.XML <<-eoxml
<?xml version="1.0"?>

<?xml-stylesheet   href="doc.xsl"
   type="text/xsl"   ?>

<!DOCTYPE doc SYSTEM "doc.dtd">

<doc>Hello, world!<!-- Comment 1 --></doc>

<?pi-without-data     ?>

<!-- Comment 2 -->

<!-- Comment 3 -->
        eoxml

        c14n = doc.canonicalize
        assert_no_match(/version=/, c14n)
        assert_match(/Hello, world/, c14n)
      end

      def test_exclude_block_params
        xml = '<a><b></b></a>'
        doc = Nokogiri.XML xml

        list = []
        c14n = doc.canonicalize do |node, parent|
          list << [node, parent]
          true
        end
        assert_equal(
          ['a', 'document', 'document', nil, 'b', 'a', 'a', 'document'],
          list.flatten.map { |x| x ? x.name : x }
        )
      end

      def test_exclude_block_true
        xml = '<a><b></b></a>'
        doc = Nokogiri.XML xml

        c14n = doc.canonicalize do |node, parent|
          true
        end
        assert_equal xml, c14n
      end

      def test_exclude_block_false
        xml = '<a><b></b></a>'
        doc = Nokogiri.XML xml

        c14n = doc.canonicalize do |node, parent|
          false
        end
        assert_equal '', c14n
      end

      def test_exclude_block_nil
        xml = '<a><b></b></a>'
        doc = Nokogiri.XML xml

        c14n = doc.canonicalize do |node, parent|
          nil
        end
        assert_equal '', c14n
      end

      def test_exclude_block_object
        xml = '<a><b></b></a>'
        doc = Nokogiri.XML xml

        c14n = doc.canonicalize do |node, parent|
          Object.new
        end
        assert_equal xml, c14n
      end
    end
  end
end
