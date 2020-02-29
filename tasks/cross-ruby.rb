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

ENV["RUBY_CC_VERSION"] ||= CROSS_RUBIES.map(&:ver).uniq.join(":")
