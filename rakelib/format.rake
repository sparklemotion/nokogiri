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
      ]
    end

    def c_files
      FileList.new("ext/**/*.[ch]")
    end

    def java_files
      FileList.new("ext/**/*.java")
    end
  end
end

namespace "format" do
  desc "Format Nokogiri's C code"
  task "c" do
    AstyleHelper.run(AstyleHelper.c_files)
  end

  desc "Format Nokogiri's Java code"
  task "java" do
    AstyleHelper.run(AstyleHelper.java_files)
  end

  CLEAN.add(AstyleHelper.c_files.map { |f| "#{f}.orig" })
  CLEAN.add(AstyleHelper.java_files.map { |f| "#{f}.orig" })
end

task "format" => ["format:c", "format:java"]
