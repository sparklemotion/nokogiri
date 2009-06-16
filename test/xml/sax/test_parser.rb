require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', "helper"))

module Nokogiri
  module XML
    module SAX
      class TestParser < Nokogiri::SAX::TestCase
        def setup
          super
          @parser = XML::SAX::Parser.new(Doc.new)
        end

        def test_bad_document_calls_error_handler
          @parser.parse('<foo><bar></foo>')
          assert @parser.document.errors
          assert @parser.document.errors.length > 0
        end

        def test_parser_sets_encoding
          parser = XML::SAX::Parser.new(Doc.new, 'UTF-8')
          assert_equal 'UTF-8', parser.encoding
        end

        def test_errors_set_after_parsing_bad_dom
          doc = Nokogiri::XML('<foo><bar></foo>')
          assert doc.errors

          @parser.parse('<foo><bar></foo>')
          assert @parser.document.errors
          assert @parser.document.errors.length > 0

          if RUBY_VERSION =~ /^1\.9/
            doc.errors.each do |error|
              assert_equal 'UTF-8', error.message.encoding.name
            end
          end

          assert_equal doc.errors.length, @parser.document.errors.length
        end

        def test_parse
          File.open(XML_FILE, 'rb') { |f|
            @parser.parse(f)
          }
          @parser.parse(File.read(XML_FILE))
          assert(@parser.document.cdata_blocks.length > 0)
        end

        def test_parse_io
          File.open(XML_FILE, 'rb') { |f|
            @parser.parse_io(f, 'UTF-8')
          }
          assert(@parser.document.cdata_blocks.length > 0)
          if RUBY_VERSION =~ /^1\.9/
            called = false
            @parser.document.start_elements.flatten.each do |thing|
              assert_equal 'UTF-8', thing.encoding.name
              called = true
            end
            assert called

            called = false
            @parser.document.end_elements.flatten.each do |thing|
              assert_equal 'UTF-8', thing.encoding.name
              called = true
            end
            assert called

            called = false
            @parser.document.data.each do |thing|
              assert_equal 'UTF-8', thing.encoding.name
              called = true
            end
            assert called

            called = false
            @parser.document.comments.flatten.each do |thing|
              assert_equal 'UTF-8', thing.encoding.name
              called = true
            end
            assert called

            called = false
            @parser.document.cdata_blocks.flatten.each do |thing|
              assert_equal 'UTF-8', thing.encoding.name
              called = true
            end
            assert called
          end
        end

        def test_parse_file
          @parser.parse_file(XML_FILE)

          assert_raises(ArgumentError) {
            @parser.parse_file(nil)
          }

          assert_raises(Errno::ENOENT) {
            @parser.parse_file('')
          }
          assert_raises(Errno::EISDIR) {
            @parser.parse_file(File.expand_path(File.dirname(__FILE__)))
          }
        end

        def test_render_parse_nil_param
          assert_raises(ArgumentError) { @parser.parse_memory(nil) }
        end

        def test_ctag
          @parser.parse_memory(<<-eoxml)
            <p id="asdfasdf">
              <![CDATA[ This is a comment ]]>
              Paragraph 1
            </p>
          eoxml
          assert_equal [' This is a comment '], @parser.document.cdata_blocks
        end

        def test_comment
          @parser.parse_memory(<<-eoxml)
            <p id="asdfasdf">
              <!-- This is a comment -->
              Paragraph 1
            </p>
          eoxml
          assert_equal [' This is a comment '], @parser.document.comments
        end

        def test_characters
          @parser.parse_memory(<<-eoxml)
            <p id="asdfasdf">Paragraph 1</p>
          eoxml
          assert_equal ['Paragraph 1'], @parser.document.data
        end

        def test_end_document
          @parser.parse_memory(<<-eoxml)
            <p id="asdfasdf">Paragraph 1</p>
          eoxml
          assert @parser.document.end_document_called
        end

        def test_end_element
          @parser.parse_memory(<<-eoxml)
            <p id="asdfasdf">Paragraph 1</p>
          eoxml
          assert_equal [["p"]],
            @parser.document.end_elements
        end

        def test_start_element_attrs
          @parser.parse_memory(<<-eoxml)
            <p id="asdfasdf">Paragraph 1</p>
          eoxml
          assert_equal [["p", ["id", "asdfasdf"]]],
                       @parser.document.start_elements
        end

        def test_parse_document
          @parser.parse_memory(<<-eoxml)
            <p>Paragraph 1</p>
            <p>Paragraph 2</p>
          eoxml
        end
      end
    end
  end
end
