require "rubocop/rake_task"

module RubocopHelper
  class << self
    def common_options(task)
      task.options << "--cache=true"
      task.options << "--parallel"
    end

    def prod_directories(task)
      task.patterns += ["bin", "ext", "lib"]
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

  desc "Run rubocop security check"
  RuboCop::RakeTask.new("security") do |task|
    RubocopHelper.common_options(task)
    RubocopHelper.prod_directories(task)
    task.options << "--only=Security"
  end

  desc "Run rubocop string literals check"
  RuboCop::RakeTask.new("frozen_string_literals") do |task|
    RubocopHelper.common_options(task)
    RubocopHelper.prod_directories(task)
    task.options << "--only=Style/FrozenStringLiteralComment"
  end
end

desc "Run rubocop checks"
task rubocop: ["rubocop:security", "rubocop:frozen_string_literals"]
