# frozen_string_literal: true

require "rbconfig"
require "shellwords"

CrossRuby = Struct.new(:version, :platform) do
  WINDOWS_PLATFORM_REGEX = /mingw|mswin/
  MINGWUCRT_PLATFORM_REGEX = /mingw-ucrt/
  MINGW32_PLATFORM_REGEX = /mingw32/
  LINUX_PLATFORM_REGEX = /linux/
  X86_LINUX_GNU_PLATFORM_REGEX = /x86.*linux-gnu$/
  X86_LINUX_MUSL_PLATFORM_REGEX = /x86.*linux-musl$/
  AARCH_LINUX_GNU_PLATFORM_REGEX = /aarch.*linux-gnu$/
  AARCH_LINUX_MUSL_PLATFORM_REGEX = /aarch.*linux-musl$/
  ARM_LINUX_GNU_PLATFORM_REGEX = /arm-linux-gnu$/
  ARM_LINUX_MUSL_PLATFORM_REGEX = /arm-linux-musl$/
  DARWIN_PLATFORM_REGEX = /darwin/

  def windows?
    !!(platform =~ WINDOWS_PLATFORM_REGEX)
  end

  def linux?
    !!(platform =~ LINUX_PLATFORM_REGEX)
  end

  def darwin?
    !!(platform =~ DARWIN_PLATFORM_REGEX)
  end

  def ver
    @ver ||= version[/\A[^-]+/]
  end

  def minor_ver
    @minor_ver ||= ver[/\A\d\.\d(?=\.)/]
  end

  def api_ver_suffix
    case minor_ver
    when nil
      raise "CrossRuby.api_ver_suffix: unsupported version: #{ver}"
    else
      minor_ver.delete(".") << "0"
    end
  end

  def tool(name)
    (@binutils_prefix ||= case platform
     when "aarch64-linux-gnu" then "aarch64-linux-gnu-"
     when "aarch64-linux-musl" then "aarch64-linux-musl-"
     when "arm-linux-gnu" then "arm-linux-gnueabihf-"
     when "arm-linux-musl" then "arm-linux-musleabihf-"
     when "arm64-darwin" then "aarch64-apple-darwin-"
     when "x64-mingw-ucrt", "x64-mingw32" then "x86_64-w64-mingw32-"
     when "x86-linux-gnu" then "i686-redhat-linux-gnu-"
     when "x86-linux-musl" then "i686-unknown-linux-musl-"
     when "x86-mingw32" then "i686-w64-mingw32-"
     when "x86_64-darwin" then "x86_64-apple-darwin-"
     when "x86_64-linux-gnu" then "x86_64-redhat-linux-gnu-"
     when "x86_64-linux-musl" then "x86_64-unknown-linux-musl-"
     else
       raise "CrossRuby.tool: unmatched platform: #{platform}"
     end) + name
  end

  def target_file_format
    case platform
    when "aarch64-linux-gnu", "aarch64-linux-musl" then "elf64-littleaarch64"
    when "arm-linux-gnu", "arm-linux-musl" then "elf32-littlearm"
    when "arm64-darwin" then "Mach-O arm64"
    when "x64-mingw-ucrt", "x64-mingw32" then "pei-x86-64"
    when "x86-linux-gnu", "x86-linux-musl" then "elf32-i386"
    when "x86-mingw32" then "pei-i386"
    when "x86_64-darwin" then "Mach-O 64-bit x86-64" # hmm
    when "x86_64-linux-gnu", "x86_64-linux-musl" then "elf64-x86-64"
    else
      raise "CrossRuby.target_file_format: unmatched platform: #{platform}"
    end
  end

  def dll_ext
    darwin? ? "bundle" : "so"
  end

  def dll_staging_path
    "tmp/#{platform}/stage/lib/#{NOKOGIRI_SPEC.name}/#{minor_ver}/#{NOKOGIRI_SPEC.name}.#{dll_ext}"
  end

  def libruby_dll
    case platform
    when "x64-mingw-ucrt"
      "x64-ucrt-ruby#{api_ver_suffix}.dll"
    when "x64-mingw32"
      "x64-msvcrt-ruby#{api_ver_suffix}.dll"
    when "x86-mingw32"
      "msvcrt-ruby#{api_ver_suffix}.dll"
    else
      raise "CrossRuby.libruby_dll: unmatched platform: #{platform}"
    end
  end

  def allowed_dlls
    case platform
    when MINGW32_PLATFORM_REGEX
      [
        "kernel32.dll",
        "msvcrt.dll",
        "ws2_32.dll",
        "user32.dll",
        "advapi32.dll",
        libruby_dll,
      ]
    when MINGWUCRT_PLATFORM_REGEX
      [
        "kernel32.dll",
        "ws2_32.dll",
        "advapi32.dll",
        "api-ms-win-crt-convert-l1-1-0.dll",
        "api-ms-win-crt-environment-l1-1-0.dll",
        "api-ms-win-crt-filesystem-l1-1-0.dll",
        "api-ms-win-crt-heap-l1-1-0.dll",
        "api-ms-win-crt-locale-l1-1-0.dll",
        "api-ms-win-crt-math-l1-1-0.dll",
        "api-ms-win-crt-private-l1-1-0.dll",
        "api-ms-win-crt-runtime-l1-1-0.dll",
        "api-ms-win-crt-stdio-l1-1-0.dll",
        "api-ms-win-crt-string-l1-1-0.dll",
        "api-ms-win-crt-time-l1-1-0.dll",
        "api-ms-win-crt-utility-l1-1-0.dll",
        libruby_dll,
      ]
    when DARWIN_PLATFORM_REGEX
      [
        "/usr/lib/libSystem.B.dylib",
        "/usr/lib/liblzma.5.dylib",
        "/usr/lib/libobjc.A.dylib",
      ]
    when X86_LINUX_MUSL_PLATFORM_REGEX, ARM_LINUX_MUSL_PLATFORM_REGEX, AARCH_LINUX_MUSL_PLATFORM_REGEX
      [
        "libc.so",
      ]
    when X86_LINUX_GNU_PLATFORM_REGEX
      [
        "libm.so.6",
        "libc.so.6",
        "libdl.so.2", # on old dists only - now in libc
      ].tap do |dlls|
        dlls << "libpthread.so.0" if ver >= "3.2.0"
      end
    when AARCH_LINUX_GNU_PLATFORM_REGEX
      [
        "libm.so.6",
        "libc.so.6",
        "libdl.so.2", # on old dists only - now in libc
        "ld-linux-aarch64.so.1",
      ].tap do |dlls|
        dlls << "libpthread.so.0" if ver >= "3.2.0"
      end
    when ARM_LINUX_GNU_PLATFORM_REGEX
      [
        "libm.so.6",
        "libdl.so.2",
        "libc.so.6",
        "ld-linux-armhf.so.3",
      ].tap do |dlls|
        dlls << "libpthread.so.0" if ver >= "3.2.0"
      end
    else
      raise "CrossRuby.allowed_dlls: unmatched platform: #{platform}"
    end
  end

  def dll_ref_versions
    case platform
    when X86_LINUX_GNU_PLATFORM_REGEX
      { "GLIBC" => "2.17" }
    when AARCH_LINUX_GNU_PLATFORM_REGEX, ARM_LINUX_GNU_PLATFORM_REGEX
      { "GLIBC" => "2.29" }
    when X86_LINUX_MUSL_PLATFORM_REGEX, AARCH_LINUX_MUSL_PLATFORM_REGEX, ARM_LINUX_MUSL_PLATFORM_REGEX
      {}
    else
      raise "CrossRuby.dll_ref_versions: unmatched platform: #{platform}"
    end
  end
end

CROSS_RUBIES = File.read(".cross_rubies").split("\n").filter_map do |line|
  case line
  when /\A([^#]+):([^#]+)/
    CrossRuby.new(Regexp.last_match(1), Regexp.last_match(2))
  end
end

ENV["RUBY_CC_VERSION"] = CROSS_RUBIES.map(&:ver).uniq.join(":")

require "rake_compiler_dock"

def java?
  RUBY_PLATFORM.include?("java")
end

def add_file_to_gem(relative_source_path)
  if relative_source_path.nil? || !File.exist?(relative_source_path)
    raise "Cannot find file '#{relative_source_path}'"
  end

  dest_path = File.join(gem_build_path, relative_source_path)
  dest_dir = File.dirname(dest_path)

  mkdir_p(dest_dir) unless Dir.exist?(dest_dir)
  rm_f(dest_path) if File.exist?(dest_path)
  safe_ln(relative_source_path, dest_path)

  NOKOGIRI_SPEC.files << relative_source_path
end

def gem_build_path
  File.join("pkg", NOKOGIRI_SPEC.full_name)
end

def verify_dll(dll, cross_ruby)
  allowed_imports = cross_ruby.allowed_dlls

  if cross_ruby.windows?
    dump = %x(#{["env", "LANG=C", cross_ruby.tool("objdump"), "-p", dll].shelljoin})

    raise "unexpected file format for generated dll #{dll}" unless /file format #{Regexp.quote(cross_ruby.target_file_format)}\s/.match?(dump)
    raise "export function Init_nokogiri not in dll #{dll}" unless /Table.*\sInit_nokogiri\s/mi.match?(dump)

    # Verify that the DLL dependencies are all allowed.
    actual_imports = dump.scan(/DLL Name: (.*)$/).map { |name| name.first.downcase }.uniq
    unless (actual_imports - allowed_imports).empty?
      raise "unallowed so imports #{actual_imports.inspect} in #{dll} (allowed #{allowed_imports.inspect})"
    end

  elsif cross_ruby.linux?
    dump = %x(#{["env", "LANG=C", cross_ruby.tool("objdump"), "-p", dll].shelljoin})
    nm = %x(#{["env", "LANG=C", cross_ruby.tool("nm"), "-D", dll].shelljoin})

    raise "unexpected file format for generated dll #{dll}" unless /file format #{Regexp.quote(cross_ruby.target_file_format)}\s/.match?(dump)
    raise "export function Init_nokogiri not in dll #{dll}" unless nm.include?(" T Init_nokogiri")

    # Verify that the DLL dependencies are all allowed.
    actual_imports = dump.scan(/NEEDED\s+(.*)/).map(&:first).uniq
    unless (actual_imports - allowed_imports).empty?
      raise "unallowed so imports #{actual_imports.inspect} in #{dll} (allowed #{allowed_imports.inspect})"
    end

    # Verify that the expected so version requirements match the actual dependencies.
    ref_versions_data = dump.scan(/0x[\da-f]+ 0x[\da-f]+ \d+ (\w+)_([\d\.]+)$/i)
    # Build a hash of library versions like {"LIBUDEV"=>"183", "GLIBC"=>"2.17"}
    actual_ref_versions = ref_versions_data.each.with_object({}) do |(lib, ver), h|
      if !h[lib] || ver.split(".").map(&:to_i).pack("C*") > h[lib].split(".").map(&:to_i).pack("C*")
        h[lib] = ver
      end
    end
    if actual_ref_versions != cross_ruby.dll_ref_versions
      raise "unexpected so version requirements #{actual_ref_versions.inspect} in #{dll}"
    end

  elsif cross_ruby.darwin?
    dump = %x(#{["env", "LANG=C", cross_ruby.tool("objdump"), "-p", dll].shelljoin})
    nm = %x(#{["env", "LANG=C", cross_ruby.tool("nm"), "-g", dll].shelljoin})

    raise "unexpected file format for generated dll #{dll}" unless /file format #{Regexp.quote(cross_ruby.target_file_format)}\s/.match?(dump)
    raise "export function Init_nokogiri not in dll #{dll}" unless / T _?Init_nokogiri/.match?(nm)

    # if liblzma is being referenced, let's make sure it's referring
    # to the system-installed file and not the homebrew-installed file.
    ldd = %x(#{["env", "LANG=C", cross_ruby.tool("otool"), "-L", dll].shelljoin})
    if (liblzma_refs = ldd.scan(/^\t([^ ]+) /).map(&:first).uniq.grep(/liblzma/))
      liblzma_refs.each do |ref|
        new_ref = File.join("/usr/lib", File.basename(ref))
        sh(["env", "LANG=C", cross_ruby.tool("install_name_tool"), "-change", ref, new_ref, dll].shelljoin)
      end

      # reload!
      ldd = %x(#{["env", "LANG=C", cross_ruby.tool("otool"), "-L", dll].shelljoin})
    end

    # Verify that the DLL dependencies are all allowed.
    actual_imports = ldd.scan(/^\t([^ ]+) /).map(&:first).uniq
    unless (actual_imports - allowed_imports).empty?
      raise "unallowed so imports #{actual_imports.inspect} in #{dll} (allowed #{allowed_imports.inspect})"
    end
  end
  puts "verify_dll: #{dll}: passed shared library sanity checks"
end

CROSS_RUBIES.each do |cross_ruby|
  task cross_ruby.dll_staging_path do |t| # rubocop:disable Rake/Desc
    verify_dll t.name, cross_ruby
  end
end

namespace "gem" do
  CROSS_RUBIES.find_all { |cr| cr.windows? || cr.linux? || cr.darwin? }.map(&:platform).uniq.each do |plat|
    desc "build native gem for #{plat} platform"
    task plat do
      RakeCompilerDock.sh(<<~EOT, platform: plat, verbose: true)
        ruby -v &&
        gem install bundler --no-document &&
        bundle &&
        bundle exec rake gem:#{plat}:builder MAKE='nice make -j`nproc`'
      EOT
    end

    namespace plat do
      desc "build native gem for #{plat} platform (guest container)"
      task "builder" do
        # use Task#invoke because the pkg/*gem task is defined at runtime
        Rake::Task["native:#{plat}"].invoke
        Rake::Task["pkg/#{NOKOGIRI_SPEC.full_name}-#{Gem::Platform.new(plat)}.gem"].invoke
      end
    end
  end

  desc "build a jruby gem"
  task "jruby" do
    RakeCompilerDock.sh(<<~EOF, rubyvm: "jruby", platform: "jruby", verbose: true)
      gem install bundler --no-document &&
      bundle &&
      bundle exec rake java gem
    EOF
  end

  desc "build native gems for windows"
  multitask "windows" => CROSS_RUBIES.find_all(&:windows?).map(&:platform).uniq

  desc "build native gems for linux"
  multitask "linux" => CROSS_RUBIES.find_all(&:linux?).map(&:platform).uniq

  desc "build native gems for darwin"
  multitask "darwin" => CROSS_RUBIES.find_all(&:darwin?).map(&:platform).uniq
end

if java?
  # append to the existing "java" task defined by rake-compiler
  task "java" do # rubocop:disable Rake/Desc
    # if we're building the java gem, don't build the vanilla gem (see rakelib/package.rake)
    Rake::Task["pkg/#{NOKOGIRI_SPEC.full_name}.gem"].clear
  end

  require "rake/javaextensiontask"
  Rake::JavaExtensionTask.new("nokogiri", NOKOGIRI_SPEC.dup) do |ext|
    # Keep the extension C files because they have docstrings (and Java files don't)
    ext.gem_spec.files.reject! { |path| File.fnmatch?("ext/nokogiri/*.h", path) }
    ext.gem_spec.files.reject! { |path| File.fnmatch?("gumbo-parser/**/*", path) }

    ext.ext_dir = "ext/java"
    ext.lib_dir = "lib/nokogiri"
    ext.source_version = "1.7"
    ext.target_version = "1.7"
    ext.classpath = ext.gem_spec.files.select { |path| File.fnmatch?("**/*.jar", path) }.join(":")
    ext.debug = true if ENV["JAVA_DEBUG"]
  end

  task gem_build_path => [:compile] do
    add_file_to_gem "lib/nokogiri/nokogiri.jar"
  end

  desc "Vendor java dependencies"
  task :vendor_jars do
    require "jars/installer"

    FileUtils.rm(FileList["lib/nokogiri/jruby/*/**/*.jar"], verbose: true)

    jars = Jars::Installer.vendor_jars!("lib/nokogiri/jruby")
    jar_dependencies = jars.sort_by(&:gav).each_with_object({}) do |a, d|
      g, a, v = a.gav.split(":")
      name = [g, a].join(":")
      d[name] = v
    end

    # output this to try to minimize git merge conflicts going forward
    string_rep = "{\n"
    jar_dependencies.each do |ga, v|
      string_rep += "    #{ga.inspect} => #{v.inspect},\n"
    end
    string_rep += "  }"

    File.open("lib/nokogiri/jruby/nokogiri_jars.rb", "a") do |f|
      f.puts
      f.puts <<~EOF
        module Nokogiri
          # generated by the :vendor_jars rake task
          JAR_DEPENDENCIES = #{string_rep}.freeze
          XERCES_VERSION = JAR_DEPENDENCIES["xerces:xercesImpl"]
          NEKO_VERSION = JAR_DEPENDENCIES["net.sourceforge.htmlunit:neko-htmlunit"]
        end
      EOF
    end
  end
else
  require "rake/extensiontask"
  require "yaml"

  dependencies = YAML.load_file("dependencies.yml")

  task gem_build_path do # rubocop:disable Rake/Desc
    NOKOGIRI_SPEC.files.reject! { |path| File.fnmatch?("**/*.{java,jar}", path, File::FNM_EXTGLOB) }

    ["libxml2", "libxslt"].each do |lib|
      version = dependencies[lib]["version"]
      archive = Dir.glob(File.join("ports", "archives", "#{lib}-#{version}.tar.*")).first
      add_file_to_gem(archive)

      patchesdir = File.join("patches", lib)
      patches = %x(#{["git", "ls-files", patchesdir].shelljoin}).split("\n").grep(/\.patch\z/)
      patches.each { |patch| add_file_to_gem patch }

      untracked = Dir[File.join(patchesdir, "*.patch")] - patches
      at_exit do
        untracked.each { |patch| puts "** WARNING: untracked patch file not added to gem: #{patch}" }
      end
    end
  end

  Rake::ExtensionTask.new("nokogiri", NOKOGIRI_SPEC.dup) do |ext|
    ext.source_pattern = "*.{c,cc,cpp,h}"
    ext.gem_spec.files.reject! { |path| File.fnmatch?("**/*.{java,jar}", path, File::FNM_EXTGLOB) }

    ext.lib_dir = File.join(*["lib", "nokogiri", ENV["FAT_DIR"]].compact)
    ext.config_options << ENV["EXTOPTS"] if ENV["EXTOPTS"]
    ext.cross_compile  = true
    ext.cross_platform = CROSS_RUBIES.map(&:platform).uniq
    ext.cross_config_options << "--enable-cross-build"
    ext.cross_compiling do |spec|
      spec.files.reject! { |path| File.fnmatch?("ports/*", path) }
      spec.files.reject! { |path| File.fnmatch?("gumbo-parser/**/*", path) }
      spec.dependencies.reject! { |dep| dep.name == "mini_portile2" }

      # when pre-compiling a native gem, package all the C headers sitting in ext/nokogiri/include
      # which were copied there in the $INSTALLFILES section of extconf.rb.
      # (see scripts/test-gem-file-contents and scripts/test-gem-installation for tests)
      headers_dir = "ext/nokogiri/include"

      ["libxml2", "libxslt"].each do |lib|
        unless File.directory?(File.join(headers_dir, lib))
          raise "#{lib} headers are not present in #{headers_dir}"
        end
      end

      Dir.glob(File.join(headers_dir, "**", "*.h")).each do |header|
        spec.files << header
      end
    end
  end
end
