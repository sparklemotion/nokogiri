Gem::Specification.new do |s|
  s.name = %q{nokogiri}
  s.version = "0.0.0.20080910014248"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Aaron Patterson"]
  s.date = %q{2008-09-10}
  s.description = %q{FIX (describe your package)}
  s.email = ["aaronp@rubyforge.org"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.txt", "Rakefile", "idl/COPYRIGHT.html", "idl/dom.idl", "lib/nokogiri.rb", "lib/nokogiri/dl/xml.rb", "lib/nokogiri/dl/xslt.rb", "lib/nokogiri/xml/document.rb", "lib/nokogiri/generated_interface.rb", "lib/nokogiri/html.rb", "lib/nokogiri/xml/node.rb", "lib/nokogiri/xml/node_set.rb", "lib/nokogiri/version.rb", "lib/nokogiri/xml.rb", "lib/nokogiri/xslt.rb", "lib/nokogiri/xslt/stylesheet.rb", "nokogiri.gemspec", "test/files/staff.xml", "test/files/staff.xslt", "test/files/tlm.html", "test/helper.rb", "test/test_document.rb", "test/test_node.rb", "test/test_node_set.rb", "test/test_nokogiri.rb", "test/test_xslt.rb"]
  s.has_rdoc = true
  s.homepage = %q{FIX (url)}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{nokogiri}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{FIX (describe your package)}
  s.test_files = ["test/test_node.rb", "test/test_nokogiri.rb", "test/test_xslt.rb", "test/test_document.rb", "test/test_node_set.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_development_dependency(%q<hoe>, [">= 1.7.0"])
    else
      s.add_dependency(%q<hoe>, [">= 1.7.0"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 1.7.0"])
  end
end
