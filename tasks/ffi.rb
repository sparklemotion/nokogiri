desc "build ffi files"
task :ffi do
  ffi_generate("lib/nokogiri", {:cflags => "-I/usr/include/libxml2"})
end

def ffi_files(dir=nil)
  require 'find'
  files = []
  dir = dir || ENV['FFI_DIR'] || 'lib'
  Find.find(dir) { |f| files << f if f =~ /\.rb\.ffi$/ }
  files.collect { |ffi_file| [ffi_file, ffi_file.gsub(/\.ffi$/,'')] }
end

def ffi_generate(dir, options={})
  require 'ffi'
  require 'ffi/tools/generator'
  require 'ffi/tools/struct_generator'

  ffi_files(dir).each do |ffi_file, ruby_file|
    unless uptodate?(ruby_file, ffi_file)
      puts "ffi: #{ffi_file} => #{ruby_file}"
      FFI::Generator.new ffi_file, ruby_file, options
    end
  end
end
