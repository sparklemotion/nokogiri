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

    def test_utf8_bom
      utf8 = "\uFEFF<!DOCTYPE html><html></html>".encode('UTF-8')
      doc = Nokogiri::HTML5(utf8, max_errors: 10)
      assert_equal [], doc.errors
    end

    def test_utf16le_bom
      utf16le = "\uFEFF<!DOCTYPE html><html></html>".encode('UTF-16LE')
      doc = Nokogiri::HTML5(utf16le, max_errors: 10)
      assert_equal [], doc.errors
    end

    def test_utf16be_bom
      utf16be = "\uFEFF<!DOCTYPE html><html></html>".encode('UTF-16BE')
      doc = Nokogiri::HTML5(utf16be, max_errors: 10)
      assert_equal [], doc.errors
    end

    def test_utf8_bom_ascii
      utf8 = "\uFEFF<!DOCTYPE html><html></html>".encode('UTF-8')
      utf8.force_encoding(Encoding::ASCII_8BIT)
      doc = Nokogiri::HTML5(utf8, max_errors: 10)
      doc.errors.each { |err| puts(err) }
      assert_equal [], doc.errors
    end

    def test_utf16le_bom_ascii
      utf16le = "\uFEFF<!DOCTYPE html><html></html>".encode('UTF-16LE')
      utf16le.force_encoding(Encoding::ASCII_8BIT)
      doc = Nokogiri::HTML5(utf16le, max_errors: 10)
      assert_equal [], doc.errors
      doc.errors.each { |err| puts(err) }
    end

    def test_utf16be_bom_ascii
      utf16be = "\uFEFF<!DOCTYPE html><html></html>".encode('UTF-16BE')
      utf16be.force_encoding(Encoding::ASCII_8BIT)
      doc = Nokogiri::HTML5(utf16be, max_errors: 10)
      assert_equal [], doc.errors
      doc.errors.each { |err| puts(err) }
    end

    def test_tag_after_utf8_bom
      utf8 = "\uFEFF<b></b>".encode('UTF-8')
      doc = Nokogiri::HTML5.fragment(utf8, max_errors: 10)
      assert_equal [], doc.errors
    end
  end

  # https://github.com/rubys/nokogumbo/issues/68
  def test_charset_sniff_to_html
    html = <<-EOF.gsub(/^      /, '')
      <!DOCTYPE html>
      <html>
        <head>
          <meta http-equiv="Content-Type" content="text/html; charset=utf-8; width=device-width">
        </head>
        <body>
          Hello!
        </body>
      </html>
    EOF
    doc = Nokogiri::HTML5(html, max_errors: 10)
    assert_equal 0, doc.errors.length
    refute_equal '', doc.to_html
  end

  # https://encoding.spec.whatwg.org/#names-and-labels
  # I chose these by looking at the Wikipedia page for each encoding, picked
  # one of the languages it was supposed to encode, and then Googled for a
  # proverb in the language. Apologies if these are ill-chosen or nonsensical.
  # I'm happy to change them. I'm just pasting them in here so I'm pretty sure
  # the right-to-left languages are backward. Corrections welcome.
  ENCODINGS = [
    ['UTF-8',          "Let's concatentate all of these for UTF-8"], # English
    ['IBM866',         'А дело бывало -- и коза волка съедала'], # Russian
    ['ISO-8859-2',     'Co můžeš udělat dnes, neodkládej na zítřek.'], # Czech
    ['ISO-8859-3',     'Yukarda mavi gök, asağıda yağız yer yaratıldıkta'], # Turkish
    ['ISO-8859-4',     'Ceļš uz elli ir bruģēts ar labiem nodomiem.'], # Latvian
    ['ISO-8859-5',     'Каде има сила, нема правдина.'], # Macedonian
    ['ISO-8859-6',     'أباد الله خضراءهم ابذل لصديقك دمك ومالك'], # Arabic
    ['ISO-8859-7',     'Η καλύτερη άμυνα είναι η επίθεση.'], # Greek
    ['ISO-8859-8',     'אין הנחתום מעיד על עיסתו'], # Hebrew
    ['ISO-8859-8-I',   'אל תסתכל בקנקן, אלא במה שבתוכו'], # Hebrew
    ['ISO-8859-10',    'Alla känner apan, men apan känner ingen.'], # Swedish
    ['ISO-8859-13',    'Lašas po lašo ir akmenį pratašo.'], # Lithuanian
    ['ISO-8859-14',    "ha bhòrd bòrd gun aran ach 's bòrd aran leis fhèin."], # Scottish Gaelic
    ['ISO-8859-15',    'This is essentially ISO 8859-1 but with € Š š Ž ž Œ œ Ÿ'], # English
    ['ISO-8859-16',    'Kiedy wszedłeś między wrony, musisz krakać jak i one.'], # Polish
    ['KOI8-R',         'А дело бывало -- и коза волка съедала'], # Russian
    ['KOI8-U',         'Яблуко від яблуньки не далеко. Ґ, Є, І, Ї'], # Ukrainian
    ['macroman',       'Some good old Mac Roman œ∑´®†¥¨ˆøπåßƒ©'], # English
    ['windows-874',    'กระต่ายหมายจันทร์'], # Thai
    ['windows-1250',   'Addig nyújtózkodj, amíg a takaród ér.'], # Hungarian
    ['windows-1251',   'Бързата работа - срам за майстора.'], # Bulgarian
    ['windows-1252',   'Basically ISO 8859-1 with ‘differences’™ •'], # English
    ['windows-1253',   'Και οι τοίχοι έχουν αυτιά.'], # Greek
    ['windows-1254',   'Baban nasılsa oğlu da öyledir.'], # Turkish
    ['windows-1255',   'אל תקנה חתול בשק; ₪'], # Hebrew
    ['windows-1256',   'أبطأ من سلحفاة'], # Arabic
    ['windows-1257',   'Hommikune töö kuld, õhtune muld.'], # Estonian
    ['windows-1258',   'Ăn theo thuở, ở theo thời.'], # Vietnamese
    ['macCyrillic', 'А дело бывало -- и коза волка съедала'], # Russian
    ['GBK',            '不闻不若闻之，闻之不若见之，见之不若知之，知之不若行之；学至于行之而止矣'], # Simplified Chinese
    ['gb18030',        '不聞不若聞之，聞之不若見之，見之不若知之，知之不若行之；學至於行之而止矣'], # Traditional Chinese
    ['Big5',           '有其父必有其子'], # Traditional Chinese
    ['EUC-JP',         '猿も木から落ちる'], # Japanese
    ['ISO-2022-JP',    '井の中の蛙大海を知らず'], # Japanese
    ['Shift_JIS',      '鳥なき里の蝙蝠'], # Japanese
    ['EUC-KR',         '아는 길도 물어가라'], # Korean
    ['replacement',    '콩 심은데 콩나고, 팥 심은데 팥난다'], # Korean
    ['UTF-16BE',       'Everything had better be representable!'], # English
    ['UTF-16LE',       'Same as with UTF-16BE'], # English
    ['US-ASCII',       'Surprisingly not one of the required encodings'] # English
  ].freeze

  def encodings_html
    @encodings_html ||=
      "<!DOCTYPE html><html><head></head><body>" +
      ENCODINGS.map { |enc| %(<span id="#{enc[0]}">#{enc[1]}</span>) }.join +
      '</body></html>'
  end

  def encodings_doc
    @encodings_doc ||= Nokogiri::HTML5(encodings_html)
  end

  def round_trip_through(str, enc)
    begin
      encoding = Encoding.find(enc)
    rescue ArgumentError
      skip "#{enc} not supported"
    end
    begin
      encoded = str.encode(encoding)
    rescue Encoding::ConverterNotFoundError
      skip "Converting UTF-8 to #{enc} not supported"
    end
    begin
      decoded = encoded.encode('UTF-8')
    rescue Encoding::ConverterNotFoundError
      skip "Converting #{enc} to UTF-8 not supported"
    end
    assert_equal str, decoded, "'#{str}' did not round trip through #{enc[0]}"
    encoded
  end

  ENCODINGS.each do |enc|
    define_method("test_parse_encoded_#{enc[0]}".to_sym) do
      html = "<!DOCTYPE html><span>#{enc[1]}</span>"
      encoded_html = round_trip_through(html, enc[0])
      doc = Nokogiri::HTML5(encoded_html, encoding: enc[0])
      span = doc.at('/html/body/span')
      refute_nil span
      assert_equal enc[1], span.content
    end

    define_method("test_inner_html_encoded_#{enc[0]}".to_sym) do
      encoded = round_trip_through(enc[1], enc[0])
      span = encodings_doc.at(%(/html/body/span[@id="#{enc[0]}"]))
      refute_nil span
      assert_equal encoded, span.inner_html(encoding: enc[0])
    end

    define_method("test_roundtrip_through_#{enc[0]}".to_sym) do
      # https://bugs.ruby-lang.org/issues/15033
      # Ruby has a bug with the `:fallback` parameter passed to `#encode` when
      # multiple conversions have to happen. I'm not sure it's worth working
      # around. It impacts this test though.
      skip 'https://bugs.ruby-lang.org/issues/15033' if enc[0] == 'ISO-2022-JP'
      round_trip_through(enc[1], enc[0])
      encoded = encodings_doc.serialize(encoding: enc[0])
      doc = Nokogiri::HTML5(encoded, encoding: enc[0])
      assert_equal encodings_html, doc.serialize
    end
  end
end
