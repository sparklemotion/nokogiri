#
#  this file monkeypatches hoe to restore SimpleCov working properly with minitest
#
#  we can delete this file once https://github.com/seattlerb/hoe/pull/102 is merged
#
require "hoe/test"
require "minitest/test_task"

module Hoe::Test
  def define_test_tasks
    default_tasks = []

    task :test

    if File.directory? "test"
      case testlib
      when :minitest
        require "minitest/test_task" # currently in hoe, but will move

        test_prelude = self.test_prelude
        Minitest::TestTask.create :test do |t|
          t.test_prelude = test_prelude
          t.libs += Hoe.include_dirs.uniq
        end
      when :testunit
        desc "Run the test suite. Use FILTER or TESTOPTS to add flags/args."
        task :test do
          ruby make_test_cmd
        end

        desc "Print out the test command. Good for profiling and other tools."
        task :test_cmd do
          puts make_test_cmd
        end

        desc "Show which test files fail when run alone."
        task :test_deps do
          tests = Dir[*self.test_globs].uniq

          paths = %w[bin lib test].join(File::PATH_SEPARATOR)
          null_dev = Hoe::WINDOZE ? "> NUL 2>&1" : "> /dev/null 2>&1"

          tests.each do |test|
            unless system "ruby -I#{paths} #{test} #{null_dev}"
              puts "Dependency Issues: #{test}"
            end
          end
        end

        if testlib == :minitest
          desc "Show bottom 25 tests wrt time."
          task "test:slow" do
            sh "rake TESTOPTS=-v | sort -n -k2 -t= | tail -25"
          end
        end
      when :none
        # do nothing
      else
        warn "Unsupported? Moving to Minitest::TestTask. Let me know if you use this!"
      end

      desc "Run the test suite using multiruby."
      task :multi do
        skip = with_config do |config, _|
          config["multiruby_skip"] + self.multiruby_skip
        end

        ENV["EXCLUDED_VERSIONS"] = skip.join(":")
        system "multiruby -S rake"
      end

      default_tasks << :test
    end

    if File.directory? "spec"
      found = try_loading_rspec2 || try_loading_rspec1

      if found
        default_tasks << :spec
      else
        warn "Found spec dir, but couldn't load rspec (1 or 2) task. skipping."
      end
    end

    desc "Run the default task(s)."
    task :default => default_tasks

    desc "Run ZenTest against the package."
    task :audit do
      libs = %w[lib test ext].join(File::PATH_SEPARATOR)
      sh "zentest -I=#{libs} #{spec.files.grep(/^(lib|test)/).join(" ")}"
    end
  end
end

module Minitest
  class TestTask < Rake::TaskLib
    def make_test_cmd(globs = test_globs)
      tests = []
      tests.concat Dir[*globs].sort.shuffle # TODO: SEED -> srand first?
      tests.map! { |f| %(require "#{f}") }

      runner = []
      runner << test_prelude if test_prelude
      runner << framework
      runner.concat tests
      runner = runner.join "; "

      args = []
      args << "-I#{libs.join(File::PATH_SEPARATOR)}" unless libs.empty?
      args << "-w" if warning
      args << "-e"
      args << "'#{runner}'"
      args << "--"
      args << extra_args.map(&:shellescape)

      args.join " "
    end
  end
end
