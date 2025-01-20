# frozen_string_literal: true

# rubocop:disable Style/WordArray

# replacement for Hoe's task of the same name

desc "Perform a sanity check on the gemspec file list"
task :check_manifest, [:verbose] do |_, args|
  verbose = args[:verbose]

  raw_gemspec = Bundler.load_gemspec("nokogiri.gemspec")

  ignore_directories = %w{
    .bundle
    .DS_Store
    .git
    .github
    .ruby-lsp
    .vagrant
    .vscode
    adr
    coverage
    gems
    html
    issues
    misc
    oci-images
    patches
    pkg
    ports
    rakelib
    scripts
    sorbet
    suppressions
    test
    tmp
    vendor
    [0-9]*
  }
  ignore_files = %w[
    .editorconfig
    .gitignore
    .gitmodules
    .rubocop.yml
    .rubocop_exclude.yml
    .rubocop_todo.yml
    CHANGELOG.md
    CODE_OF_CONDUCT.md
    CONTRIBUTING.md
    Gemfile?*
    ROADMAP.md
    Rakefile
    SECURITY.md
    Vagrantfile
    [a-z]*.{log,out}
    [0-9]*
    appveyor.yml
    **/compile_commands.json
    gumbo-parser/fuzzer/*
    gumbo-parser/googletest/*
    gumbo-parser/test/*
    gumbo-parser/gperf-filter.sed
    lib/nokogiri/**/nokogiri.{jar,so}
    lib/nokogiri/nokogiri.{jar,so}
    nokogiri.gemspec
  ]

  if verbose
    ignore_directories.each do |glob|
      matches = Dir.glob(glob).select { |filename| File.directory?(filename) }
      $stderr.puts "NOTE: ignored directory glob '#{glob}' has zero matches" if matches.empty?
    end

    ignore_files.each do |glob|
      matches = Dir.glob(glob).select { |filename| File.file?(filename) }
      $stderr.puts "NOTE: ignored file glob '#{glob}' has zero matches" if matches.empty?
    end
  end

  intended_directories = Dir.children(".")
    .select { |filename| File.directory?(filename) }
    .reject { |filename| ignore_directories.any? { |ig| File.fnmatch?(ig, filename) } }

  intended_files = Dir.children(".")
    .select { |filename| File.file?(filename) }
    .reject { |filename| ignore_files.any? { |ig| File.fnmatch?(ig, filename, File::FNM_EXTGLOB) } }

  intended_files += Dir.glob(intended_directories.map { |d| File.join(d, "/**/*") })
    .select { |filename| File.file?(filename) }
    .reject { |filename| ignore_files.any? { |ig| File.fnmatch?(ig, filename, File::FNM_EXTGLOB) } }
    .sort

  spec_files = raw_gemspec.files.sort

  missing_files = intended_files - spec_files
  extra_files = spec_files - intended_files

  unless missing_files.empty?
    puts "missing:"
    missing_files.sort.each { |f| puts "- #{f}" }
  end
  unless extra_files.empty?
    puts "unexpected:"
    extra_files.sort.each { |f| puts "+ #{f}" }
  end
end

# rubocop:enable Style/WordArray
