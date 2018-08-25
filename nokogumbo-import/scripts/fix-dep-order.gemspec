Gem::Specification.new do |s|
  s.name = 'fix-dep-order'
  s.version = '0.1.0'
  s.author = 'Stephen Checkoway <s@pahtak.org>'
  s.files = []
  s.summary = 'Fix Nokogiri not depending on pkg-config'
  s.add_runtime_dependency 'pkg-config'
end
