require "yard"
YARD::Rake::YardocTask.new("doc") # options are set in .yardopts
CLEAN.add("doc")
CLOBBER.add(".yardoc")
