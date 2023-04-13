# frozen_string_literal: true

#
# Some environment variables that are used to configure the test suite:
# - NOKOGIRI_TEST_FAIL_FAST: if set to anything, emit test failure messages immediately upon failure
# - NOKOGIRI_TEST_GC_LEVEL: (roughly in order of stress)
#   - "normal" - normal GC functionality (default)
#   - "minor" - force a minor GC cycle after each test
#   - "major" - force a major GC cycle after each test
#   - "compact" - force a major GC after each test and GC compaction after every 20 tests
#   - "verify" - force a major GC after each test and verify references-after-compaction after every 20 tests
#   - "stress" - run tests with GC.stress set to true
# - NOKOGIRI_GC: read more in test/test_memory_leak.rb
#

require "simplecov"
SimpleCov.start do
  add_filter "/test/"
  enable_coverage :branch
end

$VERBOSE = true

require "minitest/autorun"
require "minitest/benchmark"
require "minitest/reporters"

nokogiri_minitest_reporters_options = { color: true, slow_count: 10, detailed_skip: false }
nokogiri_minitest_reporters_options[:fast_fail] = true if ENV["NOKOGIRI_TEST_FAIL_FAST"]
puts "Minitest::Reporters options: #{nokogiri_minitest_reporters_options}"
Minitest::Reporters.use!(Minitest::Reporters::DefaultReporter.new(nokogiri_minitest_reporters_options))

require "fileutils"
require "tempfile"
require "pp"
require "yaml"

require "nokogiri"

if ENV["TEST_NOKOGIRI_WITH_LIBXML_RUBY"]
  #
  #  if you'd like to test with the libxml-ruby gem loaded, it's
  #  recommended that you set
  #
  #    BUNDLE_GEMFILE=Gemfile-libxml-ruby
  #
  #  which will a) bundle that gem, and b) set the appropriate env var to
  #  trigger this block
  #
  require "libxml"
  warn "#{__FILE__}:#{__LINE__}: loaded libxml-ruby '#{LibXML::XML::VERSION}'"
end

warn "#{__FILE__}:#{__LINE__}: version info:"
warn Nokogiri::VERSION_INFO.to_yaml

module Nokogiri
  module TestBase
    ASSETS_DIR           = File.expand_path(File.join(File.dirname(__FILE__), "files"))
    ADDRESS_SCHEMA_FILE  = File.join(ASSETS_DIR, "address_book.rlx")
    ADDRESS_XML_FILE     = File.join(ASSETS_DIR, "address_book.xml")
    ENCODING_HTML_FILE   = File.join(ASSETS_DIR, "encoding.html")
    ENCODING_XHTML_FILE  = File.join(ASSETS_DIR, "encoding.xhtml")
    EXML_FILE            = File.join(ASSETS_DIR, "exslt.xml")
    EXSLT_FILE           = File.join(ASSETS_DIR, "exslt.xslt")
    HTML_FILE            = File.join(ASSETS_DIR, "tlm.html")
    METACHARSET_FILE     = File.join(ASSETS_DIR, "metacharset.html")
    NICH_FILE            = File.join(ASSETS_DIR, "2ch.html")
    NOENCODING_FILE      = File.join(ASSETS_DIR, "noencoding.html")
    PO_SCHEMA_FILE       = File.join(ASSETS_DIR, "po.xsd")
    PO_XML_FILE          = File.join(ASSETS_DIR, "po.xml")
    SHIFT_JIS_HTML       = File.join(ASSETS_DIR, "shift_jis.html")
    SHIFT_JIS_NO_CHARSET = File.join(ASSETS_DIR, "shift_jis_no_charset.html")
    SHIFT_JIS_XML        = File.join(ASSETS_DIR, "shift_jis.xml")
    SNUGGLES_FILE        = File.join(ASSETS_DIR, "snuggles.xml")
    XML_FILE             = File.join(ASSETS_DIR, "staff.xml")
    XML_XINCLUDE_FILE    = File.join(ASSETS_DIR, "xinclude.xml")
    XML_ATOM_FILE        = File.join(ASSETS_DIR, "atom.xml")
    XSLT_FILE            = File.join(ASSETS_DIR, "staff.xslt")
    XPATH_FILE           = File.join(ASSETS_DIR, "slow-xpath.xml")

    def i_am_ruby_matching(gem_version_requirement_string)
      Gem::Requirement.new(gem_version_requirement_string).satisfied_by?(Gem::Version.new(RUBY_VERSION))
    end

    def i_am_in_a_systemd_container
      File.exist?("/proc/self/cgroup") && File.read("/proc/self/cgroup") =~ %r(/docker/|/garden/)
    end

    def i_am_running_in_valgrind
      # https://stackoverflow.com/questions/365458/how-can-i-detect-if-a-program-is-running-from-within-valgrind/62364698#62364698
      ENV["LD_PRELOAD"] =~ /valgrind|vgpreload/
    end

    def i_am_running_with_asan
      # https://stackoverflow.com/questions/35012059/check-whether-sanitizer-like-addresssanitizer-is-active
      %x"ldd #{Gem.ruby}".include?("libasan.so")
    rescue
      false
    end

    def skip_unless_libxml2(msg = "this test should only run with libxml2")
      skip(msg) unless Nokogiri.uses_libxml?
    end

    def skip_unless_libxml2_patch(patch_name)
      patch_dir = File.join(__dir__, "..", "patches", "libxml2")
      if File.directory?(patch_dir) && !File.exist?(File.join(patch_dir, patch_name))
        raise("checking for nonexistent patch file #{patch_name.inspect}")
      end

      unless Nokogiri.libxml2_patches.include?(patch_name)
        skip("this test needs libxml2 patched with #{patch_name}")
      end
    end

    def skip_unless_jruby(msg = "this test should only run with jruby")
      skip(msg) unless Nokogiri.jruby?
    end

    def truffleruby_system_libraries?
      RUBY_ENGINE == "truffleruby" && !Nokogiri::PACKAGED_LIBRARIES
    end
  end

  class TestBenchmark < Minitest::BenchSpec
    extend TestBase
  end

  # rubocop:disable Style/ClassVars
  class TestCase < Minitest::Spec
    include TestBase

    COMPACT_EVERY = 20
    @@test_count = 0
    @@gc_level = nil

    def initialize_nokogiri_test_gc_level
      return if Nokogiri.jruby?
      return if @@gc_level

      @@gc_level = if ["stress", "major", "minor", "normal"].include?(ENV["NOKOGIRI_TEST_GC_LEVEL"])
        ENV["NOKOGIRI_TEST_GC_LEVEL"]
      elsif (ENV["NOKOGIRI_TEST_GC_LEVEL"] == "compact") && defined?(GC.compact)
        "compact"
      elsif (ENV["NOKOGIRI_TEST_GC_LEVEL"] == "verify") && defined?(GC.verify_compaction_references)
        "verify"
      else
        "normal"
      end

      if ["compact", "verify"].include?(@@gc_level)
        # the only way of detecting an unsupported platform is actually
        # trying GC compaction
        begin
          GC.compact
        rescue NotImplementedError
          @@gc_level = "normal"
          warn("#{__FILE__}:#{__LINE__}: GC compaction not suppport by platform")
        end
      end
      warn("#{__FILE__}:#{__LINE__}: NOKOGIRI_TEST_GC_LEVEL: #{@@gc_level}")
    end

    def setup
      initialize_nokogiri_test_gc_level

      @@test_count += 1
      if Nokogiri.uses_libxml?
        @fake_error_handler_called = false
        Nokogiri::Test.__foreign_error_handler do
          @fake_error_handler_called = true
        end
      end

      unless Nokogiri.jruby?
        if @@gc_level == "stress"
          GC.stress = true
        end
      end

      super
    end

    def teardown
      unless Nokogiri.jruby?
        case @@gc_level
        when "minor"
          GC.start(full_mark: false)
        when "major"
          GC.start(full_mark: true)
        when "compact"
          if @@test_count % COMPACT_EVERY == 0
            GC.compact
          else
            GC.start(full_mark: true)
          end
        when "verify"
          if @@test_count % COMPACT_EVERY == 0
            # https://alanwu.space/post/check-compaction/
            gc_verify_compaction_references
          end
          GC.start(full_mark: true)
        when "stress"
          GC.stress = false
        end
      end

      if Nokogiri.uses_libxml?
        refute(@fake_error_handler_called, "the fake error handler should never get called")
      end

      super
    end

    def gc_verify_compaction_references
      if Gem::Requirement.new(">= 3.2.0").satisfied_by?(Gem::Version.new(RUBY_VERSION))
        GC.verify_compaction_references(expand_heap: true, toward: :empty)
      else
        GC.verify_compaction_references(double_heap: true, toward: :empty)
      end
    end

    def stress_memory_while(&block)
      # force the test to explicitly declare a skip
      raise "memory stress tests shouldn't be run on JRuby" if Nokogiri.jruby?

      old_stress = GC.stress
      begin
        GC.stress = true
        yield
      ensure
        GC.stress = old_stress
      end
    end

    def refute_valgrind_errors
      # force the test to explicitly declare a skip
      raise "memory stress tests shouldn't be run on JRuby" if Nokogiri.jruby?

      yield.tap do
        GC.start(full_mark: true) if @@gc_level == "minor"
      end
    end

    def assert_indent(amount, doc, message = nil)
      nodes = []
      doc.traverse do |node|
        nodes << node if node.text? && node.blank?
      end
      refute_empty(nodes)
      nodes.each do |node|
        len = node.content.gsub(/[\r\n]/, "").length
        assert_equal(0, len % amount, message)
      end
    end

    def util_decorate(document, decorator_module)
      document.decorators(XML::Node) << decorator_module
      document.decorators(XML::NodeSet) << decorator_module
      document.decorate!
    end

    def assert_not_send(send_ary, m = nil)
      recv, msg, *args = send_ary
      m = message(m) do
        "Expected #{mu_pp(recv)}.#{msg}(*#{mu_pp(args)}) to return false"
      end
      refute(recv.__send__(msg, *args), m)
    end unless method_defined?(:assert_not_send)

    def pending(msg)
      begin
        yield
      rescue Minitest::Assertion
        skip("pending #{msg} [#{caller(2..2).first}]")
      end
      flunk("pending test unexpectedly passed: #{msg} [#{caller(1..1).first}]")
    end

    def pending_if(msg, pend_eh, &block)
      return yield unless pend_eh

      pending(msg, &block)
    end
  end
  # rubocop:enable Style/ClassVars

  module SAX
    class TestCase < Nokogiri::TestCase
      class Doc < XML::SAX::Document
        attr_reader :start_elements, :start_document_called
        attr_reader :end_elements, :end_document_called
        attr_reader :data, :comments, :cdata_blocks, :start_elements_namespace
        attr_reader :errors, :warnings, :end_elements_namespace
        attr_reader :xmldecls
        attr_reader :processing_instructions

        def initialize
          @errors = []
          super
        end

        def xmldecl(version, encoding, standalone)
          @xmldecls = [version, encoding, standalone].compact
          super
        end

        def start_document
          @start_document_called = true
          super
        end

        def end_document
          @end_document_called = true
          super
        end

        def error(error)
          (@errors ||= []) << error
          super
        end

        def warning(warning)
          (@warnings ||= []) << warning
          super
        end

        def start_element(*args)
          (@start_elements ||= []) << args
          super
        end

        def start_element_namespace(*args)
          (@start_elements_namespace ||= []) << args
          super
        end

        def end_element(*args)
          (@end_elements ||= []) << args
          super
        end

        def end_element_namespace(*args)
          (@end_elements_namespace ||= []) << args
          super
        end

        def characters(string)
          @data ||= []
          @data += [string]
          super
        end

        def comment(string)
          @comments ||= []
          @comments += [string]
          super
        end

        def cdata_block(string)
          @cdata_blocks ||= []
          @cdata_blocks += [string]
          super
        end

        def processing_instruction(name, content)
          @processing_instructions ||= []
          @processing_instructions << [name, content]
        end
      end

      # This document will help us to test the strict order of items.

      class DocWithOrderedItems < XML::SAX::Document
        attr_reader :items

        def initialize
          super
          # [
          #   [ :method_1, argument_1, ... ],
          #   [ :method_2, argument_2, ... ],
          #   ...
          # ]
          @items = Items.new
        end

        [
          :xmldecl,
          :start_document,
          :end_document,
          :start_element,
          :end_element,
          :start_element_namespace,
          :end_element_namespace,
          :characters,
          :comment,
          :cdata_block,
          :processing_instruction,
          :error,
          :warning,
        ].each do |name|
          define_method name do |*arguments|
            @items << [name, *arguments]
            super(*arguments)
          end
        end

        class Items < Array
          def get_root_content(root_name)
            items          = clone
            is_inside_root = false

            items.select! do |item|
              method_name  = item[0]
              element_name = item[1]

              case method_name
              when :start_element, :start_element_namespace
                if element_name == root_name
                  is_inside_root = true
                  next false
                end

              when :end_element, :end_element_namespace
                is_inside_root = false if (element_name == root_name) && is_inside_root
              end

              is_inside_root
            end

            items
          end

          def select_methods(names)
            items = clone

            items.select! do |item|
              name = item[0]
              names.include?(name)
            end

            items
          end

          def strip_text!(method_names)
            each do |item|
              method_name = item[0]
              text        = item[1]

              text.strip! if method_names.include?(method_name)
            end

            nil
          end
        end
      end
    end
  end
end

Minitest::Spec.register_spec_type(//, Nokogiri::TestCase) # make TestCase the default
