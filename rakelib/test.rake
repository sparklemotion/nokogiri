# frozen_string_literal: true

require "minitest/test_task"

begin
  require "ruby_memcheck"
rescue LoadError => e
  warn("WARNING: ruby_memcheck is not available in this environment: #{e}")
end

#
#  much of this was ripped out of hoe-debugging
#
class ValgrindTestTask < Minitest::TestTask
  DEFAULT_DIRECTORY_NAME = "suppressions"
  ERROR_EXITCODE = 42 # the answer to life, the universe, and segfaulting.
  VALGRIND_OPTIONS = [
    "--num-callers=50",
    "--error-limit=no",
    "--partial-loads-ok=yes",
    "--undef-value-errors=no",
    "--error-exitcode=#{ERROR_EXITCODE}",
    "--gen-suppressions=all",
  ]

  if defined?(RubyMemcheck)
    RubyMemcheck.config(binary_name: "nokogiri", valgrind_generate_suppressions: true)
  end

  def ruby(*args, **options, &block)
    ENV["NCPU"] = nil # don't run valgrind in parallel (minitest-parallel_fork)

    valgrind_options = check_for_suppression_file(VALGRIND_OPTIONS)
    command = "ulimit -s unlimited && valgrind #{valgrind_options.join(" ")} #{RUBY} #{args.join(" ")}"
    sh(command, **options, &block)
  end

  def formatted_ruby_version
    engine = if defined?(RUBY_DESCRIPTION) && RUBY_DESCRIPTION.include?("Ruby Enterprise Edition")
      "ree"
    else
      defined?(RUBY_ENGINE) ? RUBY_ENGINE : "ruby"
    end
    %{#{engine}-#{RUBY_VERSION}.#{RUBY_PATCHLEVEL}}
  end

  def check_for_suppression_file(options)
    options = options.dup
    suppression_files = matching_suppression_files
    suppression_files.each do |suppression_file|
      puts "NOTICE: using valgrind suppressions in #{suppression_file.inspect}"
      options << "--suppressions=#{suppression_file}"
    end
    options
  end

  def matching_suppression_files
    matching_files = []
    version_matches.each do |version_string|
      matching_files += Dir[File.join(DEFAULT_DIRECTORY_NAME, "#{version_string}.supp")]
      matching_files += Dir[File.join(DEFAULT_DIRECTORY_NAME, "#{version_string}_*.supp")]
    end
    matching_files
  end

  def version_matches
    matches = [formatted_ruby_version] # e.g. "ruby-2.5.1.57"
    matches << formatted_ruby_version.split(".")[0, 3].join(".") # e.g. "ruby-2.5.1"
    matches << formatted_ruby_version.split(".")[0, 2].join(".") # e.g. "ruby-2.5"
    matches << formatted_ruby_version.split(".")[0, 1].join(".") # e.g. "ruby-2"
    matches << formatted_ruby_version.split("-").first # e.g. "ruby"
    matches
  end
end

class GdbTestTask < Minitest::TestTask
  def ruby(*args, **options, &block)
    ENV["NCPU"] = nil

    command = "gdb --args #{RUBY} #{args.join(" ")}"
    sh(command, **options, &block)
  end
end

class LldbTestTask < Minitest::TestTask
  def ruby(*args, **options, &block)
    ENV["NCPU"] = nil

    command = "lldb #{RUBY} -- #{args.join(" ")}"
    sh(command, **options, &block)
  end
end

class MemorySuiteTestTask < Minitest::TestTask
  def ruby(*args, **options, &block)
    ENV["NCPU"] = nil
    ENV["NOKOGIRI_MEMORY_SUITE"] = "t"
    ENV["NOKOGIRI_TEST_GC_LEVEL"] = "major"

    super
  end
end

if defined?(RubyMemcheck)
  class MemcheckTestTask < RubyMemcheck::TestTask
    def ruby(*args, **options, &block)
      ENV["NCPU"] = nil
      ENV["NOKOGIRI_MEMORY_SUITE"] = "t"

      super
    end

    # RubyMemcheck::TestTask inherits from Rake::TestTask,
    # let's make it emulate this aspect of Minitest::TestTask
    def test_globs=(glob)
      self.pattern = glob
    end
  end
end

def nokogiri_test_task_configuration(t)
  t.libs << "test"
  t.verbose = true if ENV["TESTGLOB"]
  t.test_prelude = 'require "simplecov_prelude"' if t.respond_to?(:test_prelude)
end

def nokogiri_test_case_configuration(t)
  nokogiri_test_task_configuration(t)
  t.test_globs = ENV["TESTGLOB"] || "test/**/test_*.rb"
end

def nokogiri_test_bench_configuration(t)
  nokogiri_test_task_configuration(t)
  t.test_globs = "test/**/bench_*.rb"
end

def nokogiri_test_memory_suite_configuration(t)
  nokogiri_test_task_configuration(t)
  t.test_globs = "test/test_memory_usage.rb"
end

Minitest::TestTask.create do |t|
  nokogiri_test_case_configuration(t)
end

namespace "test" do
  Minitest::TestTask.create("bench") do |t|
    nokogiri_test_bench_configuration(t)
  end

  ValgrindTestTask.create("valgrind") do |t|
    nokogiri_test_case_configuration(t)
  end

  GdbTestTask.create("gdb") do |t|
    nokogiri_test_case_configuration(t)
  end

  LldbTestTask.create("lldb") do |t|
    nokogiri_test_case_configuration(t)
  end

  MemorySuiteTestTask.create("memory_suite") do |t|
    nokogiri_test_memory_suite_configuration(t)
  end

  if defined?(RubyMemcheck)
    MemcheckTestTask.new("memcheck") do |t|
      nokogiri_test_case_configuration(t)
    end
  end
end
