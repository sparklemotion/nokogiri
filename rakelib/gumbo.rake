# frozen_string_literal: true

namespace "gumbo" do
  gtest_pkg = "gumbo-parser/googletest"
  gtest_lib = File.join(gtest_pkg, "make/gtest_main.a")

  file gtest_lib => gtest_pkg do
    sh("make -C gumbo-parser/googletest/make gtest_main.a")
  end

  file gtest_pkg do
    sh(<<~EOF)
      curl -L https://github.com/google/googletest/archive/release-1.8.0.tar.gz | \
        tar zxf - --strip-components 1 -C gumbo-parser googletest-release-1.8.0/googletest
    EOF
  end

  desc "Run the gumbo parser test suite"
  task "test" => gtest_lib do
    sh("make -j2 -C gumbo-parser")
  end

  desc "Clean up after the gumbo parser test suite"
  task "clean" do
    sh("make -j2 -C gumbo-parser clean")
  end

  CLOBBER.add(gtest_pkg)
end

desc "Run the gumbo parser test suite"
task "gumbo" => "gumbo:test"

task "clean" => "gumbo:clean" # rubocop:disable Rake/Desc
