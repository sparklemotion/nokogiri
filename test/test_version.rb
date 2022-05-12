# frozen_string_literal: true

require "helper"
require "rbconfig"
require "json"

module TestVersionInfoTests
  VERSION_MATCH = /\d+\.\d+\.\d+/
  #
  #  This module is mixed into test classes below so that the tests
  #  are validated when `nokogiri.rb` is required and when
  #  `nokogiri/version.rb` is required. See #1896 for background.
  #
  def test_version_info_basics
    assert_match(VERSION_MATCH, Nokogiri::VERSION)

    assert_equal(Nokogiri::VERSION, Nokogiri::VERSION_INFO["nokogiri"]["version"])

    if jruby?
      refute(Nokogiri::VERSION_INFO["nokogiri"].key?("cppflags"), "did not expect cppflags")
    else
      # cppflags/ldflags are more fully tested in scripts/test-gem-installation
      assert_kind_of(Array, Nokogiri::VERSION_INFO["nokogiri"]["cppflags"], "cppflags should be an array")
      assert_kind_of(Array, Nokogiri::VERSION_INFO["nokogiri"]["ldflags"], "ldflags should be an array")
    end

    assert_equal(::RUBY_VERSION, Nokogiri::VERSION_INFO["ruby"]["version"])
    assert_equal(::RUBY_PLATFORM, Nokogiri::VERSION_INFO["ruby"]["platform"])
    assert_equal(::Gem::Platform.local.to_s, Nokogiri::VERSION_INFO["ruby"]["gem_platform"])
  end

  def test_version_info_for_xerces_and_nekohtml
    skip_unless_jruby("xerces/nekohtml is only used for JRuby")
    assert_equal(Nokogiri::XERCES_VERSION, version_info["other_libraries"]["xerces:xercesImpl"])
    assert_equal(Nokogiri::NEKO_VERSION, version_info["other_libraries"]["net.sourceforge.htmlunit:neko-htmlunit"])
    refute_nil(version_info["other_libraries"]["isorelax:isorelax"])
    refute_nil(version_info["other_libraries"]["nu.validator:jing"])
    refute_nil(version_info["other_libraries"]["xalan:serializer"])
    refute_nil(version_info["other_libraries"]["xalan:xalan"])
    refute_nil(version_info["other_libraries"]["xerces:xercesImpl"])
    refute_nil(version_info["other_libraries"]["xml-apis:xml-apis"])
    assert_empty(Nokogiri.libxml2_patches)
  end

  def test_version_info_for_libxml
    skip_unless_libxml2("libxml2 is only used for CRuby")

    if Nokogiri::VersionInfo.instance.libxml2_using_packaged?
      assert_equal("packaged", version_info["libxml"]["source"])
      assert(version_info["libxml"]["patches"])
      assert_equal(Nokogiri.libxml2_patches, version_info["libxml"]["patches"])
      assert_equal(Nokogiri::VersionInfo.instance.libxml2_precompiled?, version_info["libxml"]["precompiled"])
    end
    if Nokogiri::VersionInfo.instance.libxml2_using_system?
      assert_equal("system", version_info["libxml"]["source"])
      refute(version_info["libxml"].key?("precompiled"))
      refute(version_info["libxml"].key?("patches"))
      assert_empty(Nokogiri.libxml2_patches)
    end

    assert_equal(Nokogiri::LIBXML_COMPILED_VERSION, version_info["libxml"]["compiled"])
    assert_match(VERSION_MATCH, version_info["libxml"]["compiled"])

    assert_match(VERSION_MATCH, version_info["libxml"]["loaded"])
    Nokogiri::LIBXML_LOADED_VERSION =~ /(\d)(\d{2})(\d{2})/
    major = Regexp.last_match(1).to_i
    minor = Regexp.last_match(2).to_i
    bug = Regexp.last_match(3).to_i
    assert_equal("#{major}.#{minor}.#{bug}", Nokogiri::VERSION_INFO["libxml"]["loaded"])

    assert(version_info["libxml"].key?("iconv_enabled"))
    assert(version_info["libxslt"].key?("datetime_enabled"))
  end

  def test_version_info_for_libxslt
    skip_unless_libxml2("libxslt is only used for CRuby")

    if Nokogiri::VersionInfo.instance.libxml2_using_packaged?
      assert_equal("packaged", version_info["libxslt"]["source"])
      assert(version_info["libxslt"]["patches"])
      assert_equal(Nokogiri::VersionInfo.instance.libxml2_precompiled?, version_info["libxslt"]["precompiled"])
    end
    if Nokogiri::VersionInfo.instance.libxml2_using_system?
      assert_equal("system", version_info["libxslt"]["source"])
      refute(version_info["libxslt"].key?("precompiled"))
      refute(version_info["libxslt"].key?("patches"))
    end

    assert_equal(Nokogiri::LIBXSLT_COMPILED_VERSION, version_info["libxslt"]["compiled"])
    assert_match(VERSION_MATCH, version_info["libxslt"]["compiled"])

    assert_match(VERSION_MATCH, version_info["libxslt"]["loaded"])
    Nokogiri::LIBXSLT_LOADED_VERSION =~ /(\d)(\d{2})(\d{2})/
    major = Regexp.last_match(1).to_i
    minor = Regexp.last_match(2).to_i
    bug = Regexp.last_match(3).to_i
    assert_equal("#{major}.#{minor}.#{bug}", Nokogiri::VERSION_INFO["libxslt"]["loaded"])
  end
end

class TestVersionInfo
  RUBYEXEC = File.join(RbConfig::CONFIG["bindir"], RbConfig::CONFIG["RUBY_INSTALL_NAME"])
  ROOTDIR = File.expand_path(File.join(File.dirname(__FILE__), ".."))

  class Base < Nokogiri::TestCase
    let(:version_info) do
      version_info = Dir.chdir(ROOTDIR) do
        %x(#{RUBYEXEC} -Ilib -rjson -e 'require "#{require_name}"; puts Nokogiri::VERSION_INFO.to_json')
      end
      JSON.parse(version_info)
    end
  end

  class RequireNokogiri < TestVersionInfo::Base
    include TestVersionInfoTests

    let(:require_name) { "nokogiri" }
  end

  class RequireVersionFileOnly < TestVersionInfo::Base
    include TestVersionInfoTests

    let(:require_name) { "nokogiri/version" }
  end
end
