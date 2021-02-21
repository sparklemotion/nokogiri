require "hoe/markdown"
Hoe::Markdown::Standalone.new("nokogiri").define_markdown_tasks("CHANGELOG.md", "CONTRIBUTING.md")
