desc "Set environment variables to build and/or test with debug options"
task :debug do
  ENV["NOKOGIRI_DEBUG"] = "true"
  ENV["CFLAGS"] ||= ""
  ENV["CFLAGS"] += " -DDEBUG"
end

task :java_debug do # rubocop:disable Rake/Desc
  ENV["JRUBY_OPTS"] = "#{ENV["JRUBY_OPTS"]} --debug --dev"
  if ENV["JAVA_DEBUG"]
    ENV["JAVA_OPTS"] = "-Xdebug -Xrunjdwp:transport=dt_socket,address=8000,server=y,suspend=y"
  end
end
task :test => :java_debug # rubocop:disable Rake/Desc
