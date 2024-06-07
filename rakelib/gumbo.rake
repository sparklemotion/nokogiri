# frozen_string_literal: true

namespace "gumbo" do
  # We want to run the gumbo test suite using exactly the same compiled gumbo-parser
  # that Nokogiri uses.
  #
  # To that end, we first need to get the Rake ExtensionTask to run extconf.rb which will
  # run the gumbo-parser's configure script. We don't want to compile the extension
  # at this point, so we make `gumbo:test` depend on the Nokogiri Makefile.

  gtest_pkg = "gumbo-parser/googletest"
  host = RbConfig::CONFIG["host_alias"].empty? ? RbConfig::CONFIG["host"] : RbConfig::CONFIG["host_alias"]
  host = host.gsub("i386", "i686")
  nokogiri_makefile = File.join("tmp/#{RUBY_PLATFORM}/nokogiri/#{RUBY_VERSION}/Makefile")
  gumbotest_builddir = "tmp/#{RUBY_PLATFORM}/nokogiri/#{RUBY_VERSION}/tmp/#{host}/ports/libgumbo/1.0.0-nokogiri/libgumbo-1.0.0-nokogiri"
  gumbotest_configure = File.absolute_path("gumbo-parser/configure")

  file gtest_pkg do
    sh(<<~EOF)
      curl -L https://github.com/google/googletest/archive/release-1.8.0.tar.gz | \
        tar zxf - --strip-components 1 -C gumbo-parser googletest-release-1.8.0/googletest
    EOF
  end

  file gumbotest_configure => gtest_pkg do
    sh("autoreconf", "-fiv", chdir: "gumbo-parser")
  end

  desc "Run the gumbo parser test suite"
  task "test" => nokogiri_makefile do
    sh("make", "-j2", "-C", gumbotest_builddir, "check")
  end

  # Make sure the libgumbo configure script is created before trying to compile the extension.
  file nokogiri_makefile => gumbotest_configure

  CLOBBER.add(gtest_pkg)
  CLOBBER.add(gumbotest_configure)
  CLOBBER.add("gumbo-parser/Makefile.in")
  CLOBBER.add("gumbo-parser/configure")
  CLOBBER.add("gumbo-parser/src/Makefile.in")
  CLOBBER.add("gumbo-parser/test/Makefile.in")
end

desc "Run the gumbo parser test suite"
task "gumbo" => "gumbo:test"
