CrossRuby = Struct.new(:version, :host) do
  def ver
    @ver ||= version[/\A[^-]+/]
  end

  def minor_ver
    @minor_ver ||= ver[/\A\d\.\d(?=\.)/]
  end

  def api_ver_suffix
    case minor_ver
    when nil
      raise "unsupported version: #{ver}"
    else
      minor_ver.delete(".") << "0"
    end
  end

  def platform
    @platform ||= case host
      when /\Ax86_64.*mingw32/
        "x64-mingw32"
      when /\Ai[3-6]86.*mingw32/
        "x86-mingw32"
      when /\Ax86_64.*linux/
        "x86_64-linux"
      when /\Ai[3-6]86.*linux/
        "x86-linux"
      else
        raise "unsupported host: #{host}"
      end
  end

  WINDOWS_PLATFORM_REGEX = /mingw|mswin/
  MINGW32_PLATFORM_REGEX = /mingw32/
  LINUX_PLATFORM_REGEX = /linux/

  def windows?
    !!(platform =~ WINDOWS_PLATFORM_REGEX)
  end

  def tool(name)
    (@binutils_prefix ||= case platform
      when "x64-mingw32"
        "x86_64-w64-mingw32-"
      when "x86-mingw32"
        "i686-w64-mingw32-"
      when "x86_64-linux"
        "x86_64-linux-gnu-"
      when "x86-linux"
        "i686-linux-gnu-"
      end) + name
  end

  def target
    case platform
    when "x64-mingw32"
      "pei-x86-64"
    when "x86-mingw32"
      "pei-i386"
    end
  end

  def libruby_dll
    case platform
    when "x64-mingw32"
      "x64-msvcrt-ruby#{api_ver_suffix}.dll"
    when "x86-mingw32"
      "msvcrt-ruby#{api_ver_suffix}.dll"
    end
  end

  def dlls
    case platform
    when MINGW32_PLATFORM_REGEX
      [
        "kernel32.dll",
        "msvcrt.dll",
        "ws2_32.dll",
        *(case
        when ver >= "2.0.0"
          "user32.dll"
        end),
        libruby_dll,
      ]
    when LINUX_PLATFORM_REGEX
      [
        "libm.so.6",
        *(case
        when ver < "2.6.0"
          "libpthread.so.0"
        end),
        "libc.so.6",
      ]
    end
  end

  def dll_ref_versions
    case platform
    when LINUX_PLATFORM_REGEX
      { "GLIBC" => "2.17" }
    end
  end
end

CROSS_RUBIES = File.read(".cross_rubies").lines.flat_map do |line|
  case line
  when /\A([^#]+):([^#]+)/
    CrossRuby.new($1, $2)
  else
    []
  end
end

ENV["RUBY_CC_VERSION"] = CROSS_RUBIES.map(&:ver).uniq.join(":")

require "rake_compiler_dock"

def verify_dll(dll, cross_ruby)
  dll_imports = cross_ruby.dlls
  dump = `#{["env", "LANG=C", cross_ruby.tool("objdump"), "-p", dll].shelljoin}`
  if cross_ruby.windows?
    raise "unexpected file format for generated dll #{dll}" unless /file format #{Regexp.quote(cross_ruby.target)}\s/ === dump
    raise "export function Init_nokogiri not in dll #{dll}" unless /Table.*\sInit_nokogiri\s/mi === dump

    # Verify that the expected DLL dependencies match the actual dependencies
    # and that no further dependencies exist.
    dll_imports_is = dump.scan(/DLL Name: (.*)$/).map(&:first).map(&:downcase).uniq
    if dll_imports_is.sort != dll_imports.sort
      raise "unexpected dll imports #{dll_imports_is.inspect} in #{dll}"
    end
  else
    # Verify that the expected so dependencies match the actual dependencies
    # and that no further dependencies exist.
    dll_imports_is = dump.scan(/NEEDED\s+(.*)/).map(&:first).uniq
    if dll_imports_is.sort != dll_imports.sort
      raise "unexpected so imports #{dll_imports_is.inspect} in #{dll} (expected #{dll_imports.inspect})"
    end

    # Verify that the expected so version requirements match the actual dependencies.
    dll_ref_versions_list = dump.scan(/0x[\da-f]+ 0x[\da-f]+ \d+ (\w+)_([\d\.]+)$/i)
    # Build a hash of library versions like {"LIBUDEV"=>"183", "GLIBC"=>"2.17"}
    dll_ref_versions_is = dll_ref_versions_list.each.with_object({}) do |(lib, ver), h|
      if !h[lib] || ver.split(".").map(&:to_i).pack("C*") > h[lib].split(".").map(&:to_i).pack("C*")
        h[lib] = ver
      end
    end
    if dll_ref_versions_is != cross_ruby.dll_ref_versions
      raise "unexpected so version requirements #{dll_ref_versions_is.inspect} in #{dll}"
    end
  end
  puts "verify_dll: #{dll}: passed shared library sanity checks"
end

CROSS_RUBIES.each do |cross_ruby|
  task "tmp/#{cross_ruby.platform}/stage/lib/nokogiri/#{cross_ruby.minor_ver}/nokogiri.so" do |t|
    verify_dll t.name, cross_ruby
  end
end

namespace "gem" do
  CROSS_RUBIES.map(&:platform).uniq.each do |plat|
    desc "build native fat binary gems for windows and linux"
    multitask "native" => plat

    desc "build native gem for #{plat} platform\nthis trampolines into the rake-compiler-dock guest"
    task plat do
      # TODO remove `find` after https://github.com/rake-compiler/rake-compiler/pull/171 is shipped
      RakeCompilerDock.sh <<-EOT, platform: plat
        gem install bundler --no-document &&
        bundle &&
        find /usr/local/rvm/gems -name extensiontask.rb | while read f ; do sudo sed -i 's/callback.call(spec) if callback/@cross_compiling.call(spec) if @cross_compiling/' $f ; done &&
        rake gem:#{plat}:guest MAKE='nice make -j`nproc`'
      EOT
    end

    namespace plat do
      desc "(within docker guest) build native gem for #{plat} platform\nthis should only be called within a rake-compiler-dock image"
      task "guest" do
        # use Task#invoke because the pkg/*gem task is defined at runtime
        Rake::Task["native:#{plat}"].invoke
        Rake::Task["pkg/#{HOE.spec.full_name}-#{plat}.gem"].invoke
      end
    end
  end

  desc "build native fat binary gems for windows"
  multitask "windows" => CROSS_RUBIES.map(&:platform).uniq.grep(WINDOWS_PLATFORM_REGEX)

  desc "build native fat binary gems for linux"
  multitask "linux" => CROSS_RUBIES.map(&:platform).uniq.grep(LINUX_PLATFORM_REGEX)

  desc "build a jruby gem with docker"
  task "jruby" do
    RakeCompilerDock.sh "gem install bundler --no-document && bundle && rake java gem", rubyvm: "jruby"
  end
end
