# coding: utf-8
# frozen_string_literal: true
namespace "format" do
  def assert_astyle
    require "mkmf"
    find_executable("astyle") || raise("Could not find command 'astyle'")
  end

  def astyle_args
    # See http://astyle.sourceforge.net/astyle.html
    # These choices are just what I happen to like,
    # but I'm the one writing most of the code these days, so ¯\_(ツ)_/¯
    [
      # indentation
      "--indent=spaces=2",

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

  def astyle_c_files
    FileList.new("ext/nokogiri/*.[ch]")
  end

  def astyle_java_files
    FileList.new("ext/java/nokogiri/**/*.java")
  end

  desc "Format Nokogiri's C code"
  task "c" do
    assert_astyle
    command = ["astyle", astyle_args, astyle_c_files].flatten.shelljoin
    system(command)
  end

  desc "Format Nokogiri's Java code"
  task "java" do
    assert_astyle
    command = ["astyle", astyle_args, astyle_java_files].flatten.shelljoin
    system(command)
  end

  CLEAN.add(astyle_c_files.map { |f| "#{f}.orig" })
  CLEAN.add(astyle_java_files.map { |f| "#{f}.orig" })
  CLEAN.add("mkmf.log") # because of find_executable
end

task "format" => ["format:c", "format:java"]
