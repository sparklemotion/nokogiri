# encoding: utf-8
require 'nokogumbo'
require 'minitest/autorun'

class TestNull < Minitest::Test
  def fragment(s)
    Nokogiri::HTML5.fragment(s, max_errors: 10)
  end

  def test_null_char_ref
    frag = fragment('&#0;')
    assert_equal 1, frag.errors.length
  end

  def test_data_state
    frag = fragment("\u0000")
    # 12.2.5.1 Data state: unexpected-null-character parse error
    # 12.2.6.4.7 The "in body" insertion mode: Parse error
    assert_equal 2, frag.errors.length
  end

  def test_data_rcdata_state
    # 12.2.6.4.7 The "in body" insertion mode: textarea swiches to RCDATA
    # state
    frag = fragment("<textarea>\u0000</textarea>")
    # 12.2.5.2 RCDATA state: unexpected-null-character parse error
    assert_equal 1, frag.errors.length
  end

  def test_data_scriptdata_state
    # 12.2.6.4.7 The "in body" insertion mode: Process "script" using rules
    # for "in head" insertion mode
    # 12.2.6.4.4 The "in head" insertion mode: "script" switches to script
    # data state
    frag = fragment("<script>\u0000</script>")
    # 12.2.5.4 Script data state: unexpected-null-character parse error
    assert_equal 1, frag.errors.length
  end

  def test_data_plaintext_state
    frag = fragment("<plaintext>\u0000</plaintext>")
    # 12.2.5.5 PLAINTEXT state: unexpected-null-character parse error
    # EOF parse error because there's no way to switch out of plaintext!
    assert_equal 2, frag.errors.length
  end

  def test_data_tag_name_state
    frag = fragment("<x\u0000></x\ufffd>")
    # 12.2.5.8 Tag name state: unexpected-null-character parse error
    assert_equal 1, frag.errors.length
  end

  # XXX: There are 6 script states to test.

  def test_attribute_name_state
    frag = fragment("<p \u0000>")
    # 12.2.5.33 Attribute name state
    assert_equal 1, frag.errors.length
  end

  def test_attribute_value_states
    frag = fragment("<p x=\"\u0000\"><p x='\u0000'><p x=\u0000>")
    # 12.2.5.36 Attribute value (double-quoted) state
    # 12.2.5.37 Attribute value (single-quoted) state
    # 12.2.5.38 Attribute value (unquoted) state
    assert_equal 3, frag.errors.length
  end

  def test_bogus_comment_state
    frag = fragment("<!\u0000>")
    # 12.2.5.42 Markup declaration open state: incorrectly-opened-comment
    # parse error
    # 12.2.5.41 Bogus comment state: unexpected-null-character parse error
    assert_equal 2, frag.errors.length
  end

  def test_comment_state
    frag = fragment("<!-- \u0000 -->")
    # 12.2.5.45 Comment state: unexpected-null-character parse error
    assert_equal 1, frag.errors.length
  end

  def test_doctype_name_states
    # There are two missing here for double quoted PUBLIC and SYSTEM values.
    doc = Nokogiri::HTML5.parse("<!DOCTYPE \u0000\u0000 PUBLIC '\u0000' '\u0000' \u0000>",
                                max_errors: 10)
    # 12.2.5.54 Before DOCTYPE name state: unexpected-null-character parse
    # error
    # 12.2.5.55 DOCTYPE name state: unexpected-null-character parse error
    # 12.2.5.60 DOCTYPE public identifier (single-quoted) state:
    # unexpected-null-character parse error
    # 12.2.5.66 DOCTYPE system identifier (single-quoted) state:
    # unexpected-null-character parse error
    # 12.2.5.67 After DOCTYPE system identifier state:
    # unexpected-character-after-doctype-system-identifier parse error
    # 12.2.5.68 Bogus DOCTYPE state: unexpected-null-character parse error
    # 12.2.6.4.1 The "initial" insertion mode: parse error
    assert_equal 7, doc.errors.length
  end

  def test_cdata_section_state
    frag = fragment("<script>//<![CDATA[\n\u0000\n//]]></script>")
    # 12.2.6.5 The rules for parsing tokens in foreign content: parse error
    assert_equal 1, frag.errors.length
  end

  def test_error_api_with_null
    frag = fragment("<p \u0000>")
    assert frag.errors.any?
    assert_includes frag.errors[0].to_s, "<p \u0000>"
  end
end
