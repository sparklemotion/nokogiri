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

  file PARSER_DEPS do |t|
    sh "racc -l -o #{t.name} #{t.prerequisites.first}"
  end

  file TOKENIZER_DEPS do |t|
    sh "rex --independent -o #{t.name} #{t.prerequisites.first}"
  end
end

task "compile" => "css:generate" # rubocop:disable Rake/Desc
task "check_manifest" => "css:generate" # rubocop:disable Rake/Desc
