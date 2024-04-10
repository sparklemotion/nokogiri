# frozen_string_literal: true

require "helper"

class TestGemPlatform < Nokogiri::TestCase
  # These tests were written to help me better understand the behavior
  # of Rubygems's platform-matching behavior. They don't exercise code
  # in Nokogiri, but do express the expectations we have of Rubygems
  # and `gem install` behavior for our native darwin gem.
  #
  # More specifically, the grpc gem ships a native darwin gem with
  # platform string `universal-darwin` which I *think* refers to the
  # fact that it supports i386-and-x86_64 architectures (and not that
  # it supports x86_64-and-arm64 architectures).
  #
  # With ARM support imminent [1] I'm a little worried about using
  # `universal` until I understand better whether ARM support will be
  # implied by `universal` or `universal2` or what. From
  # https://en.wikipedia.org/wiki/Universal_binary:
  #
  # > The new Universal 2 binary format was introduced at the 2020
  # > Worldwide Developers Conference. Universal 2 allows applications
  # > to run on both Intel x86-64-based and ARM64-based Macintosh
  # > computers, for the Mac transition to Apple Silicon.
  #
  # [1]: https://arstechnica.com/gadgets/2020/06/this-is-apples-roadmap-for-moving-the-first-macs-away-from-intel/
  #
  # There seems to be a lot of uncertainty right now, so I'm writing
  # some tests to express my expectations, and we're going to
  # conservatively use `x86_64-darwin` as the platform name for the
  # native gem.
  let(:darwin_gem_platform) { Gem::Platform.new("x86_64-darwin") }

  describe "darwin" do
    it "builds a gem that works on all darwin x86+64 platforms" do
      assert_match darwin_gem_platform,
        Gem::Platform.new(["universal", "darwin", "19"]),
        "gem should match system-installed ruby on catalina"
      assert_match darwin_gem_platform,
        Gem::Platform.new(["x86_64", "darwin", "19"]),
        "gem should match user-installed ruby on catalina"
      assert_match darwin_gem_platform,
        Gem::Platform.new(["x86_64", "darwin", "18"]),
        "gem should match user-installed ruby on mojave"

      # The intention here is to test that the x86_64 platform gems
      # won't match a future ruby that is compiled on arm64/aarch64.
      #
      # I don't know what the future platform will call itself, but at
      # least one of these should be right and none of them should
      # match, so here are all the tests I can reasonably imagine.
      #
      # Feel free to delete assertions for clarity once we know more.
      refute_match darwin_gem_platform,
        Gem::Platform.new(["arm64", "darwin", "19"]),
        "gem should not match an arm64 ruby"
      refute_match darwin_gem_platform,
        Gem::Platform.new(["arm", "darwin", "19"]),
        "gem should not match an arm ruby"
      refute_match darwin_gem_platform,
        Gem::Platform.new(["aarch64", "darwin", "19"]),
        "gem should not match an aarch64 ruby"
      refute_match darwin_gem_platform,
        Gem::Platform.new(["universal2", "darwin", "19"]),
        "gem should not match an aarch64 ruby"
      refute_match darwin_gem_platform,
        Gem::Platform.new(["universal_2", "darwin", "19"]),
        "gem should not match an aarch64 ruby"
    end
  end
end
