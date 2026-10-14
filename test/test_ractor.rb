# frozen_string_literal: true

require "helper"

describe "Ractor" do
  def skip_unless_ractors
    skip("Ractor.shareable_proc is not available") unless defined?(Ractor.shareable_proc)
    skip("Ractor support requires libxml2 >= 2.14") unless Nokogiri.uses_libxml?(">= 2.14")
  end

  # rubocop:disable Lint/ConstantDefinitionInBlock
  module RactorWork # :nodoc:
    XML = "<root><item id='1'/><item id='2'/><!-- c --></root>"

    XSD = <<~EOX
      <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
        <xs:element name="root">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="item" maxOccurs="unbounded">
                <xs:complexType><xs:attribute name="id" type="xs:integer"/></xs:complexType>
              </xs:element>
            </xs:sequence>
          </xs:complexType>
        </xs:element>
      </xs:schema>
    EOX

    XSL = <<~EOX
      <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
        <xsl:template match="/"><count><xsl:value-of select="count(//item)"/></count></xsl:template>
      </xsl:stylesheet>
    EOX

    def self.everything
      doc = Nokogiri::XML(XML)
      html = Nokogiri::HTML4("<p>hello</p>")
      html5 = Nokogiri::HTML5("<p>hello</p>")
      schema = Nokogiri::XML::Schema(XSD)
      xslt = Nokogiri::XSLT(XSL)
      builder = Nokogiri::XML::Builder.new { |x| x.root { x.item(id: 3) } }

      {
        xpath: doc.xpath("//item").size,
        css: doc.css("item").size,
        html4: html.at_css("p").text,
        html5: html5.at_css("p").text,
        serialize: doc.to_xml,
        parse_errors: Nokogiri::XML("<root><a></root>").errors.map(&:message),
        schema_valid: schema.validate(doc).map(&:message),
        schema_invalid: schema.validate(Nokogiri::XML("<root><item id='x'/></root>")).map(&:message),
        xslt: xslt.transform(doc).to_xml,
        builder: builder.to_xml,
        html5_serialize: html5.to_html,
        html5_serialize_ascii: Nokogiri::HTML5("<p>café</p>").at_css("p").to_html(encoding: "US-ASCII"),
        dup: doc.dup.to_xml,
        clone: doc.clone.to_xml,
        version_info: Nokogiri::VERSION_INFO["nokogiri"]["version"],
      }
    end

    # A stylesheet whose transform reports an error mentioning +tag+, so that a message collected
    # from another Ractor's transform can be told apart.
    def self.transform_error(tag)
      xslt = Nokogiri::XSLT(<<~EOX)
        <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
          <xsl:template match="/"><xsl:value-of select="$#{tag}"/></xsl:template>
        </xsl:stylesheet>
      EOX
      xslt.transform(Nokogiri::XML(XML))
      nil
    rescue RuntimeError => e
      e.message
    end
  end
  # rubocop:enable Lint/ConstantDefinitionInBlock

  it "parses, searches, serializes, validates and transforms in a non-main Ractor" do
    skip_unless_ractors

    expected = RactorWork.everything
    actual = Ractor.new { RactorWork.everything }.value

    assert_equal(expected, actual)
    assert_equal(2, actual[:xpath])
    assert_equal(1, actual[:parse_errors].size)
    assert_empty(actual[:schema_valid])
    assert_equal(1, actual[:schema_invalid].size)
    assert_includes(actual[:xslt], "<count>2</count>")
  end

  it "uses XSLT extension modules registered in the main Ractor" do
    skip_unless_ractors

    shout = Class.new do
      def shout(str)
        str.to_s.upcase
      end
    end
    Nokogiri::XSLT.register("urn:nokogiri-test-ractor-shout", shout)
    Ractor.make_shareable(shout)

    result = Ractor.new do
      xsl = Nokogiri::XSLT(<<~EOX)
        <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                        xmlns:my="urn:nokogiri-test-ractor-shout" extension-element-prefixes="my">
          <xsl:template match="/"><out><xsl:value-of select="my:shout(string(//b))"/></out></xsl:template>
        </xsl:stylesheet>
      EOX
      xsl.transform(Nokogiri::XML("<a><b>two</b></a>")).root.text
    end.value

    assert_equal("TWO", result)
  end

  it "collects errors correctly when several Ractors run concurrently" do
    skip_unless_ractors

    ractors = 4.times.map do |i|
      Ractor.new(i) do |i|
        tag = "ractor#{i}"
        50.times.map do
          RactorWork.everything
          RactorWork.transform_error(tag)
        end
      end
    end

    ractors.each_with_index do |ractor, i|
      messages = ractor.value

      messages.each do |message|
        refute_nil(message, "transform did not raise")
        assert_includes(message, "ractor#{i}")
        4.times do |j|
          refute_includes(message, "ractor#{j}") unless j == i
        end
      end
    end
  end
end
