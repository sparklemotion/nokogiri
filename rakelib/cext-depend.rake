# frozen_string_literal: true

require "set"

namespace "cext" do
  desc "Regenerate C extension dependencies in #{File.dirname(NOKOGIRI_SPEC.extensions.first)}/depend"
  task :depend do
    # this task requires the `makedepend` utility
    NOKOGIRI_SPEC.extensions.each do |extconf|
      ext_dir = File.dirname(extconf)
      Dir.chdir(ext_dir) do
        puts "(in #{ext_dir})"
        File.exist?("depend") || FileUtils.touch("depend")
        sh "makedepend -f depend -Y -I. *.c 2> /dev/null"
        dep = File.read("depend")
        dep.gsub!(%r{ \./}, " $(srcdir)/")
        File.write("depend", dep)
      end
    end
  end
end
