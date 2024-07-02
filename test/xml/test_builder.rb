# -*- coding: utf-8 -*-
# frozen_string_literal: true

require "helper"

module Nokogiri
  module XML
    class TestBuilder < Nokogiri::TestCase
      def test_attribute_sensitivity
        xml = Nokogiri::XML::Builder.new do |x|
          x.tag("hello", "abcDef" => "world")
        end.to_xml
        doc = Nokogiri.XML(xml)
        assert_equal("world", doc.root["abcDef"])
      end

      def test_builder_resilient_to_exceptions
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.root do
            begin
              xml.a { raise "badjoras" }
            rescue StandardError
              # Ignored
            end

            xml.b
          end
        end

        expected_output = <<~HEREDOC
          <?xml version="1.0"?>
          <root>
            <a/>
            <b/>
          </root>
        HEREDOC
        assert_equal(expected_output, builder.to_xml)
      end

      def test_builder_with_utf8_text
        text = "test ﺵ "
        doc = Nokogiri::XML::Builder.new(encoding: "UTF-8") { |xml| xml.test(text) }.doc
        assert_equal(text, doc.content)
      end

      def test_builder_escape
        xml = Nokogiri::XML::Builder.new do |x|
          x.condition("value < 1", attr: "value < 1")
        end.to_xml
        doc = Nokogiri.XML(xml)
        assert_equal("value < 1", doc.root["attr"])
        assert_equal("value < 1", doc.root.content)
      end

      def test_builder_namespace
        doc = Nokogiri::XML::Builder.new do |xml|
          xml.a("xmlns:a" => "x") do
            xml.b("xmlns:a" => "x", "xmlns:b" => "y")
          end
        end.doc

        b = doc.at("b")
        assert(b)
        assert_equal({ "xmlns:a" => "x", "xmlns:b" => "y" }, b.namespaces)
        assert_equal({ "xmlns:b" => "y" }, namespaces_defined_on(b))
      end

      def test_builder_namespace_part_deux
        doc = Nokogiri::XML::Builder.new do |xml|
          xml.a("xmlns:b" => "y") do
            xml.b("xmlns:a" => "x", "xmlns:b" => "y", "xmlns:c" => "z")
          end
        end.doc

        b = doc.at("b")
        assert(b)
        assert_equal({ "xmlns:a" => "x", "xmlns:b" => "y", "xmlns:c" => "z" }, b.namespaces)
        assert_equal({ "xmlns:a" => "x", "xmlns:c" => "z" }, namespaces_defined_on(b))
      end

      def test_builder_with_unlink
        b = Nokogiri::XML::Builder.new do |xml|
          xml.foo do
            xml.bar { xml.parent.unlink }
            xml.bar2
          end
        end
        assert(b)
      end

      def test_with_root
        doc = Nokogiri::XML(File.read(XML_FILE))
        Nokogiri::XML::Builder.with(doc.at_css("employee")) do |xml| # rubocop:disable Style/SymbolProc
          xml.foo
        end
        assert_equal(1, doc.xpath("//employee/foo").length)
      end

      def test_root_namespace_default_decl
        b = Nokogiri::XML::Builder.new { |xml| xml.root(xmlns: "one:two") }
        doc = b.doc
        assert_equal("one:two", doc.root.namespace.href)
        assert_equal({ "xmlns" => "one:two" }, doc.root.namespaces)
      end

      def test_root_namespace_multi_decl
        b = Nokogiri::XML::Builder.new do |xml|
          xml.root(:xmlns => "one:two", "xmlns:foo" => "bar") do
            xml.hello
          end
        end
        doc = b.doc
        assert_equal("one:two", doc.root.namespace.href)
        assert_equal({ "xmlns" => "one:two", "xmlns:foo" => "bar" }, doc.root.namespaces)

        assert_equal("one:two", doc.at("hello").namespace.href)
      end

      def test_non_root_namespace
        b = Nokogiri::XML::Builder.new do |xml|
          xml.root { xml.hello(xmlns: "one") }
        end
        assert_equal("one", b.doc.at("hello", "xmlns" => "one").namespace.href)
      end

      def test_builder_namespace_inheritance_true
        # see https://github.com/sparklemotion/nokogiri/issues/2317
        result = Nokogiri::XML::Builder.new(encoding: "utf-8") do |xml|
          xml["soapenv"].Envelope("xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/") do
            xml.Header
          end
        end
        assert(result.doc.namespace_inheritance)
        assert(
          result.doc.at_xpath("//soapenv:Header", "soapenv" => "http://schemas.xmlsoap.org/soap/envelope/"),
          "header element should have a namespace",
        )
      end

      def test_builder_namespace_inheritance_false
        # see https://github.com/sparklemotion/nokogiri/issues/2317
        result = Nokogiri::XML::Builder.new(encoding: "utf-8", namespace_inheritance: false) do |xml|
          xml["soapenv"].Envelope("xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/") do
            xml.Header
          end
        end
        refute(result.doc.namespace_inheritance)
        assert(
          result.doc.at_xpath("//Header"),
          "header element should not have a namespace",
        )
      end

      def test_builder_namespace_inheritance_false_part_deux
        # see https://github.com/sparklemotion/nokogiri/issues/1712
        result = Nokogiri::XML::Builder.new(encoding: "utf-8", namespace_inheritance: false) do |xml|
          xml["soapenv"].Envelope("xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/", "xmlns:emer" => "http://dashcs.com/api/v1/emergency") do
            xml["soapenv"].Header
            xml["soapenv"].Body do
              xml["emer"].validateLocation do
                # these should not have a namespace
                xml.location do
                  xml.address("Some place over the rainbow")
                end
              end
            end
          end
        end
        assert(
          result.doc.at_xpath("//emer:validateLocation", { "emer" => "http://dashcs.com/api/v1/emergency" }),
          "expected validateLocation node to have a namespace",
        )
        assert(result.doc.at_xpath("//location"), "expected location node to not have a namespace")
      end

      def test_specify_namespace
        b = Nokogiri::XML::Builder.new do |xml|
          xml.root("xmlns:foo" => "bar") do
            xml[:foo].bar
            xml["foo"].baz
          end
        end
        doc = b.doc
        assert_equal("bar", doc.at("foo|bar", "foo" => "bar").namespace.href)
        assert_equal("bar", doc.at("foo|baz", "foo" => "bar").namespace.href)
      end

      def test_dtd_in_builder_output
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.doc.create_internal_subset(
            "html",
            "-//W3C//DTD HTML 4.01 Transitional//EN",
            "http://www.w3.org/TR/html4/loose.dtd",
          )
          xml.root do
            xml.foo
          end
        end
        assert_match(
          %r{<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">},
          builder.to_xml,
        )
      end

      def test_specify_namespace_nested
        b = Nokogiri::XML::Builder.new do |xml|
          xml.root("xmlns:foo" => "bar") do
            xml.yay do
              xml[:foo].bar

              xml.yikes do
                xml["foo"].baz
              end
            end
          end
        end
        doc = b.doc
        assert_equal("bar", doc.at("foo|bar", "foo" => "bar").namespace.href)
        assert_equal("bar", doc.at("foo|baz", "foo" => "bar").namespace.href)
      end

      def test_specified_namespace_postdeclared
        doc = Nokogiri::XML::Builder.new do |xml|
          xml.a do
            xml[:foo].b("xmlns:foo" => "bar")
          end
        end.doc
        a = doc.at("a")
        assert_empty(a.namespaces)

        b = doc.at_xpath("//foo:b", { foo: "bar" })
        assert(b)
        assert_equal({ "xmlns:foo" => "bar" }, b.namespaces)
        assert_equal("b", b.name)
        assert_equal("bar", b.namespace.href)
      end

      def test_specified_namespace_undeclared
        assert_raises(ArgumentError) do
          Nokogiri::XML::Builder.new do |xml|
            xml.root do
              xml[:foo].bar
            end
          end
        end
      end

      def test_set_namespace_inheritance
        assert(Nokogiri::XML::Builder.new.doc.namespace_inheritance)
        refute(Nokogiri::XML::Builder.new(namespace_inheritance: false).doc.namespace_inheritance)
      end

      def test_set_encoding
        builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
          xml.root do
            xml.bar("blah")
          end
        end
        assert_equal("UTF-8", builder.doc.encoding)
        assert_match("UTF-8", builder.to_xml)
      end

      def test_bang_and_underscore_is_escaped
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.root do
            xml.p_("adsfadsf")
            xml.p!("adsfadsf")
          end
        end
        assert_equal(2, builder.doc.xpath("//p").length)
      end

      def test_square_brackets_set_attributes
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.root do
            foo = xml.foo
            foo["id"] = "hello"
            assert_equal("hello", foo["id"])
          end
        end
        assert_equal(1, builder.doc.xpath('//foo[@id = "hello"]').length)
      end

      def test_nested_local_variable_and_instance_variable
        @ivar = "hello"
        local_var = "hello world"
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.root do
            xml.foo(local_var)
            xml.bar(@ivar)
            xml.baz do
              xml.text(@ivar)
            end
            xml.quux.foo { xml.text(@ivar) }
          end
        end

        assert_equal("hello world", builder.doc.at("//root/foo").content)
        assert_equal("hello", builder.doc.at("//root/bar").content)
        assert_equal("hello", builder.doc.at("baz").content)
        assert_equal("hello", builder.doc.at("quux.foo").content)
      end

      def test_raw_append
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.root do
            xml << "hello"
          end
        end

        assert_equal("hello", builder.doc.at("/root").content)
      end

      def test_node_builder_method_missing_yield
        # https://github.com/sparklemotion/nokogiri/issues/1041
        who_is_self = nil

        Nokogiri::XML::Builder.new do |xml|
          xml.root do
            xml.div.foo { who_is_self = self }
          end
        end

        assert_equal(self, who_is_self)
      end

      def test_node_builder_method_missing_instance_eval
        # https://github.com/sparklemotion/nokogiri/issues/1041
        who_is_self = nil

        builder = Nokogiri::XML::Builder.new do
          root do
            div.foo { who_is_self = self }
          end
        end

        assert_equal(builder, who_is_self)
      end

      def test_raw_append_with_instance_eval
        builder = Nokogiri::XML::Builder.new do
          root do
            self << "hello"
          end
        end

        assert_equal("hello", builder.doc.at("/root").content)
      end

      def test_raw_xml_append
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.root do
            xml << "<aaa><bbb/><ccc/></aaa>"
          end
        end

        assert_equal(["aaa"], builder.doc.at_css("root").children.collect(&:name))
        assert_equal(["bbb", "ccc"], builder.doc.at_css("aaa").children.collect(&:name))
      end

      def test_raw_xml_append_with_namespaces
        doc = Nokogiri::XML::Builder.new do |xml|
          xml.root("xmlns:foo" => "x", "xmlns" => "y") do
            xml << '<Element foo:bar="bazz"/>'
          end
        end.doc

        el = doc.at("Element")
        refute_nil(el)

        assert_equal("y", el.namespace.href)
        assert_nil(el.namespace.prefix)

        attr = el.attributes["bar"]
        refute_nil(attr)
        refute_nil(attr.namespace)
        assert_equal("foo", attr.namespace.prefix)
      end

      def test_cdata
        builder = Nokogiri::XML::Builder.new do
          root do
            cdata("hello world")
          end
        end
        assert_equal(
          "<?xml version=\"1.0\"?><root><![CDATA[hello world]]></root>",
          builder.to_xml.delete("\n"),
        )
      end

      def test_comment
        builder = Nokogiri::XML::Builder.new do
          root do
            comment("this is a comment")
          end
        end
        assert_predicate(builder.doc.root.children.first, :comment?)
      end

      def test_builder_no_block
        string = "hello world"
        builder = Nokogiri::XML::Builder.new
        builder.root do
          cdata(string)
        end
        assert_equal(
          "<?xml version=\"1.0\"?><root><![CDATA[hello world]]></root>",
          builder.to_xml.delete("\n"),
        )
      end

      def test_builder_can_inherit_parent_namespace
        builder = Nokogiri::XML::Builder.new
        builder.products do
          builder.parent.default_namespace = "foo"
          builder.product do
            builder.parent.default_namespace = nil
          end
        end
        doc = builder.doc
        ["product", "products"].each do |n|
          assert_equal("foo", doc.at_xpath("//*[local-name() = '#{n}']").namespace.href)
        end
      end

      def test_builder_can_handle_namespace_override
        builder = Nokogiri::XML::Builder.new
        builder.products("xmlns:foo" => "bar") do
          builder.product("xmlns:foo" => "baz")
        end

        doc = builder.doc
        assert_equal("baz", doc.at_xpath("//*[local-name() = 'product']").namespaces["xmlns:foo"])
        assert_equal("bar", doc.at_xpath("//*[local-name() = 'products']").namespaces["xmlns:foo"])
        assert_nil(doc.at_xpath("//*[local-name() = 'products']").namespace)
      end

      def test_builder_reuses_namespaces
        # see https://github.com/sparklemotion/nokogiri/issues/1810 for memory leak report
        builder = Nokogiri::XML::Builder.new
        builder.send(:envelope, { "xmlns" => "http://schemas.xmlsoap.org/soap/envelope/" }) do
          builder.send(:package, { "xmlns" => "http://schemas.xmlsoap.org/soap/envelope/" })
        end
        envelope = builder.doc.at_css("envelope")
        package = builder.doc.at_css("package")
        assert_equal(envelope.namespace, package.namespace)
        assert_same(envelope.namespace, package.namespace)
      end

      def test_builder_uses_proper_document_class
        xml_builder = Nokogiri::XML::Builder.new
        assert_instance_of(Nokogiri::XML::Document, xml_builder.doc)

        html_builder = Nokogiri::HTML4::Builder.new
        assert_instance_of(Nokogiri::HTML4::Document, html_builder.doc)

        foo_builder = ThisIsATestBuilder.new
        assert_instance_of(Nokogiri::XML::Document, foo_builder.doc)

        foo_builder = ThisIsAnotherTestBuilder.new
        assert_instance_of(Nokogiri::HTML4::Document, foo_builder.doc)
      end

      private

      def namespaces_defined_on(node)
        Hash[*node.namespace_definitions.collect { |n| ["xmlns:" + n.prefix, n.href] }.flatten]
      end
    end
  end
end

class ThisIsATestBuilder < Nokogiri::XML::Builder
  # this exists for the test_builder_uses_proper_document_class and should be empty
end

class ThisIsAnotherTestBuilder < Nokogiri::HTML4::Builder
  # this exists for the test_builder_uses_proper_document_class and should be empty
end
