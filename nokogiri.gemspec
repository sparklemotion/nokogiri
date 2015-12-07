require File.expand_path('../lib/nokogiri/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'nokogiri'
  s.version = Nokogiri::VERSION

  s.files = `git ls-files`.split("\n")
  s.extensions = 'ext/nokogiri/extconf.rb'

  s.bindir = 'bin'
  s.executables << 'nokogiri'

  s.required_ruby_version = '>= 1.9.2'

  # Pulled from https://github.com/envato/nokogiri/blob/master/Rakefile#L132
  s.add_runtime_dependency 'mini_portile2', '~> 2.0.0'

  # Extracted from https://github.com/envato/nokogiri/blob/master/Rakefile#L136-L147
  s.add_development_dependency 'hoe-bundler', '>= 1.1'
  s.add_development_dependency 'hoe-debugging', '~> 1.2.0'
  s.add_development_dependency 'hoe-gemspec', '>= 1.0'
  s.add_development_dependency 'hoe-git', '>= 1.4'
  s.add_development_dependency 'minitest', '~> 2.2.2'
  s.add_development_dependency 'rake', '>= 0.9'
  s.add_development_dependency 'rake-compiler', '~> 0.9.2'
  s.add_development_dependency 'rake-compiler-dock', '~> 0.4.2'
  s.add_development_dependency 'racc', '>= 1.4.6'
  s.add_development_dependency 'rexical', '>= 1.0.5'
end
