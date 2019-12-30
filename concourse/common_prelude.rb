require "json"

$common_ignore_paths = [
  "CHANGELOG.md",
  "README.md",
  "concourse/**",
  "suppressions/**",
  ".github/**",
].to_json
