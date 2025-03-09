# frozen_string_literal: true

require "helper"

# This test uses Nokogiri::XML::Builder for code terseness.
# The test is primarily intended to test serialization behavior,
# not tree construction.
describe "serializing namespaces" do
  it "does not repeat xmlns definitions in child elements" do
    # https://github.com/sparklemotion/nokogiri/issues/3455
    doc = Nokogiri::XML::Builder.new do |xml|
      xml["ds"].Signature("xmlns:ds" => "http://www.w3.org/2000/09/xmldsig#") do
        xml["ds"].SignatureValue("foobar") do
        end
      end
    end.doc.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)

    assert_includes(doc, '<ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">')
    assert_includes(doc, "<ds:SignatureValue>foobar</ds:SignatureValue>")
  end

  it "does not repeat xmlns definitions even when explicitly defined" do
    doc = Nokogiri::XML::Builder.new do |xml|
      xml["ds"].Signature("xmlns:ds" => "http://www.w3.org/2000/09/xmldsig#") do
        xml["ds"].SignatureValue("foobar", "xmlns:ds" => "http://www.w3.org/2000/09/xmldsig#") do
        end
      end
    end.doc.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)

    assert_includes(doc, '<ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">')
    assert_includes(doc, "<ds:SignatureValue>foobar</ds:SignatureValue>")
  end

  it "redeclares xmlns definitions when shadowed" do
    doc = Nokogiri::XML::Builder.new do |xml|
      xml["dnd"].adventure("xmlns:dnd" => "http://www.w3.org/dungeons#") do
        xml["dnd"].party("xmlns:dnd" => "http://www.w3.org/dragons#") do
          xml["dnd"].members("xmlns:dnd" => "http://www.w3.org/dragons#") do
            xml["dnd"].character("xmlns:dnd" => "http://www.w3.org/dungeons#") do
              xml["dnd"].name("Nigel", "xmlns:dnd" => "http://www.w3.org/dungeons#")
            end
          end
        end
      end
    end.doc.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)

    assert_includes(doc, '<dnd:adventure xmlns:dnd="http://www.w3.org/dungeons#">')
    assert_includes(doc, '<dnd:party xmlns:dnd="http://www.w3.org/dragons#">')
    assert_includes(doc, "<dnd:members>")
    pending_if("https://github.com/sparklemotion/nokogiri/issues/3458", !Nokogiri.jruby?) do
      # Here MRI Ruby is incorrectly omitting the xmlns namespace declaration, i.e.:
      # '<dnd:character>'
      assert_includes(doc, '<dnd:character xmlns:dnd="http://www.w3.org/dungeons#">')
    end
    assert_includes(doc, "<dnd:name>Nigel</dnd:name>")
  end

  describe "default namespaces" do
    it "properly handles default namespaces" do
      doc = Nokogiri::XML::Builder.new do |xml|
        xml.root(xmlns: "http://default-namespace.org/") do
          xml.child("with default namespace")
          xml["specific"].child("with specific namespace", "xmlns:specific" => "http://specific-namespace.org/")
        end
      end.doc.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)

      assert_includes(doc, '<root xmlns="http://default-namespace.org/">')
      assert_includes(doc, "<child>with default namespace</child>")
      assert_includes(doc,
        '<specific:child xmlns:specific="http://specific-namespace.org/">with specific namespace</specific:child>')
    end

    it "handles nested default namespaces" do
      doc = Nokogiri::XML::Builder.new do |xml|
        xml.root(xmlns: "http://outer-namespace.org/") do
          xml.outer("in outer namespace")
          xml.inner(xmlns: "http://inner-namespace.org/") do
            xml.element("in inner namespace")
          end
          xml.another("back in outer namespace")
        end
      end.doc.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)

      assert_includes(doc, '<root xmlns="http://outer-namespace.org/">')
      assert_includes(doc, "<outer>in outer namespace</outer>")
      assert_includes(doc, '<inner xmlns="http://inner-namespace.org/">')
      pending_if("https://github.com/sparklemotion/nokogiri/issues/3457", Nokogiri.jruby?) do
        # Here JRuby is incorrectly adding the xmlns namespace declaration, i.e.:
        # '<element xmlns="http://outer-namespace.org/">in inner namespace</element>'
        assert_includes(doc, "<element>in inner namespace</element>")
      end
      assert_includes(doc, "<another>back in outer namespace</another>")
    end
  end

  describe "multiple namespaces on elements" do
    it "handles multiple namespaces declared on a single element" do
      doc = Nokogiri::XML::Builder.new do |xml|
        xml.root do
          xml.element(
            "xmlns:ns1" => "http://namespace1.org/",
            "xmlns:ns2" => "http://namespace2.org/",
            "xmlns:ns3" => "http://namespace3.org/",
          ) do
            xml["ns1"].first("using first namespace")
            xml["ns2"].second("using second namespace")
            xml["ns3"].third("using third namespace")
          end
        end
      end.doc.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)

      assert_includes(doc, '<element xmlns:ns1="http://namespace1.org/" xmlns:ns2="http://namespace2.org/" xmlns:ns3="http://namespace3.org/">')
      assert_includes(doc, "<ns1:first>using first namespace</ns1:first>")
      assert_includes(doc, "<ns2:second>using second namespace</ns2:second>")
      assert_includes(doc, "<ns3:third>using third namespace</ns3:third>")
    end

    it "handles multiple namespaces declared on middle elements" do
      doc = Nokogiri::XML::Builder.new do |xml|
        xml.root("xmlns:top" => "http://top-namespace.org/") do
          xml["top"].level1 do
            xml.middle(
              "xmlns:mid1" => "http://middle1-namespace.org/",
              "xmlns:mid2" => "http://middle2-namespace.org/",
            ) do
              xml["mid1"].item("using middle1 namespace")
              xml["mid2"].item("using middle2 namespace")
              xml["top"].item("still using top namespace")

              xml.bottom("xmlns:bot" => "http://bottom-namespace.org/") do
                xml["bot"].item("using bottom namespace")
                xml["mid1"].item("still using middle1 namespace")
              end
            end
          end
        end
      end.doc.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)

      assert_includes(doc, '<root xmlns:top="http://top-namespace.org/">')
      assert_includes(doc, "<top:level1>")
      assert_includes(doc, '<top:middle xmlns:mid1="http://middle1-namespace.org/" xmlns:mid2="http://middle2-namespace.org/">')
      assert_includes(doc, "<mid1:item>using middle1 namespace</mid1:item>")
      assert_includes(doc, "<mid2:item>using middle2 namespace</mid2:item>")
      assert_includes(doc, "<top:item>still using top namespace</top:item>")
      assert_includes(doc, '<top:bottom xmlns:bot="http://bottom-namespace.org/">')
      assert_includes(doc, "<bot:item>using bottom namespace</bot:item>")
      assert_includes(doc, "<mid1:item>still using middle1 namespace</mid1:item>")
    end
  end

  describe "namespace scope and visibility" do
    it "handles namespace prefixes reused with different URIs" do
      doc = Nokogiri::XML::Builder.new do |xml|
        xml.root do
          xml.outer("xmlns:ns" => "http://outer-uri.org/") do
            xml["ns"].element("outer namespace")

            xml.inner("xmlns:ns" => "http://inner-uri.org/") do
              xml["ns"].element("inner namespace")
            end

            xml["ns"].another("back to outer namespace")
          end
        end
      end.doc.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)

      assert_includes(doc, '<outer xmlns:ns="http://outer-uri.org/">')
      assert_includes(doc, "<ns:element>outer namespace</ns:element>")
      assert_includes(doc, '<inner xmlns:ns="http://inner-uri.org/">')
      assert_includes(doc, "<ns:element>inner namespace</ns:element>")
      assert_includes(doc, "<ns:another>back to outer namespace</ns:another>")
    end

    it "handles mixing default and prefixed namespaces" do
      doc = Nokogiri::XML::Builder.new do |xml|
        xml.root(:xmlns => "http://default.org/", "xmlns:ns" => "http://prefixed.org/") do
          xml.default_element("in default namespace")
          xml["ns"].prefixed_element("in prefixed namespace")

          xml.mixed(xmlns: "http://new-default.org/") do
            xml.new_default("in new default namespace")
            xml["ns"].still_prefixed("still using original prefixed namespace")
          end
        end
      end.doc.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)

      assert_includes(doc, '<root xmlns="http://default.org/" xmlns:ns="http://prefixed.org/">')
      assert_includes(doc, "<default_element>in default namespace</default_element>")
      assert_includes(doc, "<ns:prefixed_element>in prefixed namespace</ns:prefixed_element>")
      assert_includes(doc, '<mixed xmlns="http://new-default.org/">')
      pending_if("https://github.com/sparklemotion/nokogiri/issues/3457", Nokogiri.jruby?) do
        # Here JRuby is incorrectly adding the xmlns namespace declaration, i.e.:
        # '<new_default xmlns="http://default.org/">in new default namespace</new_default>'
        assert_includes(doc, "<new_default>in new default namespace</new_default>")
      end
      assert_includes(doc, "<ns:still_prefixed>still using original prefixed namespace</ns:still_prefixed>")
    end
  end

  describe "namespace inheritance" do
    it "inherits namespaces from ancestors without redeclaring them" do
      doc = Nokogiri::XML::Builder.new do |xml|
        xml.root("xmlns:a" => "http://a.org/", "xmlns:b" => "http://b.org/") do
          xml["a"].first do
            xml["a"].second do
              xml["b"].inner("using b namespace inside a")
            end
          end
          xml["b"].third do
            xml["a"].inner("using a namespace inside b")
          end
        end
      end.doc.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)

      assert_includes(doc, '<root xmlns:a="http://a.org/" xmlns:b="http://b.org/">')
      assert_includes(doc, "<a:first>")
      assert_includes(doc, "<a:second>")
      assert_includes(doc, "<b:inner>using b namespace inside a</b:inner>")
      assert_includes(doc, "<b:third>")
      assert_includes(doc, "<a:inner>using a namespace inside b</a:inner>")

      # Ensure namespaces aren't redundantly declared
      assert_equal(1, doc.scan('xmlns:a="http://a.org/"').count)
      assert_equal(1, doc.scan('xmlns:b="http://b.org/"').count)
    end

    it "works with namespace declarations at different levels of the hierarchy" do
      doc = Nokogiri::XML::Builder.new do |xml|
        xml.root("xmlns:top" => "http://top.org/") do
          xml["top"].level1 do
            xml["top"].level2("xmlns:mid" => "http://mid.org/") do
              xml["mid"].item1
              xml["top"].item2

              xml["mid"].container("xmlns:deep" => "http://deep.org/") do
                xml["deep"].deepest
                xml["mid"].stillMid
                xml["top"].stillTop
              end
            end
          end
        end
      end.doc.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)

      assert_includes(doc, '<root xmlns:top="http://top.org/">')
      assert_includes(doc, '<top:level2 xmlns:mid="http://mid.org/">')
      assert_includes(doc, "<mid:item1/>")
      assert_includes(doc, "<top:item2/>")
      assert_includes(doc, '<mid:container xmlns:deep="http://deep.org/">')
      assert_includes(doc, "<deep:deepest/>")
      assert_includes(doc, "<mid:stillMid/>")
      assert_includes(doc, "<top:stillTop/>")
    end
  end
end
