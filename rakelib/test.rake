# frozen_string_literal: true

require "rake/testtask"
require "ruby_memcheck"

#
#  much of this was ripped out of hoe-debugging
#
class ValgrindTestTask < Rake::TestTask
  DEFAULT_DIRECTORY_NAME = "suppressions"
  ERROR_EXITCODE = 42 # the answer to life, the universe, and segfaulting.
  VALGRIND_OPTIONS = ["--num-callers=50",
                      "--error-limit=no",
                      "--partial-loads-ok=yes",
                      "--undef-value-errors=no",
                      "--error-exitcode=#{ERROR_EXITCODE}",
                      "--gen-suppressions=all",]

  RubyMemcheck.config(
    binary_name: "nokogiri",
    valgrind_generate_suppressions: true,
  )

  def ruby(*args, **options, &block)
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
      matching_files += Dir[File.join(DEFAULT_DIRECTORY_NAME, "nokogiri_#{version_string}.supp")]
      matching_files += Dir[File.join(DEFAULT_DIRECTORY_NAME, "nokogiri_#{version_string}_*.supp")]
    end
    matching_files
  end

  def version_matches
    matches = [formatted_ruby_version] # e.g. "ruby-2.5.1.57"
    matches << formatted_ruby_version.split(".")[0, 3].join(".") # e.g. "ruby-2.5.1"
    matches << formatted_ruby_version.split(".")[0, 2].join(".") # e.g. "ruby-2.5"
    matches << formatted_ruby_version.split(".")[0, 1].join(".") # e.g. "ruby-2"
    matches << formatted_ruby_version.split("-").first          # e.g. "ruby"
    matches
  end
end

class GdbTestTask < ValgrindTestTask
  def ruby(*args, **options, &block)
    command = "gdb --args #{RUBY} #{args.join(" ")}"
    sh(command, **options, &block)
  end
end

class LldbTestTask < ValgrindTestTask
  def ruby(*args, **options, &block)
    command = "lldb #{RUBY} -- #{args.join(" ")}"
    sh(command, **options, &block)
  end
end

def nokogiri_test_task_configuration(t)
  t.libs << "test"
  t.verbose = true
  t.options = "-v" if ENV["CI"]
end

def nokogiri_test_case_configuration(t)
  nokogiri_test_task_configuration(t)
  t.test_files = FileList["test/**/test_*.rb"]
end

def nokogiri_test_bench_configuration(t)
  nokogiri_test_task_configuration(t)
  t.test_files = FileList["test/**/bench_*.rb"]
end

Rake::TestTask.new do |t|
  nokogiri_test_case_configuration(t)
end

namespace "test" do
  Rake::TestTask.new("bench") do |t|
    nokogiri_test_bench_configuration(t)
  end

  ValgrindTestTask.new("valgrind") do |t|
    nokogiri_test_case_configuration(t)
  end

  GdbTestTask.new("gdb") do |t|
    nokogiri_test_case_configuration(t)
  end

  LldbTestTask.new("lldb") do |t|
    nokogiri_test_case_configuration(t)
  end

  RubyMemcheck::TestTask.new("memcheck") do |t|
    nokogiri_test_case_configuration(t)
  end
end
