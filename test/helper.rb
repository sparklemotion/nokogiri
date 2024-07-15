# frozen_string_literal: true

#
# Some environment variables that are used to configure the test suite:
# - NOKOGIRI_TEST_GC_LEVEL: (roughly in order of stress)
#   - "normal" - normal GC functionality (default)
#   - "minor" - force a minor GC cycle after each test
#   - "major" - force a major GC cycle after each test
#   - "compact" - force a major GC after each test and GC compaction after every 20 tests
#   - "verify" - force a major GC after each test and verify references-after-compaction after every 20 tests
#   - "stress" - run tests with GC.stress set to true
# - NOKOGIRI_MEMORY_SUITE: read more in test/test_memory_usage.rb
#

$VERBOSE = true

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
warn

require "minitest/autorun"
require "minitest/benchmark"

if !Nokogiri.jruby? && ENV["NCPU"].to_i > 1
  require "minitest/parallel_fork"
  warn "Running parallel tests with NCPU=#{ENV["NCPU"].inspect}"
end

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

    class << self
      def nokogiri_test_gc_level
        level = ENV["NOKOGIRI_TEST_GC_LEVEL"]&.to_sym

        if [:stress, :major, :minor, :normal].include?(level)
          level
        elsif (level == :compact) && defined?(GC.compact)
          :compact
        elsif (level == :verify) && defined?(GC.verify_compaction_references) &&
            Gem::Requirement.new(">= 3.3.0").satisfied_by?(Gem::Version.new(RUBY_VERSION))
          :verify
        else
          :normal
        end
      end
    end

    def initialize_nokogiri_test_gc_level
      return if Nokogiri.jruby?
      return if @@gc_level

      @@gc_level = TestCase.nokogiri_test_gc_level

      if [:compact, :verify].include?(@@gc_level)
        # the only way of detecting an unsupported platform is actually trying GC compaction
        begin
          GC.compact
        rescue NotImplementedError
          @@gc_level = :normal
          warn("#{__FILE__}:#{__LINE__}: GC compaction not supported by platform")
        end
      end
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
        if @@gc_level == :stress
          GC.stress = true
        end
      end

      super
    end

    def teardown
      unless Nokogiri.jruby?
        case @@gc_level
        when :minor
          GC.start(full_mark: false)
        when :major
          GC.start(full_mark: true)
        when :compact
          if @@test_count % COMPACT_EVERY == 0
            GC.compact
            putc("<")
          else
            GC.start(full_mark: true)
          end
        when :verify
          if @@test_count % COMPACT_EVERY == 0
            gc_verify_compaction_references
            putc("!")
          end
          GC.start(full_mark: true)
        when :stress
          GC.stress = false
        end
      end

      super

      if !skipped? && !error? && assertions.zero?
        raise(Minitest::Assertion, "Test is missing assertions")
      end

      if Nokogiri.uses_libxml?
        refute(@fake_error_handler_called, "the fake error handler should never get called")
      end
    end

    def gc_verify_compaction_references
      # https://alanwu.space/post/check-compaction/
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
        GC.start(full_mark: true) if @@gc_level == :minor
        @assertions += 1
      end
    end

    def refute_raises
      yield.tap do
        @assertions += 1
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

    # returns the page size in bytes
    # will only work on linux
    def meminfo_page_size
      @page_size ||= %x(getconf PAGESIZE).chomp.to_i
    end

    # returns the vmsize in bytes
    # will only work on linux
    def meminfo_vmsize
      File.read("/proc/self/statm").split(" ")[0].to_i * meminfo_page_size
    end

    # returns the rss in bytes
    # will only work on linux
    def meminfo_rss
      File.read("/proc/self/statm").split(" ")[1].to_i * meminfo_page_size
    end

    # see test/test_memory_usage.rb for example usage
    #
    # when running under valgrind, this just loops for 1 second, so that valgrind leak check
    # (ruby_memcheck) can find any leaks.
    #
    # otherwise, will loop for 10 seconds, measure vmsize over time, calculate the best-fit linear
    # slope, and fail if there is definitely a leak.
    def memwatch(method, n: nil, retry_once: true, &block)
      if i_am_running_in_valgrind
        refute_valgrind_errors do
          t1 = Time.now
          loop do
            yield
            break if Time.new - t1 > 1
          end
        end

        return
      end

      measurements = 10
      default_run_length = 10 # seconds
      warmup = 2.0 # seconds

      if n.nil?
        # calculate n to run for about default_run_length seconds
        t1 = Time.now
        n = 0
        loop do
          n += 1

          yield

          break if (Time.now - t1) > warmup
        end
        n = (n * (default_run_length / warmup)).ceil(-3)
      end
      data_point_every = n / measurements

      puts

      memsizes = []
      iterations = []

      t1 = Time.now
      (n + 1).times do |j| # plus one to print out the final iteration
        if j % data_point_every == 0
          GC.start(full_mark: true)
          memsize = meminfo_vmsize

          printf("memwatch: %s: (n=%-2d %7d) %d Kb", method, memsizes.length + 1, j, memsize / 1024)
          unless memsizes.empty?
            delta = memsize - memsizes.last
            printf(", Δ %+d", delta / 1024)
          end
          print("\n")

          iterations << j
          memsizes << memsize.to_f # so fit_linear gives us floats
        end

        yield
      end
      printf("memwatch: %s: elapsed %fs\n", method, Time.now - t1)

      bench = Minitest::Benchmark.new("meminfo")
      _a_coeff, b_coeff, r_squared = bench.fit_linear(iterations, memsizes)
      printf(
        "memwatch: %s: slope = %.5f (r^2 = %.3f)\n",
        method,
        b_coeff,
        r_squared,
      )

      begin
        # we use `< 1` because losing more than 1 byte per iteration is a leak
        refute(
          b_coeff >= 1 && r_squared >= 0.7,
          "best-fit slope #{b_coeff} (r^2=#{r_squared}) should be close to zero",
        )
      rescue Minitest::Assertion => e
        if retry_once
          printf("memwatch: %s: #{e}: retrying once\n", method)
          memwatch(method, n: n, retry_once: false, &block)
        else
          raise e
        end
      end
    end
  end
  # rubocop:enable Style/ClassVars

  module SAX
    class TestCase < Nokogiri::TestCase
      class Doc < XML::SAX::Document
        attr_reader :start_elements
        attr_reader :start_document_called
        attr_reader :end_elements
        attr_reader :end_document_called
        attr_reader :data
        attr_reader :comments
        attr_reader :cdata_blocks
        attr_reader :start_elements_namespace
        attr_reader :errors
        attr_reader :warnings
        attr_reader :end_elements_namespace
        attr_reader :xmldecls
        attr_reader :processing_instructions
        attr_reader :references

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
          super
        end

        def reference(name, content)
          @references ||= []
          @references << [name, content]
          super
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

warn("NOKOGIRI_TEST_GC_LEVEL: #{Nokogiri::TestCase.nokogiri_test_gc_level}")

Minitest::Spec.register_spec_type(//, Nokogiri::TestCase) # make TestCase the default
