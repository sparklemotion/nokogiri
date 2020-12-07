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

    assert_equal(::RUBY_VERSION, Nokogiri::VERSION_INFO["ruby"]["version"])
    assert_equal(::RUBY_PLATFORM, Nokogiri::VERSION_INFO["ruby"]["platform"])
    assert_equal(::Gem::Platform.local.to_s, Nokogiri::VERSION_INFO["ruby"]["gem_platform"])
  end

  def test_version_info_for_xerces
    skip("xerces is only used for JRuby") unless Nokogiri.jruby?
    assert_equal(Nokogiri::XERCES_VERSION, version_info["xerces"])
  end

  def test_version_info_for_nekohtml
    skip("nekohtml is only used for JRuby") unless Nokogiri.jruby?
    assert_equal(Nokogiri::NEKO_VERSION, version_info["nekohtml"])
  end

  def test_version_info_for_libxml
    skip("libxml2 is only used for CRuby") unless Nokogiri.uses_libxml?

    assert_equal(Nokogiri::LIBXML_COMPILED_VERSION, version_info["libxml"]["compiled"])
    assert_match(VERSION_MATCH, version_info["libxml"]["compiled"])

    assert_match VERSION_MATCH, version_info["libxml"]["loaded"]
    Nokogiri::LIBXML_LOADED_VERSION =~ /(\d)(\d{2})(\d{2})/
    major = Regexp.last_match(1).to_i
    minor = Regexp.last_match(2).to_i
    bug = Regexp.last_match(3).to_i
    assert_equal("#{major}.#{minor}.#{bug}", Nokogiri::VERSION_INFO["libxml"]["loaded"])

    assert(version_info["libxml"]["source"])
  end

  def test_version_info_for_libxslt
    skip("libxslt is only used for CRuby") unless Nokogiri.uses_libxml?

    assert_equal(Nokogiri::LIBXSLT_COMPILED_VERSION, version_info["libxslt"]["compiled"])
    assert_match(VERSION_MATCH, version_info["libxslt"]["compiled"])

    assert_match(VERSION_MATCH, version_info["libxslt"]["loaded"])
    Nokogiri::LIBXSLT_LOADED_VERSION =~ /(\d)(\d{2})(\d{2})/
    major = Regexp.last_match(1).to_i
    minor = Regexp.last_match(2).to_i
    bug = Regexp.last_match(3).to_i
    assert_equal("#{major}.#{minor}.#{bug}", Nokogiri::VERSION_INFO["libxslt"]["loaded"])

    assert(version_info["libxslt"]["source"])
  end

  def test_version_info_for_iconv
    skip("this value is only set in the C extension when libxml2 is used") unless Nokogiri.uses_libxml?

    assert_operator(version_info["libxml"], :key?, "iconv_enabled")
  end
end

class TestVersionInfo
  RUBYEXEC = File.join(RbConfig::CONFIG["bindir"], RbConfig::CONFIG["RUBY_INSTALL_NAME"])
  ROOTDIR = File.expand_path(File.join(File.dirname(__FILE__), ".."))

  class Base < Nokogiri::TestCase
    let(:version_info) do
      version_info = Dir.chdir(ROOTDIR) do
        %x(#{RUBYEXEC} -Ilib -rjson -r#{require_name} -e 'puts Nokogiri::VERSION_INFO.to_json')
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
