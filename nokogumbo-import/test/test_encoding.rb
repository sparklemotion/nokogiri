# encoding: utf-8
require 'nokogumbo'
require 'minitest/autorun'

class TestNokogumbo < Minitest::Test
  if ''.respond_to? 'encoding'
    def test_macroman_encoding
      mac="<span>\xCA</span>".force_encoding('macroman')
      doc = Nokogiri::HTML5(mac)
      assert_equal "<span> </span>", doc.at("span").to_xml
    end

    def test_iso8859_encoding
      iso8859="<span>Se\xF1or</span>".force_encoding(Encoding::ASCII_8BIT)
      doc = Nokogiri::HTML5(iso8859)
      assert_equal '<span>Señor</span>', doc.at('span').to_xml
    end

    def test_charset_encoding
      utf8="<meta charset='utf-8'><span>Se\xC3\xB1or</span>".
        force_encoding(Encoding::ASCII_8BIT)
      doc = Nokogiri::HTML5(utf8)
      assert_equal '<span>Señor</span>', doc.at('span').to_xml
    end

    def test_bogus_encoding
      bogus="<meta charset='bogus'><span>Se\xF1or</span>".
        force_encoding(Encoding::ASCII_8BIT)
      doc = Nokogiri::HTML5(bogus)
      assert_equal '<span>Señor</span>', doc.at('span').to_xml
    end
  end
end
