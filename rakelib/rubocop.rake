# frozen_string_literal: true

require "rubocop/rake_task"

module RubocopHelper
  class << self
    def common_options(task)
      task.patterns += [
        "Gemfile", "Rakefile", "nokogiri.gemspec",
        "bin", "ext", "lib", "oci-images", "rakelib", "scripts", "test",
      ]
      task.options << "--cache=true"
      task.options << "--parallel"
    end
  end
end

namespace "rubocop" do
  desc "Generate the rubocop todo list"
  RuboCop::RakeTask.new("todo") do |task|
    RubocopHelper.common_options(task)
    task.options << "--auto-gen-config"
  end

  desc "Run all checks on a subset of directories"
  RuboCop::RakeTask.new("check") do |task|
    RubocopHelper.common_options(task)
  end
end

desc "Run rubocop checks"
task rubocop: "rubocop:check"
