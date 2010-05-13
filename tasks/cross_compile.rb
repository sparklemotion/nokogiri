### Build zlib ###
file 'tmp/cross/download/zlib-1.2.5' do |t|
  FileUtils.mkdir_p('tmp/cross/download')

  file = 'zlib-1.2.5'
  url  = "http://zlib.net/#{file}.tar.gz"

  Dir.chdir('tmp/cross/download') do
    sh "wget #{url} || curl -O #{url}"
    sh "tar zxvf #{file}.tar.gz"
  end

  Dir.chdir t.name do
    mk = File.read('win32/Makefile.gcc')
    File.open('win32/Makefile.gcc', 'wb') do |f|
      f.puts "BINARY_PATH = #{CROSS_DIR}/bin"
      f.puts "LIBRARY_PATH = #{CROSS_DIR}/lib"
      f.puts "INCLUDE_PATH = #{CROSS_DIR}/include"

      # FIXME: need to make the cross compiler dynamic
      f.puts mk.sub(/^PREFIX\s*=\s*$/, 'PREFIX = i386-mingw32-').
        sub(/^SHARED_MODE=0$/, 'SHARED_MODE=1')
    end
  end
end

file 'tmp/cross/bin/zlib1.dll' => 'tmp/cross/download/zlib-1.2.5' do |t|
  Dir.chdir t.prerequisites.first do
    sh 'make -f win32/Makefile.gcc'
    sh 'make -f win32/Makefile.gcc install'
  end
end
### End build zlib ###

### Build iconv ###
file 'tmp/cross/download/libiconv-1.13.1' do |t|
  FileUtils.mkdir_p('tmp/cross/download')

  file = 'libiconv-1.13.1'
  url  = "http://ftp.gnu.org/pub/gnu/libiconv/#{file}.tar.gz"

  Dir.chdir('tmp/cross/download') do
    sh "wget #{url} || curl -O #{url}"
    sh "tar zxvf #{file}.tar.gz"
  end

  Dir.chdir t.name do
    # FIXME: need to make the host dynamic
    sh "./configure --enable-shared --enable-static --host=i386-mingw32 --prefix=#{CROSS_DIR} CPPFLAGS='-mno-cygwin -Wall' CFLAGS='-mno-cygwin -O2 -g' CXXFLAGS='-mno-cygwin -O2 -g' LDFLAGS=-mno-cygwin"
  end
end

file 'tmp/cross/bin/iconv.exe' => 'tmp/cross/download/libiconv-1.13.1' do |t|
  Dir.chdir t.prerequisites.first do
    sh 'make'
    sh 'make install'
  end
end
### End build iconv ###

### Build libxml2 ###
file 'tmp/cross/download/libxml2-2.7.7' do |t|
  FileUtils.mkdir_p('tmp/cross/download')

  file = 'libxml2-2.7.7'
  url  = "ftp://ftp.xmlsoft.org/libxml2/#{file}.tar.gz"

  Dir.chdir('tmp/cross/download') do
    sh "wget #{url} || curl -O #{url}"
    sh "tar zxvf #{file}.tar.gz"
  end

  Dir.chdir t.name do
    # FIXME: need to make the host dynamic
    sh "CFLAGS='-DIN_LIBXML' ./configure --host=i386-mingw32 --enable-static --enable-shared --prefix=#{CROSS_DIR} --with-zlib=#{CROSS_DIR} --with-iconv=#{CROSS_DIR} --without-python --without-readline"
  end
end

file 'tmp/cross/bin/xml2-config' => 'tmp/cross/download/libxml2-2.7.7' do |t|
  Dir.chdir t.prerequisites.first do
    sh 'make'
    sh 'make install'
  end
end
### End build libxml2 ###

### Build libxslt ###
file 'tmp/cross/download/libxslt-1.1.26' do |t|
  FileUtils.mkdir_p('tmp/cross/download')

  file = 'libxslt-1.1.26'
  url  = "ftp://ftp.xmlsoft.org/libxml2/#{file}.tar.gz"

  Dir.chdir('tmp/cross/download') do
    sh "wget #{url} || curl -O #{url}"
    sh "tar zxvf #{file}.tar.gz"
  end

  Dir.chdir t.name do
    # FIXME: need to make the host dynamic
    sh "CFLAGS='-DIN_LIBXML' ./configure --host=i386-mingw32 --enable-static --enable-shared --prefix=#{CROSS_DIR} --with-libxml-prefix=#{CROSS_DIR} --without-python"
  end
end

file 'tmp/cross/bin/xslt-config' => 'tmp/cross/download/libxslt-1.1.26' do |t|
  Dir.chdir t.prerequisites.first do
    sh 'make'
    sh 'make install'
  end
end
### End build libxslt ###

file 'lib/nokogiri/nokogiri.rb' => 'cross:libxslt' do
  File.open("lib/#{HOE.name}/#{HOE.name}.rb", 'wb') do |f|
    f.write <<-eoruby
require "#{HOE.name}/\#{RUBY_VERSION.sub(/\\.\\d+$/, '')}/#{HOE.name}"
    eoruby
  end
end

namespace :cross do
  task :iconv   => 'tmp/cross/bin/iconv.exe'
  task :zlib    => 'tmp/cross/bin/zlib1.dll'
  task :libxml2 => ['cross:zlib', 'cross:iconv', 'tmp/cross/bin/xml2-config']
  task :libxslt => ['cross:libxml2', 'tmp/cross/bin/xslt-config']

  task :copy_dlls do
    Dir['tmp/cross/bin/*.dll'].each do |file|
      cp file, "ext/nokogiri"
    end
  end

  task :file_list => 'cross:copy_dlls' do
    HOE.spec.extensions = []
    HOE.spec.files += Dir["lib/#{HOE.name}/#{HOE.name}.rb"]
    HOE.spec.files += Dir["lib/#{HOE.name}/1.{8,9}/#{HOE.name}.so"]
    HOE.spec.files += Dir["ext/nokogiri/*.dll"]
  end
end

CLOBBER.include("lib/nokogiri/nokogiri.{so,dylib,rb,bundle}")
CLOBBER.include("lib/nokogiri/1.{8,9}")
CLOBBER.include("ext/nokogiri/*.dll")

if Rake::Task.task_defined?(:cross)
  Rake::Task[:cross].prerequisites << "lib/nokogiri/nokogiri.rb"
  Rake::Task[:cross].prerequisites << "cross:file_list"
end
