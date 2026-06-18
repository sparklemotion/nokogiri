# frozen_string_literal: true

require "helper"

# Namespace axis values for the matrix. These are file-level locals (not `let`s) because the
# matrix loops below run at class-definition time, before `let` methods exist.
xi_2001 = "http://www.w3.org/2001/XInclude"
xi_2003 = "http://www.w3.org/2003/XInclude"
namespaces = { "2001" => xi_2001, "2003" => xi_2003 }

describe "xinclude processing" do
  let(:namespace) { xi_2001 }
  let(:xinclude_file) { Nokogiri::TestBase::XML_XINCLUDE_FILE }
  let(:included_file) { File.join(Nokogiri::TestBase::ASSETS_DIR, "to_be_xincluded.xml") }
  let(:included_file_uri) { file_url_for(included_file) }
  let(:included_content) { "this snippet is to be included from xinclude.xml" }
  let(:document) do
    Nokogiri::XML.parse(<<~XML)
      <root xmlns:xi="#{namespace}">
        <xi:include href="#{included_file_uri}"/>
      </root>
    XML
  end

  before do
    skip_unless_libxml2("XInclude behavior and use-after-free protection are specific to the libxml2 C extension")
  end

  def run_xinclude(target, noxincnode: false, safe_copy: true, nowarning: false)
    target.do_xinclude(safe_copy: safe_copy) do |options|
      options.noxincnode if noxincnode
      options.nowarning if nowarning
    end
  end

  it "performs XInclude substitution only when requested during parsing" do
    xml_doc = nil

    File.open(xinclude_file) do |fp|
      xml_doc = Nokogiri::XML(fp) do |conf|
        conf.strict.dtdload.noent.nocdata.xinclude
      end
    end

    refute_nil(xml_doc)
    refute_nil(included = xml_doc.at_xpath("//included"))
    assert_equal(included_content, included.content)

    xml_doc = nil

    File.open(xinclude_file) do |fp|
      xml_doc = Nokogiri::XML(fp) do |conf|
        conf.strict.dtdload.noent.nocdata
      end
    end

    refute_nil(xml_doc)
    assert_nil(xml_doc.at_xpath("//included"))
  end

  it "yields the parse options to a block" do
    non_default_options = Nokogiri::XML::ParseOptions::NOBLANKS | Nokogiri::XML::ParseOptions::XINCLUDE

    document.do_xinclude(non_default_options) do |options|
      assert_equal(non_default_options, options.to_i)
    end
  end

  it "defaults safe_copy to true, protecting wrapped nodes" do
    wrapped = document.at_xpath("//xi:include", "xi" => namespace)
    assert_equal("include", wrapped.name)

    document.do_xinclude(&:noxincnode)

    refute_valgrind_errors { wrapped.name }

    assert_equal("include", wrapped.name)
    refute_nil(document.at_xpath("//included"))
  end

  describe "a bare include" do
    namespaces.each do |label, ns|
      describe "in the #{label} namespace" do
        let(:namespace) { ns }

        [true, false].each do |noxincnode|
          [true, false].each do |safe_copy|
            it "substitutes the include#{" with NOXINCNODE" if noxincnode}#{" without safe_copy" unless safe_copy}" do
              run_xinclude(document, noxincnode: noxincnode, safe_copy: safe_copy)

              refute_nil(included = document.at_xpath("//included"))
              assert_equal(included_content, included.content)
              assert_nil(document.at_xpath("//xi:include", "xi" => namespace)) if noxincnode
            end
          end
        end
      end
    end
  end

  describe "a wrapped <xi:include> element" do
    let(:wrapped) { document.at_xpath("//xi:include", "xi" => namespace) }

    namespaces.each do |label, ns|
      describe "in the #{label} namespace" do
        let(:namespace) { ns }

        [true, false].each do |noxincnode|
          it "survives processing#{" with NOXINCNODE" if noxincnode}" do
            assert_equal("include", wrapped.name)

            run_xinclude(document, noxincnode: noxincnode)

            refute_valgrind_errors { wrapped.name }

            assert_equal("include", wrapped.name)
            refute_nil(document.at_xpath("//included"))
          end
        end
      end
    end
  end

  describe "a wrapped fallback child" do
    let(:document) do
      Nokogiri::XML.parse(<<~XML)
        <root xmlns:xi="#{namespace}">
          <xi:include href="#{included_file_uri}">
            <xi:fallback><fallback_content/></xi:fallback>
          </xi:include>
        </root>
      XML
    end
    let(:wrapped) { document.at_xpath("//xi:fallback", "xi" => namespace) }

    namespaces.each do |label, ns|
      describe "in the #{label} namespace" do
        let(:namespace) { ns }

        [true, false].each do |noxincnode|
          it "survives processing#{" with NOXINCNODE" if noxincnode}" do
            assert_equal("fallback", wrapped.name)

            run_xinclude(document, noxincnode: noxincnode)

            refute_valgrind_errors { wrapped.name }

            assert_equal("fallback", wrapped.name)
            refute_nil(document.at_xpath("//included"))
          end
        end
      end
    end
  end

  describe "a wrapped namespace in the subtree" do
    let(:document) do
      Nokogiri::XML.parse(<<~XML)
        <root xmlns:xi="#{namespace}">
          <xi:include href="#{included_file_uri}">
            <xi:fallback xmlns:foo="http://example.com/foo"/>
          </xi:include>
        </root>
      XML
    end
    let(:wrapped) { document.at_xpath("//xi:fallback", "xi" => namespace).namespace_definitions.first }

    namespaces.each do |label, ns|
      describe "in the #{label} namespace" do
        let(:namespace) { ns }

        [true, false].each do |noxincnode|
          it "survives processing#{" with NOXINCNODE" if noxincnode}" do
            assert_equal("foo", wrapped.prefix)

            run_xinclude(document, noxincnode: noxincnode)

            refute_valgrind_errors do
              wrapped.prefix
              wrapped.href
            end

            assert_equal("foo", wrapped.prefix)
            assert_equal("http://example.com/foo", wrapped.href)
          end
        end
      end
    end
  end

  describe "multiple wrapped top-level includes" do
    let(:document) do
      Nokogiri::XML.parse(<<~XML)
        <root xmlns:xi="#{namespace}">
          <xi:include href="#{included_file_uri}"/>
          <xi:include href="#{included_file_uri}"/>
        </root>
      XML
    end
    let(:wrapped) { document.xpath("//xi:include", "xi" => namespace).to_a }

    namespaces.each do |label, ns|
      describe "in the #{label} namespace" do
        let(:namespace) { ns }

        [true, false].each do |noxincnode|
          it "preserves every wrapped include#{" with NOXINCNODE" if noxincnode}" do
            assert_equal(2, wrapped.length)
            wrapped.each { |include_node| assert_equal("include", include_node.name) }

            run_xinclude(document, noxincnode: noxincnode)

            refute_valgrind_errors { wrapped.each(&:name) }

            wrapped.each { |include_node| assert_equal("include", include_node.name) }
            assert_equal(2, document.xpath("//included").length)
          end
        end
      end
    end
  end

  describe "do_xinclude called on the include node itself" do
    let(:wrapped) { document.at_xpath("//xi:include", "xi" => namespace) }

    namespaces.each do |label, ns|
      describe "in the #{label} namespace" do
        let(:namespace) { ns }

        [true, false].each do |noxincnode|
          it "survives processing#{" with NOXINCNODE" if noxincnode}" do
            refute_nil(wrapped.parent)
            assert_equal("include", wrapped.name)

            run_xinclude(wrapped, noxincnode: noxincnode)

            refute_valgrind_errors { wrapped.name }

            assert_equal("include", wrapped.name)
            refute_nil(document.at_xpath("//included"))
          end
        end
      end
    end
  end

  describe "a nested include inside a fallback" do
    # the nested include targets a nonexistent file, so processing it would raise
    let(:source) do
      <<~XML
        <root xmlns:xi="#{namespace}">
          <xi:include href="#{included_file_uri}">
            <xi:fallback>
              <xi:include href="nonexistent.xml"/>
            </xi:fallback>
          </xi:include>
        </root>
      XML
    end
    let(:document) { Nokogiri::XML.parse(source) }

    namespaces.each do |label, ns|
      describe "in the #{label} namespace" do
        let(:namespace) { ns }

        it "does not process the nested include" do
          refute_raises do
            run_xinclude(document)
          end

          refute_nil(document.at_xpath("//included"))
        end

        it "does not process the nested include when parsed with XINCLUDE (safe_copy: false)" do
          parsed = nil

          refute_raises do
            parsed = Nokogiri::XML.parse(source, &:xinclude)
          end

          refute_nil(parsed.at_xpath("//included"))
        end
      end
    end
  end

  describe "an ancestor namespace used inside a fallback" do
    let(:document) do
      Nokogiri::XML.parse(<<~XML)
        <root xmlns:xi="#{namespace}" xmlns:foo="http://example.com/foo">
          <xi:include href="nonexistent.xml">
            <xi:fallback><foo:content/></xi:fallback>
          </xi:include>
        </root>
      XML
    end

    namespaces.each do |label, ns|
      describe "in the #{label} namespace" do
        let(:namespace) { ns }

        it "reconciles the ancestor namespace in the copied subtree" do
          run_xinclude(document, nowarning: true)

          refute_nil(content = document.at_xpath("//foo:content", "foo" => "http://example.com/foo"))
          assert_equal("http://example.com/foo", content.namespace.href)
        end
      end
    end
  end

  describe "an unlinked <xi:include> node" do
    let(:orphan) { document.at_xpath("//xi:include", "xi" => namespace).tap(&:unlink) }

    [true, false].each do |safe_copy|
      it "raises because there is no parent to receive the content#{" with safe_copy false" unless safe_copy}" do
        assert_raises(RuntimeError) do
          orphan.do_xinclude(safe_copy: safe_copy)
        end
      end
    end
  end

  describe "an <xi:include> inside an unlinked subtree" do
    let(:document) do
      Nokogiri::XML.parse(<<~XML)
        <root xmlns:xi="#{namespace}">
          <container>
            <xi:include href="#{included_file_uri}"/>
          </container>
        </root>
      XML
    end
    let(:container) { document.at_xpath("//container").tap(&:unlink) }

    it "processes when called on the unlinked container" do
      container.do_xinclude

      refute_nil(container.at_xpath(".//included"))
    end

    it "processes when called on the include whose ancestor is unlinked" do
      include_node = container.at_xpath("./xi:include", "xi" => namespace)

      include_node.do_xinclude

      refute_nil(container.at_xpath(".//included"))
    end
  end
end

describe "Node#do_xinclude on any backend" do
  let(:included_file) { File.join(Nokogiri::TestBase::ASSETS_DIR, "to_be_xincluded.xml") }
  let(:included_file_uri) { file_url_for(included_file) }
  let(:document) do
    Nokogiri::XML.parse(<<~XML)
      <root xmlns:xi="http://www.w3.org/2001/XInclude">
        <xi:include href="#{included_file_uri}"/>
      </root>
    XML
  end

  it "is callable on a document and returns self" do
    assert_same(document, document.do_xinclude)
  end

  it "is callable on a node and returns self" do
    node = document.root

    assert_same(node, node.do_xinclude)
  end
end
