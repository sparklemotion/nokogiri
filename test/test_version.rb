require "helper"
require "rbconfig"
require "json"

module TestVersionInfoTests
  #
  #  This module is mixed into test classes below so that the tests
  #  are validated when `nokogiri.rb` is required and when
  #  `nokogiri/version.rb` is required. See #1896 for background.
  #
  def test_version_info_for_xerces
    skip "xerces is only used for JRuby" unless Nokogiri.jruby?
    assert_equal @version_info["xerces"], Nokogiri::VERSION_INFO["xerces"]
  end

  def test_version_info_for_nekohtml
    skip "nekohtml is only used for JRuby" unless Nokogiri.jruby?
    assert_equal @version_info["nekohtml"], Nokogiri::VERSION_INFO["nekohtml"]
  end

  def test_version_info_for_libxml
    skip "libxml2 is only used for CRuby" unless Nokogiri.uses_libxml?
    assert_equal @version_info["libxml"]["compiled"], Nokogiri::LIBXML_VERSION
    assert @version_info["libxml"]["loaded"]
    assert @version_info["libxml"]["source"]
  end

  def test_version_info_for_libxslt
    skip "libxslt is only used for CRuby" unless Nokogiri.uses_libxml?
    assert_equal @version_info["libxslt"]["compiled"], Nokogiri::LIBXSLT_COMPILED_VERSION
    assert @version_info["libxslt"]["loaded"]
    assert @version_info["libxslt"]["source"]
  end
end

class TestVersionInfo
  RUBYEXEC = File.join(RbConfig::CONFIG["bindir"], RbConfig::CONFIG["RUBY_INSTALL_NAME"])
  ROOTDIR = File.expand_path(File.join(File.dirname(__FILE__), ".."))

  class Base < Nokogiri::TestCase
    def setup
      super
      version_info = Dir.chdir(ROOTDIR) do
        `#{RUBYEXEC} -Ilib -rjson -r#{@require_me} -e 'puts Nokogiri::VERSION_INFO.to_json'`
      end
      @version_info = JSON.parse version_info
    end
  end

  class RequireNokogiri < TestVersionInfo::Base
    include TestVersionInfoTests

    def setup
      @require_me = "nokogiri"
      super
    end
  end

  class RequireVersionFileOnly < TestVersionInfo::Base
    include TestVersionInfoTests

    def setup
      @require_me = "nokogiri/version"
      super
    end
  end
end
