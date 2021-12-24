# frozen_string_literal: true

desc "Temporarily set Nokogiri::VERSION to a unique timestamp"
task "set-version-to-timestamp" do
  # this task is used by scripts/test-gem-build
  # to test building, packaging, and installing a Nokogiri gem
  version_constant_re = /^\s*VERSION\s*=\s*["'](.*)["']$/

  version_file_path = File.join(File.dirname(__FILE__), "..", "lib/nokogiri/version/constant.rb")
  version_file_contents = File.read(version_file_path)

  current_version_string = version_constant_re.match(version_file_contents)[1]
  current_version = Gem::Version.new(current_version_string)

  fake_version = Gem::Version.new(format("%s.test.%s", current_version.bump, Time.now.strftime("%Y.%m%d.%H%M")))

  unless version_file_contents.gsub!(version_constant_re, "  VERSION = \"#{fake_version}\"")
    raise("Could not hack the VERSION constant")
  end

  File.write(version_file_path, version_file_contents)

  puts "NOTE: wrote version as \"#{fake_version}\""
end
