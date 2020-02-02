namespace "changelog" do
  CHANGELOG_NAME = HOE.history_file
  CHANGELOG_PATH = File.join(File.dirname(__FILE__), "..", CHANGELOG_NAME)

  desc "link issues and usernames in #{CHANGELOG_NAME}"
  task "linkify" do
    # this task is idempotent
    changelog = File.read(CHANGELOG_PATH)

    github_issue_regex = /
      \#([[:digit:]]+)  # issue number, like '#1234'
      (?!\]\()          # not already in a markdown hyperlink
      (?![[[:digit:]]]) # don't truncate the issue number to meet the previous negative lookahead
    /x
    changelog.gsub!(github_issue_regex, "[#\\1](#{HOE.urls["bugs"]}/\\1)")

    # see https://github.com/shinnn/github-username-regex
    github_user_regex = /
      @([[:alnum:]](?:[[:alnum:]]|-(?=[[:alnum:]])){0,38}) # username, like "@flavorjones"
      (?!\]\()                                             # not already in a markdown hyperlink
      (?![[[:alnum:]]]) # don't truncate the username to meet the previous negative lookahead
    /x
    changelog.gsub!(github_user_regex, "[@\\1](https://github.com/\\1)")
    changelog.gsub!(github_user_regex, "[@\\1](https://github.com/\\1)")
    changelog.gsub!(github_user_regex, "[@\\1](https://github.com/\\1)")

    File.open(CHANGELOG_PATH, "w") { |f| f.write changelog }
  end
end
