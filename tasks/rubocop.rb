desc "Run rubocop checks"
task :rubocop => [:rubocop_security, :rubocop_frozen_string_literals]

desc "Run rubocop security check"
task :rubocop_security do
  sh "rubocop lib --only Security"
end

desc "Run rubocop string literals check"
task :rubocop_frozen_string_literals do
  sh "rubocop lib --auto-correct-all --only Style/FrozenStringLiteralComment"
end
