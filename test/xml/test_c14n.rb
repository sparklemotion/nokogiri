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
    end
  end
end
