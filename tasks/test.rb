# partial-loads-ok and undef-value-errors necessary to ignore
# spurious (and eminently ignorable) warnings from the ruby
# interpreter
VALGRIND_BASIC_OPTS = "--num-callers=50 --error-limit=no --partial-loads-ok=yes --undef-value-errors=no"

class NokogiriTestTask < Rake::TestTask
  def initialize *args
    super
    %w[ ext lib bin test ].each do |dir|
      self.libs << dir
    end
    self.test_files = FileList['test/**/test_*.rb'] +
      FileList['test/**/*_test.rb']
    self.verbose = "verbose"
    self.warning = true
  end
end

desc "run test suite under valgrind with basic ruby options"
NokogiriTestTask.new('test:valgrind').extend(Module.new {
  def ruby *args
    cmd = "valgrind #{VALGRIND_BASIC_OPTS} #{RUBY} #{args.join(' ')} test/test_nokogiri.rb --verbose=verbose"
    puts cmd
    system cmd
  end
})

desc "run test suite under valgrind with memory-fill ruby options"
NokogiriTestTask.new('test:valgrind_mem').extend(Module.new {
  def ruby *args
    cmd = "valgrind #{VALGRIND_BASIC_OPTS} --freelist-vol=100000000 --malloc-fill=6D --free-fill=66 #{RUBY} #{args.join(' ')} test/test_nokogiri.rb --verbose=verbose"
    puts cmd
    system cmd
  end
})

desc "run test suite under valgrind with memory-zero ruby options"
NokogiriTestTask.new('test:valgrind_mem0').extend(Module.new {
  def ruby *args
    cmd = "valgrind #{VALGRIND_BASIC_OPTS} --freelist-vol=100000000 --malloc-fill=00 --free-fill=00 #{RUBY} #{args.join(' ')} test/test_nokogiri.rb --verbose=verbose"
    puts cmd
    system cmd
  end
})

desc "run test suite under gdb"
NokogiriTestTask.new('test:gdb').extend(Module.new {
  def ruby *args
    cmd = "gdb --args #{RUBY} #{args.join(' ')}"
    puts cmd
    system cmd
  end
})

desc "test coverage"
NokogiriTestTask.new('test:coverage').extend(Module.new {
  def ruby *args
    rm_rf "coverage"
    cmd = "rcov -x Library -I lib:ext:test #{args.join(' ')}"
    puts cmd
    system cmd
  end
})

namespace :test do
  desc "run test suite with aggressive GC"
  task :gc => :build do
    ENV['NOKOGIRI_GC'] = "true"
    Rake::Task["test"].invoke
  end

  desc "find call-seq in the rdoc"
  task :rdoc => 'docs' do
    Dir['doc/**/*.html'].each { |docfile|
      next if docfile =~ /\.src/
      puts "FAIL: #{docfile}" if File.read(docfile) =~ /call-seq/
    }
  end

  desc "Test against multiple versions of libxml2"
  task :multixml2 do
    MULTI_XML = File.join(ENV['HOME'], '.multixml2')
    unless File.exists?(MULTI_XML)
      %w{ versions install build }.each { |x|
        FileUtils.mkdir_p(File.join(MULTI_XML, x))
      }
      Dir.chdir File.join(MULTI_XML, 'versions') do
        require 'net/ftp'
        ftp = Net::FTP.new('xmlsoft.org')
        ftp.login('anonymous', 'anonymous')
        ftp.chdir('libxml2')
        ftp.list('libxml2-2.*.tar.gz').each do |x|
          file = x[/[^\s]*$/]
          puts "Downloading #{file}"
          ftp.getbinaryfile(file)
        end
      end
    end

    # Build any libxml2 versions in $HOME/.multixml2/versions that
    # haven't been built yet
    Dir[File.join(MULTI_XML, 'versions','*.tar.gz')].each do |f|
      filename = File.basename(f, '.tar.gz')

      install_dir = File.join(MULTI_XML, 'install', filename)
      next if File.exists?(install_dir)

      Dir.chdir File.join(MULTI_XML, 'versions') do
        system "tar zxvf #{f} -C #{File.join(MULTI_XML, 'build')}"
      end

      Dir.chdir File.join(MULTI_XML, 'build', filename) do
        system "./configure --prefix=#{install_dir}"
        system "make && make install"
      end
    end

    test_results = {}
    libxslt = Dir[File.join(MULTI_XML, 'install', 'libxslt*')].first
    Dir[File.join(MULTI_XML, 'install', '*')].each do |xml2_version|
      next unless xml2_version =~ /libxml2/
      extopts = "--with-xml2-include=#{xml2_version}/include/libxml2 --with-xml2-lib=#{xml2_version}/lib --with-xslt-dir=#{libxslt}"
      cmd = "#{$0} clean test EXTOPTS='#{extopts}'"

      version = File.basename(xml2_version)
      result = system(cmd)
      test_results[version] = {
        :result => result,
        :cmd    => cmd
      }
    end
    test_results.sort_by { |k,v| k }.each do |k,v|
      passed = v[:result]
      puts "#{k}: #{passed ? 'PASS' : 'FAIL'}"
      puts "repro: #{v[:cmd]}" unless passed
    end
  end
end
