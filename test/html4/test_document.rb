# frozen_string_literal: true

require "helper"

module Nokogiri
  module HTML4
    class TestDocument < Nokogiri::TestCase
      describe Nokogiri::HTML4::Document do
        let(:html) { Nokogiri::HTML4.parse(File.read(HTML_FILE)) }

        def test_nil_css
          # Behavior is undefined but shouldn't break
          assert(html.css(nil))
          assert(html.xpath(nil))
        end

        def test_does_not_fail_with_illformatted_html
          doc = Nokogiri::HTML4((+'"</html>";').force_encoding(Encoding::BINARY))
          refute_nil(doc)
        end

        def test_exceptions_remove_newlines
          errors = html.errors
          refute_empty(errors, "has errors")
          errors.each do |error|
            assert_equal(error.to_s.chomp, error.to_s)
          end
        end

        def test_fragment
          fragment = html.fragment
          assert_equal(0, fragment.children.length)
        end

        def test_document_takes_config_block
          options = nil
          Nokogiri::HTML4(File.read(HTML_FILE), HTML_FILE) do |cfg|
            options = cfg
            options.nonet.nowarning.dtdattr
          end
          assert_predicate(options, :nonet?)
          assert_predicate(options, :nowarning?)
          assert_predicate(options, :dtdattr?)
        end

        def test_parse_takes_config_block
          options = nil
          Nokogiri::HTML4.parse(File.read(HTML_FILE), HTML_FILE) do |cfg|
            options = cfg
            options.nonet.nowarning.dtdattr
          end
          assert_predicate(options, :nonet?)
          assert_predicate(options, :nowarning?)
          assert_predicate(options, :dtdattr?)
        end

        def test_document_parse_method
          html = Nokogiri::HTML4::Document.parse(File.read(HTML_FILE))
          assert_equal(html.to_s, html.to_s)
        end

        def test_document_parse_method_with_url
          doc = Nokogiri::HTML4("<html></html>", "http://foobar.example.com/", "UTF-8")
          refute_empty(doc.to_s, "Document should not be empty")
          assert_equal("http://foobar.example.com/", doc.url)
        end

        def test_document_parse_method_with_url_kwarg
          doc = Nokogiri::HTML4("<html></html>", url: "http://foobar.example.com/", encoding: "UTF-8")
          refute_empty(doc.to_s, "Document should not be empty")
          assert_equal("http://foobar.example.com/", doc.url)
        end

        ###
        # Nokogiri::HTML4 returns an empty Document when given a blank string GH#11
        def test_empty_string_returns_empty_doc
          doc = Nokogiri::HTML4("")
          assert_instance_of(Nokogiri::HTML4::Document, doc)
          assert_nil(doc.root)
        end

        def test_to_xhtml_with_indent
          doc = Nokogiri::HTML4("<html><body><a>foo</a></body></html>")
          doc = Nokogiri::HTML4(doc.to_xhtml(indent: 2))
          assert_indent(2, doc)
        end

        def test_write_to_xhtml_with_indent
          io = StringIO.new
          doc = Nokogiri::HTML4("<html><body><a>foo</a></body></html>")
          doc.write_xhtml_to(io, indent: 5)
          io.rewind
          doc = Nokogiri::HTML4(io.read)
          assert_indent(5, doc)
        end

        def test_swap_should_not_exist
          assert_raises(NoMethodError) do
            html.swap
          end
        end

        def test_namespace_should_not_exist
          assert_raises(NoMethodError) do
            html.namespace
          end
        end

        def test_meta_encoding
          assert_equal("UTF-8", html.meta_encoding)
        end

        def test_meta_encoding_is_strict_about_http_equiv
          doc = Nokogiri::HTML4(<<~HTML)
            <html>
              <head>
                <meta http-equiv="X-Content-Type" content="text/html; charset=Shift_JIS">
              </head>
              <body>
                foo
              </body>
            </html>
          HTML
          assert_nil(doc.meta_encoding)
        end

        def test_meta_encoding_handles_malformed_content_charset
          doc = Nokogiri::HTML4(<<~HTML)
            <html>
              <head>
                <meta http-equiv="Content-type" content="text/html; utf-8" />
              </head>
              <body>
                foo
              </body>
            </html>
          HTML
          assert_nil(doc.meta_encoding)
        end

        def test_meta_encoding_checks_charset
          doc = Nokogiri::HTML4(<<~HTML)
            <html>
              <head>
                <meta charset="UTF-8">
              </head>
              <body>
                foo
              </body>
            </html>
          HTML
          assert_equal("UTF-8", doc.meta_encoding)
        end

        def test_meta_encoding=
          html.meta_encoding = "EUC-JP"
          assert_equal("EUC-JP", html.meta_encoding)
        end

        def test_title
          assert_equal("Tender Lovemaking  ", html.title)
          doc = Nokogiri::HTML4("<html><body>foo</body></html>")
          assert_nil(doc.title)
        end

        def test_title=
          doc = Nokogiri::HTML4(<<~HTML)
            <html>
              <head>
                <title>old</title>
              </head>
              <body>
                foo
              </body>
            </html>
          HTML
          doc.title = "new"
          assert_equal(1, doc.css("title").size)
          assert_equal("new", doc.title)

          doc = Nokogiri::HTML4(<<~HTML)
            <html>
              <head>
                <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
              </head>
              <body>
                foo
              </body>
            </html>
          HTML
          doc.title = "new"
          assert_equal("new", doc.title)
          title = doc.at("/html/head/title")
          refute_nil(title)
          assert_equal("new", title.text)
          assert_equal(-1, doc.at("meta[@http-equiv]") <=> title)

          doc = Nokogiri::HTML4(<<~HTML)
            <html>
              <body>
                foo
              </body>
            </html>
          HTML
          doc.title = "new"
          assert_equal("new", doc.title)
          # <head> may or may not be added
          title = doc.at("/html//title")
          refute_nil(title)
          assert_equal("new", title.text)
          assert_equal(-1, title <=> doc.at("body"))

          doc = Nokogiri::HTML4(<<~HTML)
            <html>
              <meta charset="UTF-8">
              <body>
                foo
              </body>
            </html>
          HTML
          doc.title = "new"
          assert_equal("new", doc.title)
          assert_equal(-1, doc.at("meta[@charset]") <=> doc.at("title"))
          assert_equal(-1, doc.at("title") <=> doc.at("body"))

          doc = Nokogiri::HTML4("<!DOCTYPE html><p>hello")
          doc.title = "new"
          assert_equal("new", doc.title)
          assert_instance_of(Nokogiri::XML::DTD, doc.children.first)
          assert_equal(-1, doc.at("title") <=> doc.at("p"))

          doc = Nokogiri::HTML4("")
          doc.title = "new"
          assert_equal("new", doc.title)
          assert_equal("new", doc.at("/html/head/title/text()").to_s)
        end

        def test_meta_encoding_without_head
          encoding = "EUC-JP"
          html = Nokogiri::HTML4("<html><body>foo</body></html>", encoding: encoding)

          assert_nil(html.meta_encoding)

          html.meta_encoding = encoding
          assert_equal(encoding, html.meta_encoding)

          meta = html.at("/html/head/meta[@http-equiv and boolean(@content)]")
          assert(meta, "meta is in head")

          assert(meta.at("./parent::head/following-sibling::body"), "meta is before body")
        end

        def test_html5_meta_encoding_without_head
          encoding = "EUC-JP"
          html = Nokogiri::HTML4("<!DOCTYPE html><html><body>foo</body></html>", encoding: encoding)

          assert_nil(html.meta_encoding)

          html.meta_encoding = encoding
          assert_equal(encoding, html.meta_encoding)

          meta = html.at("/html/head/meta[@charset]")
          assert(meta, "meta is in head")

          assert(meta.at("./parent::head/following-sibling::body"), "meta is before body")
        end

        def test_meta_encoding_with_empty_content_type
          html = Nokogiri::HTML4(<<~HTML)
            <html>
              <head>
                <meta http-equiv="Content-Type" content="">
              </head>
              <body>
                foo
              </body>
            </html>
          HTML
          assert_nil(html.meta_encoding)

          html = Nokogiri::HTML4(<<~HTML)
            <html>
              <head>
                <meta http-equiv="Content-Type">
              </head>
              <body>
                foo
              </body>
            </html>
          HTML
          assert_nil(html.meta_encoding)
        end

        def test_root_node_parent_is_document
          parent = html.root.parent
          assert_equal(html, parent)
          assert_instance_of(Nokogiri::HTML4::Document, parent)
        end

        def test_parse_handles_nil_gracefully
          @doc = Nokogiri::HTML4::Document.parse(nil)
          assert_instance_of(Nokogiri::HTML4::Document, @doc)
        end

        def test_parse_empty_document
          doc = Nokogiri::HTML4("\n")
          assert_equal(0, doc.css("a").length)
          assert_equal(0, doc.xpath("//a").length)
          assert_equal(0, doc.search("//a").length)
        end

        def test_html_predicate
          html = Nokogiri::HTML4(File.read(HTML_FILE))
          assert_predicate(html, :html?)
        end

        def test_parse_works_with_an_object_that_responds_to_read
          klass = Class.new do
            def initialize
              super
              @contents = StringIO.new("<div>foo</div>")
            end

            def read(*args)
              @contents.read(*args)
            end
          end

          doc = Nokogiri::HTML4.parse(klass.new)
          assert_equal("foo", doc.at_css("div").content)
        end

        def test_parse_temp_file
          temp_html_file = Tempfile.new("TEMP_HTML_FILE")
          File.open(HTML_FILE, "rb") { |f| temp_html_file.write(f.read) }
          temp_html_file.close
          temp_html_file.open
          assert_equal(
            Nokogiri::HTML4.parse(File.read(HTML_FILE)).xpath("//div/a").length,
            Nokogiri::HTML4.parse(temp_html_file).xpath("//div/a").length,
          )
        end

        def test_to_xhtml
          assert_match("XHTML", html.to_xhtml)
          assert_match("XHTML", html.to_xhtml(encoding: "UTF-8"))
          assert_match("UTF-8", html.to_xhtml(encoding: "UTF-8"))
        end

        def test_to_xhtml_self_closing_tags
          # https://github.com/sparklemotion/nokogiri/issues/2324
          html = "<html><body><br><table><colgroup><col>"
          doc = Nokogiri::HTML4::Document.parse(html)
          xhtml = doc.to_xhtml
          assert_match(%r(<br ?/>), xhtml)
          assert_match(%r(<col ?/>), xhtml)
        end

        def test_no_xml_header
          html = Nokogiri::HTML4(<<~HTML)
            <html>
            </html>
          HTML
          refute_empty(html.to_html, "html length is too short")
          refute_match(/^<\?xml/, html.to_html)
        end

        def test_document_has_error
          html = Nokogiri::HTML4(<<~HTML)
            <html>
              <body>
                <div>
                </foo>
              </body>
            </html>
          HTML
          refute_empty(html.errors)
        end

        def test_relative_css
          html = Nokogiri::HTML4(<<~HTML)
            <html>
              <body>
                <div>
                  <p>inside div tag</p>
                </div>
                <p>outside div tag</p>
              </body>
            </html>
          HTML
          set = html.search("div").search("p")
          assert_equal(1, set.length)
          assert_equal("inside div tag", set.first.inner_text)
        end

        def test_multi_css
          html = Nokogiri::HTML4(<<~HTML)
            <html>
              <body>
                <div>
                  <p>p tag</p>
                  <a>a tag</a>
                </div>
              </body>
            </html>
          HTML
          set = html.css("p, a")
          assert_equal(2, set.length)
          assert_equal(["a tag", "p tag"].sort, set.map(&:content).sort)
        end

        def test_inner_text
          html = Nokogiri::HTML4(<<~HTML)
            <html>
              <body>
                <div>
                  <p>
                    Hello world!
                  </p>
                </div>
              </body>
            </html>
          HTML
          node = html.xpath("//div").first
          assert_equal("Hello world!", node.inner_text.strip)
        end

        def test_doc_type
          html = Nokogiri::HTML4(<<~HTML)
            <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
            <html xmlns="http://www.w3.org/1999/xhtml">
              <body>
                <p>Rainbow Dash</p>
              </body>
            </html>
          HTML
          assert_equal("html", html.internal_subset.name)
          assert_equal("-//W3C//DTD XHTML 1.1//EN", html.internal_subset.external_id)
          assert_equal("http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd", html.internal_subset.system_id)
          assert_equal(
            "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">",
            html.to_s[0, 97],
          )
        end

        def test_content_size
          html = Nokogiri::HTML4("<div>\n</div>")
          assert_equal(1, html.content.size)
          assert_equal(1, html.content.split("").size)
          assert_equal("\n", html.content)
        end

        def test_find_by_xpath
          found = html.xpath("//div/a")
          assert_equal(3, found.length)
        end

        def test_find_by_css
          found = html.css("div > a")
          assert_equal(3, found.length)
        end

        def test_find_by_css_with_square_brackets
          found = html.css("div[@id='header'] > h1")
          refute_nil(found)
          assert_equal(1, found.length)

          # this blows up on commit 6fa0f6d329d9dbf1cc21c0ac72f7e627bb4c05fc
          found = html.css("div[@id='header'] h1")
          refute_nil(found)
          assert_equal(1, found.length)
        end

        def test_find_by_css_with_escaped_characters
          found_without_escape = html.css("div[@id='abc.123']")
          found_by_id = html.css("#abc\\.123")
          found_by_class = html.css(".special\\.character")
          assert_equal(1, found_without_escape.length)
          assert_equal(found_by_id, found_without_escape)
          assert_equal(found_by_class, found_without_escape)
        end

        def test_find_with_function
          assert(html.css("div:awesome() h1", Class.new do
                                                def awesome(divs)
                                                  [divs.first]
                                                end
                                              end.new))
        end

        def test_dup_shallow
          found = html.search("//div/a").first
          dup = found.dup(0)
          assert(dup)
          assert_equal("", dup.content)
        end

        def test_search_can_handle_xpath_and_css
          found = html.search("//div/a", "div > p")
          length = html.xpath("//div/a").length +
            html.css("div > p").length
          assert_equal(length, found.length)
        end

        def test_dup_document
          assert(dup = html.dup)
          refute_equal(dup, html)
          assert_predicate(html, :html?)
          assert_instance_of(Nokogiri::HTML4::Document, dup)
          assert_predicate(dup, :html?, "duplicate should be html")
          assert_equal(html.to_s, dup.to_s)
        end

        def test_dup_document_shallow
          assert(dup = html.dup(0))
          refute_equal(dup, html)
        end

        def test_dup
          found = html.search("//div/a").first
          dup = found.dup
          assert(dup)
          assert_equal(found.content, dup.content)
          assert_equal(found.document, dup.document)
        end

        # issue 1060
        def test_node_ownership_after_dup
          html = "<html><head></head><body><div>replace me</div></body></html>"
          doc = Nokogiri::HTML4::Document.parse(html)
          dup = doc.dup
          assert_same(dup, dup.at_css("div").document)

          # should not raise an exception
          dup.at_css("div").parse("<div>replaced</div>")
        end

        def test_inner_html
          html = Nokogiri::HTML4(<<~HTML)
            <html>
              <body>
                <div>
                  <p>
                    Hello world!
                  </p>
                </div>
              </body>
            </html>
          HTML
          node = html.xpath("//div").first
          assert_equal("<p>Helloworld!</p>", node.inner_html.gsub(/\s/, ""))
        end

        def test_round_trip
          doc = Nokogiri::HTML4(html.inner_html)
          assert_equal(html.root.to_html, doc.root.to_html)
        end

        def test_fragment_contains_text_node
          fragment = Nokogiri::HTML4.fragment("fooo")
          assert_equal(1, fragment.children.length)
          assert_equal("fooo", fragment.inner_text)
        end

        def test_fragment_includes_two_tags
          assert_equal(2, Nokogiri::HTML4.fragment("<br/><hr/>").children.length)
        end

        def test_relative_css_finder
          doc = Nokogiri::HTML4(<<~HTML)
            <html>
              <body>
                <div class="red">
                  <p>
                    inside red
                  </p>
                </div>
                <div class="green">
                  <p>
                    inside green
                  </p>
                </div>
              </body>
            </html>
          HTML
          red_divs = doc.css("div.red")
          assert_equal(1, red_divs.length)
          p_tags = red_divs.first.css("p")
          assert_equal(1, p_tags.length)
          assert_equal("inside red", p_tags.first.text.strip)
        end

        def test_find_classes
          doc = Nokogiri::HTML4(<<~HTML)
            <html>
              <body>
                <p class="red">RED</p>
                <p class="awesome red">RED</p>
                <p class="notred">GREEN</p>
                <p class="green notred">GREEN</p>
              </body>
            </html>
          HTML
          list = doc.css(".red")
          assert_equal(2, list.length)
          assert_equal(["RED", "RED"], list.map(&:text))
        end

        def test_parse_can_take_io
          html = nil
          File.open(HTML_FILE, "rb") do |f|
            html = Nokogiri::HTML4(f)
          end
          assert_predicate(html, :html?)
          assert_equal(HTML_FILE, html.url)
        end

        def test_parse_works_with_an_object_that_responds_to_path
          html = +"<html><body>hello</body></html>"
          def html.path
            "/i/should/be/the/document/url"
          end

          doc = Nokogiri::HTML4.parse(html)

          assert_equal("/i/should/be/the/document/url", doc.url)
        end

        # issue #1821, #2110
        def test_parse_can_take_pathnames
          assert_operator(File.size(HTML_FILE), :>, 4096) # file must be big enough to trip the read callback more than once

          doc = Nokogiri::HTML4.parse(Pathname.new(HTML_FILE))

          # an arbitrary assertion on the structure of the document
          assert_equal(166, doc.css("a").length)
          assert_equal(HTML_FILE, doc.url)
        end

        def test_html?
          refute_predicate(html, :xml?)
          assert_predicate(html, :html?)
        end

        def test_serialize
          assert(html.serialize)
          assert(html.to_html)
        end

        def test_empty_document
          # empty document should return "" #699
          assert_equal("", Nokogiri::HTML4.parse(nil).text)
          assert_equal("", Nokogiri::HTML4.parse("").text)
        end

        def test_capturing_nonparse_errors_during_document_clone
          # see https://github.com/sparklemotion/nokogiri/issues/1196 for background
          original = Nokogiri::HTML4.parse("<div id='unique'></div><div id='unique'></div>")
          original_errors = original.errors.dup

          copy = original.dup
          assert_equal(original_errors, copy.errors)
        end

        def test_capturing_nonparse_errors_during_node_copy_between_docs
          # Errors should be emitted while parsing only, and should not change when moving nodes.
          doc1 = Nokogiri::HTML4("<html><body><div id='unique'>one</foo1></body></html>")
          doc2 = Nokogiri::HTML4("<html><body><div id='unique'>two</foo2></body></html>")
          node1 = doc1.at_css("#unique")
          node2 = doc2.at_css("#unique")
          original_errors1 = doc1.errors.dup
          original_errors2 = doc2.errors.dup

          refute_empty(original_errors1)
          refute_empty(original_errors2)

          node1.add_child(node2)

          assert_equal(original_errors1, doc1.errors)
          assert_equal(original_errors2, doc2.errors)
        end

        def test_silencing_nonparse_errors_during_attribute_insertion_1262
          # see https://github.com/sparklemotion/nokogiri/issues/1262
          #
          # libxml2 emits a warning when this happens; the JRuby
          # implementation does not. so rather than capture the error in
          # doc.errors in a platform-dependent way, I'm opting to have
          # the error silenced.
          #
          # So this test doesn't look meaningful, but we want to avoid
          # having `ID unique-issue-1262 already defined` emitted to
          # stderr when running the test suite.
          #
          doc = Nokogiri::HTML4::Document.new
          Nokogiri::XML::Element.new("div", doc).set_attribute("id", "unique-issue-1262")
          Nokogiri::XML::Element.new("div", doc).set_attribute("id", "unique-issue-1262")
          assert_equal(0, doc.errors.length)
        end

        it "skips encoding for script tags" do
          html = Nokogiri::HTML4(<<~HTML)
            <html>
              <head>
                <script>var isGreater = 4 > 5;</script>
              </head>
              <body></body>
            </html>
          HTML
          node = html.xpath("//script").first
          assert_equal("var isGreater = 4 > 5;", node.inner_html)
        end

        it "skips encoding for style tags" do
          html = Nokogiri::HTML4(<<~HTML)
            <html>
              <head>
                <style>tr > div { display:block; }</style>
              </head>
              <body></body>
            </html>
          HTML
          node = html.xpath("//style").first
          assert_equal("tr > div { display:block; }", node.inner_html)
        end

        it "does not fail when converting to_html using explicit encoding" do
          html_fragment = <<~HTML
            <img width="16" height="16" src="images/icon.gif" border="0" alt="Inactive hide details for &quot;User&quot; ---19/05/2015 12:55:29---Provvediamo subito nell&#8217;integrare">
          HTML
          doc = Nokogiri::HTML4(html_fragment, encoding: "ISO-8859-1")
          html = doc.to_html
          assert html.index("src=\"images/icon.gif\"")
          assert_equal "ISO-8859-1", html.encoding.name
        end

        it "handles ill-formed processing instructions" do
          html = %{<html><body><!--><?a/}
          doc = Nokogiri::HTML4::Document.parse(html)
          expected = if Nokogiri.jruby?
            [Nokogiri::XML::Node::COMMENT_NODE, Nokogiri::XML::Node::PI_NODE]
          elsif Nokogiri.uses_libxml?(">= 2.14.0")
            [Nokogiri::XML::Node::COMMENT_NODE, Nokogiri::XML::Node::COMMENT_NODE]
          elsif Nokogiri.uses_libxml?(">= 2.10.0")
            [Nokogiri::XML::Node::COMMENT_NODE]
          else
            []
          end
          assert_equal(expected, doc.at_css("body").children.map(&:type))
        end

        it "emits HTML even when no save options are specified" do
          doc = Nokogiri::HTML4::Document.parse("<html><body><div>hello</div></body></html>")
          expected = doc.to_html

          assert_equal(
            expected,
            doc.write_to(StringIO.new, save_with: Nokogiri::XML::Node::SaveOptions::DEFAULT_HTML).tap(&:rewind).read,
          )
          assert_equal(
            expected,
            doc.write_to(StringIO.new).tap(&:rewind).read,
          )

          # but not when the AS_XML or AS_XHTML flag is set
          as_xml = doc.write_to(StringIO.new, save_with: Nokogiri::XML::Node::SaveOptions::AS_XML).tap(&:rewind).read
          refute_equal(expected, as_xml)
          assert(as_xml.start_with?("<?xml"))

          as_xhtml = doc.write_to(StringIO.new, save_with: Nokogiri::XML::Node::SaveOptions::AS_XHTML).tap(&:rewind).read
          refute_equal(expected, as_xhtml)
          assert(as_xhtml.start_with?("<?xml"))
        end

        describe ".parse" do
          let(:html_strict) do
            Nokogiri::XML::ParseOptions.new(Nokogiri::XML::ParseOptions::DEFAULT_HTML).norecover
          end

          it "sets the test up correctly" do
            assert_predicate(html_strict, :strict?)
          end

          describe "ill-formed < character" do
            let(:input) { %{<html><body><div>this < that</div><div>second element</div></body></html>} }

            it "skips to the next start tag" do
              # see https://github.com/sparklemotion/nokogiri/issues/2461 for why we're testing this edge case
              doc = Nokogiri::HTML4.parse(input)
              body = doc.at_xpath("//body")

              if Nokogiri.uses_libxml?("= 2.9.13")
                # <body><div>this <div>second element</div></div></body>
                assert_equal(1, body.children.length)
                body.children.first.tap do |div|
                  assert_equal(2, div.children.length)
                  assert_equal("this ", div.children[0].content)
                  assert_equal("div", div.children[1].name)
                  assert_equal("second element", div.children[1].content)
                end
              else
                # <body><div>this &lt; that</div><div>second element</div></body>
                assert_equal(2, body.children.length)
                assert_equal(["div", "div"], body.children.map(&:name), body.to_html)
                assert_equal("this < that", body.children[0].text, body.to_html)
                assert_equal("second element", body.children[1].text, body.to_html)
              end
            end
          end

          describe "read memory" do
            let(:input) { "<html><body><div></foo>" }

            describe "strict parsing" do
              let(:parse_options) { html_strict }

              it "raises exception on parse error" do
                exception = assert_raises(Nokogiri::SyntaxError) do
                  Nokogiri::HTML4.parse(input, nil, nil, parse_options)
                end
                assert_match(/Parser without recover option encountered error or warning/, exception.to_s)
                assert_nil(exception.path)
              end

              it "raises exception on parse error using kwarg" do
                exception = assert_raises(Nokogiri::SyntaxError) do
                  Nokogiri::HTML4.parse(input, options: parse_options)
                end
                assert_match(/Parser without recover option encountered error or warning/, exception.to_s)
                assert_nil(exception.path)
              end
            end

            describe "default options" do
              it "does not raise exception on parse error" do
                doc = Nokogiri::HTML4.parse(input)
                assert_operator(doc.errors.length, :>, 0)
              end
            end
          end

          describe "read io" do
            let(:input) { StringIO.new("<html><body><div></foo>") }

            describe "strict parsing" do
              let(:parse_options) { html_strict }

              it "raises exception on parse error" do
                exception = assert_raises(Nokogiri::SyntaxError) do
                  Nokogiri::HTML4.parse(input, nil, "UTF-8", parse_options)
                end
                assert_match(/Parser without recover option encountered error or warning/, exception.to_s)
                assert_nil(exception.path)
              end

              it "raises exception on parse error using kwargs" do
                exception = assert_raises(Nokogiri::SyntaxError) do
                  Nokogiri::HTML4.parse(input, encoding: "UTF-8", options: parse_options)
                end
                assert_match(/Parser without recover option encountered error or warning/, exception.to_s)
                assert_nil(exception.path)
              end
            end

            describe "default options" do
              it "does not raise exception on parse error" do
                doc = Nokogiri::HTML4.parse(input, nil, "UTF-8")
                assert_operator(doc.errors.length, :>, 0)
              end

              it "does not raise exception on parse error using kwarg" do
                doc = Nokogiri::HTML4.parse(input, encoding: "UTF-8")
                assert_operator(doc.errors.length, :>, 0)
              end
            end
          end
        end

        describe "subclassing" do
          let(:klass) do
            Class.new(Nokogiri::HTML4::Document) do
              attr_accessor :initialized_with, :initialized_count

              def initialize(*args)
                super
                @initialized_with = args
                @initialized_count ||= 0
                @initialized_count += 1
              end
            end
          end

          describe ".new" do
            it "returns an instance of the expected class" do
              doc = klass.new
              assert_instance_of(klass, doc)
            end

            it "calls #initialize exactly once" do
              doc = klass.new
              assert_equal(1, doc.initialized_count)
            end

            it "passes arguments to #initialize" do
              doc = klass.new("http://www.w3.org/TR/REC-html40/loose.dtd", "-//W3C//DTD HTML 4.0 Transitional//EN")
              assert_equal(
                ["http://www.w3.org/TR/REC-html40/loose.dtd", "-//W3C//DTD HTML 4.0 Transitional//EN"],
                doc.initialized_with,
              )
            end
          end

          it "#dup returns the expected class" do
            doc = klass.new.dup
            assert_instance_of(klass, doc)
          end

          describe ".parse" do
            it "returns an instance of the expected class" do
              doc = klass.parse(File.read(HTML_FILE))
              assert_instance_of(klass, doc)
            end

            it "calls #initialize exactly once" do
              doc = klass.parse(File.read(HTML_FILE))
              assert_equal(1, doc.initialized_count)
            end

            it "parses the doc" do
              doc = klass.parse(File.read(HTML_FILE))
              assert_equal(html.root.to_s, doc.root.to_s)
            end
          end
        end
      end
    end
  end
end
