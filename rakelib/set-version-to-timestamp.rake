task "set-version-to-timestamp" do
  version = Time.now.strftime("%Y.%m%d.%H%M")

  version_file_path = File.join(File.dirname(__FILE__), "..", "lib/nokogiri/version.rb")
  version_file_contents = File.read(version_file_path)
  version_file_contents.gsub!(/^\s*VERSION\s*=.*/, "VERSION = \"#{version}\"")

  File.open(version_file_path, "w") { |f| f.write version_file_contents }

  puts "NOTE: wrote version as \"#{version}\""
end
