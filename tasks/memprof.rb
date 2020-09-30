# frozen_string_literal: true

namespace :memprof do
  require "memory_profiler"
  module NokoMemProf
    def self.profile abs_path
      puts "\nTesting with Nokogiri v" + Nokogiri::VERSION.to_s
      puts
      contents = File.read abs_path
      MemoryProfiler.report do
        1000.times { yield contents  }
      end.pretty_print(scale_bytes: true, normalize_paths: true)
    end
  end


  task :html_doc do
    require "nokogiri"

    abs_path = File.expand_path("../test/files/fixture.html", __dir__)
    NokoMemProf.profile(abs_path) do |contents|
      Nokogiri::HTML::Document.parse(contents).to_html
    end
  end

  task :html_doc_frag do
    require "nokogiri"

    abs_path = File.expand_path("../test/files/fixture_body.html", __dir__)
    NokoMemProf.profile(abs_path) do |contents|
      Nokogiri::HTML::DocumentFragment.parse(contents).to_html
    end
  end
end
