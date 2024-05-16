# frozen_string_literal: true

require "helper"

module Nokogiri
  class TestCase
    describe Nokogiri::XSLT::Stylesheet do
      def check_params(result_doc, params)
        result_doc.xpath("/root/params/*").each do |p|
          assert_equal(p.content, params[p.name.intern])
        end
      end

      let(:doc) { Nokogiri::XML(File.open(XML_FILE)) }

      def test_class_methods
        style = Nokogiri::XSLT(File.read(XSLT_FILE))

        assert(result = style.apply_to(doc, ["title", '"Grandma"']))
        assert_match(%r{<h1>Grandma</h1>}, result)
      end

      def test_transform
        assert(style = Nokogiri::XSLT.parse(File.read(XSLT_FILE)))

        assert(result = style.apply_to(doc, ["title", '"Booyah"']))
        assert_match(%r{<h1>Booyah</h1>}, result)
        assert_match(%r{<th.*Employee ID</th>}, result)
        assert_match(%r{<th.*Name</th>}, result)
        assert_match(%r{<th.*Position</th>}, result)
        assert_match(%r{<th.*Salary</th>}, result)
        assert_match(%r{<td>EMP0003</td>}, result)
        assert_match(%r{<td>Margaret Martin</td>}, result)
        assert_match(%r{<td>Computer Specialist</td>}, result)
        assert_match(%r{<td>100,000</td>}, result)
        refute_match(/Dallas|Texas/, result)
        refute_match(/Female/, result)

        assert(result = style.apply_to(doc, ["title", '"Grandma"']))
        assert_match(%r{<h1>Grandma</h1>}, result)

        assert(result = style.apply_to(doc))
        assert_match(%r{<h1></h1>|<h1/>}, result)
      end

      def test_xml_declaration
        input_xml = <<~EOS
          <?xml version="1.0" encoding="utf-8"?>
          <report>
            <title>My Report</title>
          </report>
        EOS

        input_xsl = <<~EOS
          <?xml version="1.0" encoding="utf-8"?>
          <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
            <xsl:output method="xml" version="1.0" encoding="utf-8" indent="yes"/>
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
        EOS

        require "nokogiri"

        xml = ::Nokogiri::XML(input_xml)
        xsl = ::Nokogiri::XSLT(input_xsl)

        assert_includes(xsl.apply_to(xml), '<?xml version="1.0" encoding="utf-8"?>')
      end

      def test_transform_with_output_style
        xslt = if Nokogiri.jruby?
          Nokogiri::XSLT(<<~eoxslt)
            <?xml version="1.0" encoding="ISO-8859-1"?>

            <xsl:stylesheet version="1.0"
            xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
            <xsl:output method="text" version="1.0"
            encoding="iso-8859-1" indent="yes"/>

            <xsl:param name="title"/>

            <xsl:template match="/">
              <html>
              <body>
                <xsl:for-each select="staff/employee">
                <tr>
                  <td><xsl:value-of select="employeeId"/></td>
                  <td><xsl:value-of select="name"/></td>
                  <td><xsl:value-of select="position"/></td>
                  <td><xsl:value-of select="salary"/></td>
                </tr>
                </xsl:for-each>
              </body>
              </html>
            </xsl:template>

            </xsl:stylesheet>
          eoxslt
        else
          Nokogiri::XSLT(<<~eoxslt)
            <?xml version="1.0" encoding="ISO-8859-1"?>

            <xsl:stylesheet version="1.0"
            xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
            <xsl:output method="text" version="1.0"
            encoding="iso-8859-1" indent="yes"/>

            <xsl:param name="title"/>

            <xsl:template match="/">
              <html>
              <body>
                <xsl:for-each select="staff/employee">
                <tr>
                  <td><xsl:value-of select="employeeId"/></td>
                  <td><xsl:value-of select="name"/></td>
                  <td><xsl:value-of select="position"/></td>
                  <td><xsl:value-of select="salary"/></td>
                </tr>
                </xsl:for-each>
                </table>
              </body>
              </html>
            </xsl:template>

            </xsl:stylesheet>
          eoxslt
        end
        result = xslt.apply_to(doc, ["title", "foo"])
        refute_match(/<td>/, result)

        # the entity-form is for systems with this bug with Encodings.properties
        # https://issues.apache.org/jira/browse/XALANJ-2618
        # a.k.a. "Attempt to output character of integral value 48 that is not represented in specified output encoding of iso-8859-1."
        assert_match(
          /This is an adjacent|&#84;&#104;&#105;&#115;&#32;&#105;&#115;&#32;&#97;&#110;&#32;&#97;&#100;&#106;&#97;&#99;&#101;&#110;&#116;/, result
        )
      end

      def test_transform_arg_error
        assert(style = Nokogiri::XSLT(File.read(XSLT_FILE)))
        assert_raises(TypeError) do
          style.transform(doc, :foo)
        end
      end

      def test_transform_with_hash
        assert(style = Nokogiri::XSLT(File.read(XSLT_FILE)))
        result = style.transform(doc, { "title" => '"Booyah"' })
        assert_predicate(result, :html?)
        assert_equal("Booyah", result.at_css("h1").content)
      end

      def test_transform2
        assert(style = Nokogiri::XSLT(File.open(XSLT_FILE)))
        assert(result_doc = style.transform(doc))
        assert_predicate(result_doc, :html?)
        assert_equal("", result_doc.at_css("h1").content)

        assert(style = Nokogiri::XSLT(File.read(XSLT_FILE)))
        assert(result_doc = style.transform(doc, ["title", '"Booyah"']))
        assert_predicate(result_doc, :html?)
        assert_equal("Booyah", result_doc.at_css("h1").content)

        assert(result_string = style.apply_to(doc, ["title", '"Booyah"']))
        assert_equal(result_string, style.serialize(result_doc))
      end

      def test_transform_with_quote_params
        assert(style = Nokogiri::XSLT(File.open(XSLT_FILE)))
        assert(result_doc = style.transform(doc, Nokogiri::XSLT.quote_params(["title", "Booyah"])))
        assert_predicate(result_doc, :html?)
        assert_equal("Booyah", result_doc.at_css("h1").content)

        assert(style = Nokogiri::XSLT.parse(File.read(XSLT_FILE)))
        assert(result_doc = style.transform(doc, Nokogiri::XSLT.quote_params({ "title" => "Booyah" })))
        assert_predicate(result_doc, :html?)
        assert_equal("Booyah", result_doc.at_css("h1").content)
      end

      def test_exslt
        # see http://yokolet.blogspot.com/2010/10/pure-java-nokogiri-xslt-extension.html")
        skip_unless_libxml2("cannot get it working on JRuby")

        assert(doc = Nokogiri::XML.parse(File.read(EXML_FILE)))
        assert_predicate(doc, :xml?)

        assert(style = Nokogiri::XSLT.parse(File.read(EXSLT_FILE)))
        params = {
          p1: "xxx",
          p2: "x'x'x",
          p3: 'x"x"x',
          p4: '"xxx"',
        }
        result_doc = Nokogiri::XML.parse(style.apply_to(
          doc,
          Nokogiri::XSLT.quote_params(params),
        ))

        assert_equal("func-result", result_doc.at("/root/function").content)
        assert_equal(3, result_doc.at("/root/max").content.to_i)
        if Nokogiri::VersionInfo.instance.libxslt_has_datetime?
          assert_match(
            /\d{4}-\d\d-\d\d([-|+]\d\d:\d\d)?/,
            result_doc.at("/root/date").content,
          )
        end
        result_doc.xpath("/root/params/*").each do |p|
          assert_equal(p.content, params[p.name.intern])
        end
        check_params(result_doc, params)
        result_doc = Nokogiri::XML.parse(style.apply_to(
          doc,
          Nokogiri::XSLT.quote_params(params.to_a.flatten),
        ))
        check_params(result_doc, params)
      end

      def test_xslt_parameters
        # see http://yokolet.blogspot.com/2010/10/pure-java-nokogiri-xslt-extension.html")
        skip_unless_libxml2("cannot get it working on JRuby")

        xslt_str = <<~EOX
          <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >
            <xsl:template match="/">
              <xsl:value-of select="$foo" />
            </xsl:template>
          </xsl:stylesheet>
        EOX

        xslt = Nokogiri::XSLT(xslt_str)
        doc = Nokogiri::XML("<root />")
        assert_match(/bar/, xslt.transform(doc, Nokogiri::XSLT.quote_params("foo" => "bar")).to_s)
      end

      def test_xslt_transform_error
        # see http://yokolet.blogspot.com/2010/10/pure-java-nokogiri-xslt-extension.html")
        skip_unless_libxml2("cannot get it working on JRuby")

        xslt_str = <<~EOX
          <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >
            <xsl:template match="/">
              <xsl:value-of select="$foo" />
            </xsl:template>
          </xsl:stylesheet>
        EOX

        xslt = Nokogiri::XSLT(xslt_str)
        doc = Nokogiri::XML("<root />")
        assert_raises(RuntimeError) { xslt.transform(doc) }
      end

      def test_xslt_parse_error
        xslt_str = <<~EOX
          <xsl:stylesheet version="1.0"
           xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
            <!-- Not well-formed: -->
            <xsl:template match="/"/>
              <values>
                <xsl:for-each select="//*">
                  <value>
                    <xsl:value-of select="@id"/>
                  </value>
                </xsl:for-each>
              </values>
            </xsl:template>
          </xsl:stylesheet>}
        EOX
        assert_raises(RuntimeError) { Nokogiri::XSLT.parse(xslt_str) }
      end

      def test_passing_a_non_document_to_transform
        xsl = Nokogiri::XSLT('<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"></xsl:stylesheet>')
        assert_raises(ArgumentError) { xsl.transform("<div></div>") }
        assert_raises(ArgumentError) { xsl.transform(Nokogiri::HTML("").css("body")) }
      end

      def test_non_html_xslt_transform
        xml = Nokogiri.XML(<<~EOXML)
          <a>
            <b>
            <c>123</c>
              </b>
            </a>
        EOXML

        xsl = Nokogiri.XSLT(<<~EOXSL)
          <xsl:stylesheet version="1.0"
                          xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

            <xsl:output encoding="UTF-8" indent="yes" method="xml" />

            <xsl:template match="/">
              <a><xsl:value-of select="/a" /></a>
            </xsl:template>
          </xsl:stylesheet>
        EOXSL

        result = xsl.transform(xml)
        refute_predicate(result, :html?)
      end

      it "should not crash when given XPath 2.0 features" do
        #
        #  https://github.com/sparklemotion/nokogiri/issues/1802
        #
        #  note that here the XPath 2.0 feature is `decimal`.
        #  this test case is taken from the example provided in the original issue.
        #
        #  also: xalan 2.7.3 seems to understand the XPath 2.0 expression
        #
        skip_unless_libxml2("testing a crash that only happened with libxml2")

        xml = <<~EOXML
          <?xml version="1.0" encoding="UTF-8"?>
          <Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"
                   xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
                   xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                   xsi:schemaLocation="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2">
            <cac:TaxTotal>
              <cbc:TaxAmount currencyID="EUR">48.00</cbc:TaxAmount>
            </cac:TaxTotal>
          </Invoice>
        EOXML

        xsl = <<~EOXSL
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                          xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
                          xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
                          xmlns:ubl="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"
                          xmlns:xs="http://www.w3.org/2001/XMLSchema"
                          version="1.0">
            <xsl:template match="/">
              <xsl:apply-templates select="/" mode="qwerty"/>
            </xsl:template>
            <xsl:template match="/ubl:Invoice/cac:TaxTotal" priority="1001" mode="qwerty">
              <xsl:choose>
                <xsl:when test="(round(xs:decimal(child::cbc:TaxAmount)))"/>
              </xsl:choose>
            </xsl:template>
          </xsl:stylesheet>
        EOXSL

        doc = Nokogiri::XML(xml)
        xslt = Nokogiri::XSLT(xsl)
        exception = assert_raises(RuntimeError) do
          xslt.transform(doc)
        end
        if Nokogiri.uses_libxml?(">= 2.13") # upstream commit 954b8984
          assert_includes(exception.message, "Unregistered function")
        else
          assert_match(/xmlXPathCompOpEval: function .* not found/, exception.message)
        end
      end

      describe "https://github.com/sparklemotion/nokogiri/issues/2800" do
        let(:doc) do
          Nokogiri::XML::Document.parse(<<~XML)
            <catalog>
              <entry><title>abc</title></entry>
              <entry><title>   </title></entry>
              <entry><title>xyz</title></entry>
            </catalog>
          XML
        end

        let(:stylesheet) do
          Nokogiri::XSLT.parse(<<~XSL)
            <?xml version="1.0" encoding="UTF-8"?>
            <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
              <xsl:strip-space elements="title" />
              <xsl:template match="/">
                <xsl:for-each select="catalog/entry">[<xsl:value-of select="title" />]</xsl:for-each>
              </xsl:template>
            </xsl:stylesheet>
          XSL
        end

        it "should modify the original doc if no wrapped blank text nodes would be removed" do
          # this is the default libxslt behavior
          skip_unless_libxml2("libxslt bug is not present in JRuby")

          result = stylesheet.transform(doc)

          assert_includes(result.to_s, "[abc][][xyz]", "xsl:strip-space should work")
          doc.at_css("entry:nth-child(2)").tap do |entry|
            assert_equal(1, entry.children.length)
            assert_equal("", entry.children.first.content, "original doc should be modified")
          end
        end

        it "should not modify the original doc if wrapped blank text nodes would be removed" do
          skip_unless_libxml2("libxslt bug is not present in JRuby")

          # wrap the blank text node
          assert(child = doc.css("title").children.find(&:blank?))

          result = stylesheet.transform(doc)

          assert(child.to_s) # raise a valgrind error if the fix isn't working

          assert_includes(result.to_s, "[abc][][xyz]", "xsl:strip-space should work")
          doc.at_css("entry:nth-child(2)").tap do |entry|
            assert_equal(1, entry.children.length)
            assert_equal("   ", entry.children.first.content, "original doc is unmodified")
          end
        end
      end

      describe "DEFAULT_XSLT parse options" do
        it "is the union of DEFAULT_XML and libxslt's XSLT_PARSE_OPTIONS" do
          xslt_parse_options = Nokogiri::XML::ParseOptions.new.noent.dtdload.dtdattr.nocdata
          expected = Nokogiri::XML::ParseOptions::DEFAULT_XML | xslt_parse_options.options
          assert_equal(expected, Nokogiri::XML::ParseOptions::DEFAULT_XSLT)
        end

        it "parses docs the same as xsltproc" do
          skip_unless_libxml2("JRuby implementation disallows this edge case XSLT")

          # see https://github.com/sparklemotion/nokogiri/issues/1940
          xml = "<t></t>"
          xsl = <<~EOF
            <?xml version="1.0"?>
            <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
            <xsl:output method="text" omit-xml-declaration="no" />
              <xsl:template match="/">
                <xsl:text disable-output-escaping="yes"><![CDATA[<>]]></xsl:text>
              </xsl:template>
            </xsl:stylesheet>
          EOF

          doc = Nokogiri::XML(xml)
          stylesheet = Nokogiri::XSLT(xsl)

          # TODO: ideally I'd like to be able to access the parse options in the final object
          # assert_equal(Nokogiri::XML::ParseOptions::DEFAULT_XSLT, stylesheet.document.parse_options)

          result = stylesheet.transform(doc)
          assert_equal("<>", result.children.to_xml)
        end
      end

      describe "XSLT.quote_params" do
        it "returns quoted values" do
          assert_equal(["asdf", "'qwer'"], Nokogiri::XSLT.quote_params({ "asdf" => "qwer" }))
        end

        it "stringifies non-string keys and values" do
          assert_equal(["asdf", "'1234'"], Nokogiri::XSLT.quote_params({ asdf: 1234 }))
          assert_equal(["1234", "'asdf'"], Nokogiri::XSLT.quote_params({ 1234 => :asdf }))
        end

        it "handles multiple key-value pairs" do
          actual = Nokogiri::XSLT.quote_params({ "abcd" => "efgh", "ijkl" => "mnop" })
          expected = ["abcd", "'efgh'", "ijkl", "'mnop'"]
          assert_equal(expected, actual)
        end

        it "handles an array of pairs" do
          actual = Nokogiri::XSLT.quote_params(["abcd", "efgh", "ijkl", "mnop"])
          expected = ["abcd", "'efgh'", "ijkl", "'mnop'"]
          assert_equal(expected, actual)
        end

        it "handles double quotes" do
          assert_equal(["a", %{'"asdf"'}], Nokogiri::XSLT.quote_params({ "a" => %{"asdf"} }))
        end

        it "handles single quotes" do
          actual = Nokogiri::XSLT.quote_params({ "a" => %{'asdf'} })
          expected = ["a", %{concat('', "'", 'asdf', "'", '')}]
          assert_equal(expected, actual)

          actual = Nokogiri::XSLT.quote_params({ "a" => %{a'sd'f} })
          expected = ["a", %{concat('a', "'", 'sd', "'", 'f')}]
          assert_equal(expected, actual)
        end

        it "does not change the input parameters" do
          input_h = { "abcd" => "efgh", "ijkl" => "mnop" }
          expected_h = input_h.dup
          input_a = input_h.to_a.flatten
          expected_a = input_a.dup

          Nokogiri::XSLT.quote_params(input_h)
          assert_equal(expected_h, input_h)

          Nokogiri::XSLT.quote_params(input_a)
          assert_equal(expected_a, input_a)
        end
      end
    end
  end
end
