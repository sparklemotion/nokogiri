require "json"

$common_ignore_paths = [
  "*.md",
  "concourse/**",
  "suppressions/**",
  ".github/**",
].to_json
