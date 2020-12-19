require "json"

cross_rubies_path = File.join(File.dirname(__FILE__), "..", ".cross_rubies")
$native_ruby_versions = File.read(cross_rubies_path).split("\n").map do |line|
  line.split(":").first.split(".").take(2).join(".")
end.uniq.sort
