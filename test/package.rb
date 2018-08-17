# These tests are only run by `rake test:package` and are intended to test the
# installed gem.
#
# This isn't called test_package.rb to prevent it being picked up by Hoe as a
# normal test.

require 'minitest/autorun'

class PackageTest < Minitest::Test
  def setup
    ext_dir = Gem::Specification.find_by_name('nokogiri').extension_dir
    @headers_dir = File.join(ext_dir, 'nokogiri/include')
  end

  def test_nokogiri_headers
    assert(File.directory?(@headers_dir))
    installed_headers = Dir.chdir(@headers_dir) do
      Dir['*.h'].sort!
    end
    source_headers = Dir.chdir(File.expand_path('../../ext/nokogiri', __FILE__)) do
      Dir['*.h'].sort!
    end
    assert_equal(source_headers, installed_headers)
  end

  def test_packaged_headers
    require 'nokogiri'
    if Nokogiri::VERSION_INFO.has_key?('libxml') and
       Nokogiri::VERSION_INFO['libxml']['source'] == 'packaged'
      # Look for some files from libxml2 and libxslt
      %w[libxml2/libxml/tree.h libxslt/xslt.h libexslt/exslt.h].each do |header|
        assert(File.file?(File.join(@headers_dir, header)))
      end
    else
      # Make sure the headers are not installed when they're not packaged.
      %w[libxml2 libxslt libexslt].each do |dir|
        refute(File.directory?(File.join(@headers_dir, dir)))
      end
    end
  end
end
# vim: set sw=2 sts=2 ts=8 et:
