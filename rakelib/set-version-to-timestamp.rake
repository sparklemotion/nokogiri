# frozen_string_literal: true
desc "Temporarily set Nokogiri::VERSION to a unique timestamp"
task "set-version-to-timestamp" do
  # this task is used by concourse/tasks/gem-test/gem-build.sh
  # to test building, packaging, and installing a Nokogiri gem
  version = Time.now.strftime("%Y.%m%d.%H%M")

  version_file_path = File.join(File.dirname(__FILE__), "..", "lib/nokogiri/version/constant.rb")
  version_file_contents = File.read(version_file_path)
  unless version_file_contents.gsub!(/^\s*VERSION\s*=.*/, "VERSION = \"#{version}\"")
    raise("Could not hack the VERSION constant")
  end

  File.open(version_file_path, "w") { |f| f.write(version_file_contents) }

  puts "NOTE: wrote version as \"#{version}\""
end
