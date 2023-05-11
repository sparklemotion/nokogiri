# frozen_string_literal: true

require "helper"

module Nokogiri
  module XSLT
    class TestExceptionHandling < Nokogiri::TestCase
      def test_java_exception_handling
        skip_unless_jruby("This test is for Java only")

        xml = Nokogiri.XML(<<~EOXML)
          <foo>
            <bar/>
          </foo>
        EOXML

        xsl = Nokogiri.XSLT(<<~EOXSL)
          <?xml version="1.0"?>
          <xsl:stylesheet version="1.0"

            xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
            <xsl:template match="/">
              <a/>
              <b/>
            </xsl:template>
          </xsl:stylesheet>
        EOXSL

        e = assert_raises(RuntimeError) do
          xsl.transform(xml)
        end

        assert_includes(e.to_s, "HIERARCHY_REQUEST_ERR")
      end
    end
  end
end
