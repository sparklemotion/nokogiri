# frozen_string_literal: true

require "hoe/markdown"
Hoe::Markdown::Standalone.new("nokogiri").define_markdown_tasks("CHANGELOG.md", "CONTRIBUTING.md")

task "format" => ["markdown:linkify"]
