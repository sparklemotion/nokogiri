require "yard"
YARD::Rake::YardocTask.new("doc") do |t|
 t.files = ["lib/**/*.rb", "ext/nokogiri/*.c"]
 t.options = ["--embed-mixins", "--main=README.md"]
end
