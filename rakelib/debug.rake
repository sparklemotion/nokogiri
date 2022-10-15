# frozen_string_literal: true

task :java_debug do # rubocop:disable Rake/Desc
  ENV["JRUBY_OPTS"] = "#{ENV["JRUBY_OPTS"]} --debug --dev"
  if ENV["JAVA_DEBUG"]
    ENV["JAVA_OPTS"] = "-Xdebug -Xrunjdwp:transport=dt_socket,address=8000,server=y,suspend=y"
  end
end
task test: :java_debug # rubocop:disable Rake/Desc
