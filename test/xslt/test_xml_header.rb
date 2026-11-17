# frozen_string_literal: true

require "minitest/autorun"
require "nokogiri"

class OutputTest < Minitest::Test
  def test_output
    input_xml = <<~XML
      <?xml version="1.0" encoding="utf-8"?>
      <report>
        <title>My Report</title>
      </report>
    XML

    input_xsl = <<~XSL
      <?xml version="1.0" encoding="utf-8"?>
      <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
        <xsl:template match="/">
          <html>
            <head>
              <title><xsl:value-of select="report/title"/></title>
            </head>
            <body>
              <h1><xsl:value-of select="report/title"/></h1>
            </body>
          </html>
        </xsl:template>
      </xsl:stylesheet>
    XSL

    expected_output = <<~HTML
      <html>
      <head>
      <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
      <title>My Report</title>
      </head>
      <body><h1>My Report</h1></body>
      </html>
    HTML

    xml = Nokogiri::XML(input_xml)
    xsl = Nokogiri::XSLT(input_xsl)
    actual_output = xsl.apply_to(xml)

    expected_output_normalized = expected_output.gsub(/\s+/, "").downcase
    actual_output_normalized = actual_output.gsub(/\s+/, "").downcase

    assert_equal(expected_output_normalized, actual_output_normalized)
  end
end
