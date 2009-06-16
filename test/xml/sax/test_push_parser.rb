require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', "helper"))

module Nokogiri
  module XML
    module SAX
      class TestPushParser < Nokogiri::SAX::TestCase
        def setup
          super
          @parser = XML::SAX::PushParser.new(Doc.new)
        end

        def test_end_document_called
          @parser.<<(<<-eoxml)
            <p id="asdfasdf">
              <!-- This is a comment -->
              Paragraph 1
            </p>
          eoxml
          assert ! @parser.document.end_document_called
          @parser.finish
          assert @parser.document.end_document_called
        end

        def test_start_element
          @parser.<<(<<-eoxml)
            <p id="asdfasdf">
          eoxml

          assert_equal [["p", ["id", "asdfasdf"]]],
            @parser.document.start_elements

          @parser.<<(<<-eoxml)
              <!-- This is a comment -->
              Paragraph 1
            </p>
          eoxml
          assert_equal [' This is a comment '], @parser.document.comments
          @parser.finish
        end

        def test_start_element_ns
          @parser.<<(<<-eoxml)
            <stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams' version='1.0' size='large'></stream:stream>
          eoxml

          assert_equal [[ 'stream',
                          {'version' => '1.0', 'size' => 'large'},
                          'stream',
                          'http://etherx.jabber.org/streams',
                          {nil => 'jabber:client', 'stream' => 'http://etherx.jabber.org/streams'}]],
            @parser.document.start_elements_ns
          @parser.finish
        end

        def test_end_element_ns
          @parser.<<(<<-eoxml)
            <stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams' version='1.0'></stream:stream>
          eoxml

          assert_equal [['stream', 'stream', 'http://etherx.jabber.org/streams']],
            @parser.document.end_elements_ns
          @parser.finish
        end

        def test_chevron_partial_xml
          @parser.<<(<<-eoxml)
            <p id="asdfasdf">
          eoxml

          @parser.<<(<<-eoxml)
              <!-- This is a comment -->
              Paragraph 1
            </p>
          eoxml
          assert_equal [' This is a comment '], @parser.document.comments
          @parser.finish
        end

        def test_chevron
          @parser.<<(<<-eoxml)
            <p id="asdfasdf">
              <!-- This is a comment -->
              Paragraph 1
            </p>
          eoxml
          @parser.finish
          assert_equal [' This is a comment '], @parser.document.comments
        end
      end
    end
  end
end
