# frozen_string_literal: true

begin
  require "rdoc/task"

  def rdoc_nokogiri_common_options(rdoc)
    rdoc.rdoc_files
      .include("README.md", "lib/**/*.rb", "ext/**/*.c", "doc/*md")
      .exclude("ext/nokogiri/test_global_handlers.c")
    rdoc.options << "--embed-mixins"
    rdoc.options << "--main=README.md"
  end

  RDoc::Task.new(rdoc: "rdoc", clobber_rdoc: "rdoc:clean", rerdoc: "rdoc:force") do |rdoc|
    rdoc.rdoc_dir = ENV["RDOC_DIR"] || "html"
    rdoc.options << "--show-hash"
    rdoc.options << "--template-stylesheets=misc/rdoc-tweaks.css"
    rdoc_nokogiri_common_options(rdoc)
  end

  RDoc::Task.new(rdoc: "ri", clobber_rdoc: "ri:clean", rerdoc: "ri:force") do |rdoc|
    rdoc.rdoc_dir = ENV["RI_DIR"] || "ri"
    rdoc.generator = "ri"
    rdoc_nokogiri_common_options(rdoc)
  end

  task clean: "rdoc:clean" # rubocop:disable Rake/Desc
rescue LoadError => e
  warn("WARNING: rdoc is not available in this environment: #{e}")
end
