linkify_tasks = []

namespace "docs:linkify" do
  CHANGELOG_PATH = File.expand_path(File.join(File.dirname(__FILE__), "..", HOE.history_file))
  ROADMAP_PATH = File.expand_path(File.join(File.dirname(__FILE__), "..", "ROADMAP.md"))

  [CHANGELOG_PATH, ROADMAP_PATH].each do |docfile_path|
    docfile_name = File.basename(docfile_path)
    taskname = docfile_name.downcase.split(".").first

    # this task is idempotent
    desc "link issues and usernames in #{docfile_name}"
    task taskname do
      puts "linkifying #{docfile_path} ..."
      docs = File.read(docfile_path)

      github_issue_regex = /
        \#([[:digit:]]+)  # issue number, like '#1234'
        (?!\]\()          # not already in a markdown hyperlink
        (?![[[:digit:]]]) # don't truncate the issue number to meet the previous negative lookahead
      /x
      docs.gsub!(github_issue_regex, "[#\\1](#{HOE.urls["bugs"]}/\\1)")

      github_link_regex = %r{
        (?<!\]\()          # not already in a markdown hyperlink
        #{HOE.urls["bugs"]}/([[:digit:]]+)
        (?![[[:digit:]]]) # don't truncate the issue number to meet the previous negative lookahead
      }x
      docs.gsub!(github_link_regex, "[#\\1](#{HOE.urls["bugs"]}/\\1)")

      github_link_regex = %r{
        (?<!\]\()          # not already in a markdown hyperlink
        #{HOE.urls["bugs"].gsub("issues", "pull")}/([[:digit:]]+)
        (?![[[:digit:]]]) # don't truncate the issue number to meet the previous negative lookahead
      }x
      docs.gsub!(github_link_regex, "[PR#\\1](#{HOE.urls["bugs"]}/\\1)")

      # see https://github.com/shinnn/github-username-regex
      github_user_regex = /
        @([[:alnum:]](?:[[:alnum:]]|-(?=[[:alnum:]])){0,38}) # username, like "@flavorjones"
        (?!\]\()                                             # not already in a markdown hyperlink
        (?![[[:alnum:]]]) # don't truncate the username to meet the previous negative lookahead
      /x
      docs.gsub!(github_user_regex, "[@\\1](https://github.com/\\1)")

      File.open(docfile_path, "w") { |f| f.write docs }
    end
    linkify_tasks << "docs:linkify:#{taskname}"
  end
end

desc "link issues and usernames in doc files"
task "docs:linkify" => linkify_tasks
