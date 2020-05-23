require "json"

$common_ignore_paths = [
  "*.md",
  "concourse/**",
  "suppressions/**",
  ".github/**",
  "Vagrantfile",
].to_json

cross_rubies_path = File.join(File.dirname(__FILE__), "..", ".cross_rubies")
$native_ruby_versions = File.read(cross_rubies_path).split("\n").map { |line| line.split(":").first.split(".").take(2).join(".") }.uniq.sort
