require "set"

desc "Regenerate C extension dependencies in #{File.dirname(HOE.spec.extensions.first)}/depend"
task :depend do
  # this task requires the `makedepend` utility
  

  ext_dir = File.dirname(HOE.spec.extensions.first)
  Dir.chdir(ext_dir) do
    File.open("depend", "w") do |depend|
      deps = {}

      makedepend = `makedepend -f- -Y -I. *.c 2> /dev/null`
      makedepend.split("\n").each do |line|
        next unless line =~ /:/
        obj_file = line[/(.*):/, 1]
        deps[obj_file] ||= Set.new
        line[/:(.*)/, 1].split.each do |dep|
          deps[obj_file].add dep
        end
      end

      deps.keys.sort.each do |obj_file|
        obj_deps = deps[obj_file].to_a.sort
        depend.print "#{obj_file}: "
        obj_deps.each_with_index do |obj_dep, j|
          depend.print obj_dep
          if j+1 < obj_deps.length
            depend.print " \\\n#{" " * obj_file.length}  "
          end
        end
        depend.puts
        depend.puts
      end
    end
  end
end
