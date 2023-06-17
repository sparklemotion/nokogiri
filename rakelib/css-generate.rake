# frozen_string_literal: true

casual_file_task = Class.new(Rake::FileTask) do
  # to avoid re-running these tasks after a git checkout, let's give it a 1 second window before we re-run
  def needed?
    !File.exist?(name) || out_of_date?(File.mtime(name) + 1) || @application.options.build_all
  end
end

namespace "css" do
  PARSER_DEPS = { "lib/nokogiri/css/parser.rb" => "lib/nokogiri/css/parser.y" }
  TOKENIZER_DEPS = { "lib/nokogiri/css/tokenizer.rb" => "lib/nokogiri/css/tokenizer.rex" }
  DEPS = PARSER_DEPS.merge(TOKENIZER_DEPS)

  desc "Generate CSS parser and tokenizer"
  task "generate" => DEPS.keys

  desc "Clean up generated CSS parser and tokenizer"
  task "clean" do
    DEPS.keys.each { |f| FileUtils.rm_f(f, verbose: true) }
  end

  casual_file_task.define_task(PARSER_DEPS) do |t|
    sh "racc -l -o #{t.name} #{t.prerequisites.first}"
  end

  casual_file_task.define_task(TOKENIZER_DEPS) do |t|
    sh "rex --independent -o #{t.name} #{t.prerequisites.first}"
  end
end

task "compile" => "css:generate" # rubocop:disable Rake/Desc
task "check_manifest" => "css:generate" # rubocop:disable Rake/Desc
