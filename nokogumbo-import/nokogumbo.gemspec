require_relative 'lib/nokogumbo/version'

Gem::Specification.new do |s|
  s.name = 'nokogumbo'
  s.version = Nokogumbo::VERSION

  s.authors = ['Sam Ruby', 'Stephen Checkoway']
  s.email = ['rubys@intertwingly.net', 's@pahtak.org']

  s.license = 'Apache-2.0'
  s.homepage = 'https://github.com/rubys/nokogumbo/#readme'
  s.summary = 'Nokogiri interface to the Gumbo HTML5 parser'
  s.description = 'Nokogumbo allows a Ruby program to invoke the Gumbo ' \
    'HTML5 parser and access the result as a Nokogiri parsed document.'

  s.metadata = {
    'bug_tracker_uri' => 'https://github.com/rubys/nokogumbo/issues',
    'changelog_uri'   => 'https://github.com/rubys/nokogumbo/blob/master/CHANGELOG.md',
    'homepage_uri'    => s.homepage,
    'source_code_uri' => 'https://github.com/rubys/nokogumbo'
  }

  s.extensions = %w[ ext/nokogumbo/extconf.rb ]

  s.files = %w[ LICENSE.txt README.md ] +
    Dir['lib/**/*.rb'] +
    Dir['ext/nokogumbo/*.{rb,c}'] +
    Dir['gumbo-parser/src/*.[hc]']

  s.required_ruby_version = ">= 2.1"
  s.add_runtime_dependency 'nokogiri', '~> 1.8', '>= 1.8.4'
end
