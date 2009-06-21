Process.setrlimit(Process::RLIMIT_CORE, Process::RLIM_INFINITY) unless RUBY_PLATFORM =~ /(java|mswin|mingw)/i
$VERBOSE = true
require 'rubygems'
require 'test/unit'

%w(../lib ../ext).each do |path|
  $LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), path)))
end

require 'nokogiri'

warn "#{__FILE__}:#{__LINE__}: libxml version info: #{Nokogiri::VERSION_INFO.inspect}"

module Nokogiri
  class TestCase < Test::Unit::TestCase
    ASSETS_DIR      = File.join(File.dirname(__FILE__), 'files')
    XML_FILE        = File.join(ASSETS_DIR, 'staff.xml')
    XSLT_FILE       = File.join(ASSETS_DIR, 'staff.xslt')
    EXSLT_FILE      = File.join(ASSETS_DIR, 'exslt.xslt')
    EXML_FILE       = File.join(ASSETS_DIR, 'exslt.xml')
    HTML_FILE       = File.join(ASSETS_DIR, 'tlm.html')
    PO_XML_FILE     = File.join(ASSETS_DIR, 'po.xml')
    PO_SCHEMA_FILE  = File.join(ASSETS_DIR, 'po.xsd')
    ADDRESS_SCHEMA_FILE = File.join(ASSETS_DIR, 'address_book.rlx')
    ADDRESS_XML_FILE = File.join(ASSETS_DIR, 'address_book.xml')
    SNUGGLES_FILE   = File.join(ASSETS_DIR, 'snuggles.xml')

    unless RUBY_VERSION >= '1.9'
      undef :default_test
    end

    def setup
      warn "#{name}" if ENV['TESTOPTS'] == '-v'
    end

    def teardown
      if ENV['NOKOGIRI_GC']
        STDOUT.putc '!'
        GC.start 
      end
    end

    def assert_indent amount, doc, message = nil
      nodes = []
      doc.traverse do |node|
        nodes << node if node.text? && node.blank?
      end
      assert nodes.length > 0
      nodes.each do |node|
        len = node.content.gsub(/[\r\n]/, '').length
        assert_equal(0, len % amount, message)
      end
    end
  end

  module SAX
    class TestCase < Nokogiri::TestCase
      class Doc < XML::SAX::Document
        attr_reader :start_elements, :start_document_called
        attr_reader :end_elements, :end_document_called
        attr_reader :data, :comments, :cdata_blocks, :start_elements_namespace
        attr_reader :errors, :warnings, :end_elements_namespace

        def start_document
          @start_document_called = true
          super
        end

        def end_document
          @end_document_called = true
          super
        end

        def error error
          (@errors ||= []) << error
          super
        end

        def warning warning
          (@warning ||= []) << warning
          super
        end

        def start_element *args
          (@start_elements ||= []) << args
          super
        end

        def start_element_namespace *args
          (@start_elements_namespace ||= []) << args
          super
        end

        def end_element *args
          (@end_elements ||= []) << args
          super
        end

        def end_element_namespace *args
          (@end_elements_namespace ||= []) << args
          super
        end

        def characters string
          @data ||= []
          @data += [string]
          super
        end

        def comment string
          @comments ||= []
          @comments += [string]
          super
        end

        def cdata_block string
          @cdata_blocks ||= []
          @cdata_blocks += [string]
          super
        end
      end
    end
  end
end
