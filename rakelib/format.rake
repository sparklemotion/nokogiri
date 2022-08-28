# coding: utf-8
# frozen_string_literal: true

module AstyleHelper
  class << self
    def run(files)
      assert
      command = ["astyle", args, files].flatten.shelljoin
      system(command)
    end

    def assert
      require "mkmf"
      find_executable0("astyle") || raise("Could not find command 'astyle'")
    end

    def args
      # See http://astyle.sourceforge.net/astyle.html
      # These choices are just what I happen to like,
      # but I'm the one writing most of the code these days, so ¯\_(ツ)_/¯
      [
        # indentation
        "--indent=spaces=2",
        "--indent-switches",

        # brackets
        "--style=1tbs",
        "--keep-one-line-blocks",

        # where do we want spaces
        "--unpad-paren",
        "--pad-header",
        "--pad-oper",
        "--pad-comma",

        # "void *pointer" and not "void* pointer"
        "--align-pointer=name",

        # function definitions and declarations
        "--break-return-type",
        "--attach-return-type-decl",

        # gotta set a limit somewhere
        "--max-code-length=120",

        # be quiet about files that haven't changed
        "--formatted",
        "--verbose",
      ]
    end

    def c_files
      NOKOGIRI_SPEC.files.grep(%r{ext/nokogiri/.*\.[ch]\Z})
    end

    def java_files
      NOKOGIRI_SPEC.files.grep(%r{ext/java/.*\.java\Z})
    end
  end
end

namespace "format" do
  desc "Format Nokogiri's C code"
  task "c" do
    puts "Running astyle on C files ..."
    AstyleHelper.run(AstyleHelper.c_files)
  end

  desc "Format Nokogiri's Java code"
  task "java" do
    puts "Running astyle on Java files ..."
    AstyleHelper.run(AstyleHelper.java_files)
  end

  desc "Format Nokogiri's Ruby code"
  task "ruby" => "rubocop:check:autocorrect"

  desc "Regenerate tables of contents in some files"
  task "toc" do
    require "mkmf"
    if find_executable0("markdown-toc")
      sh "markdown-toc --maxdepth=2 -i CONTRIBUTING.md"
      sh "markdown-toc -i LICENSE-DEPENDENCIES.md"
    else
      puts "WARN: cannot find markdown-toc, skipping. install with 'npm install markdown-toc'"
    end
  end

  CLEAN.add(AstyleHelper.c_files.map { |f| "#{f}.orig" })
  CLEAN.add(AstyleHelper.java_files.map { |f| "#{f}.orig" })
end

task "format" => ["format:c", "format:java", "format:ruby", "format:toc"]
