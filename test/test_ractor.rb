# frozen_string_literal: true

require "helper"
require "open3"
require "rbconfig"

# The Ractor tests run in child processes. Once a process has started a Ractor, some
# process-wide behavior changes for good (for example, ObjectSpace.each_object stops seeing
# objects), which would leak into unrelated tests. A child process also lets a hang fail the
# test instead of stalling the suite.
describe "Ractor support" do
  def ractor_script_timeout
    120
  end

  def ractor_script_prelude
    <<~RUBY
      # frozen_string_literal: true
      require "nokogiri"
      Warning[:experimental] = false
      def ractor_value(r) = r.respond_to?(:value) ? r.value : r.take
    RUBY
  end

  def assert_ractor_script(script, expected)
    load_path = $LOAD_PATH.select { |dir| File.directory?(dir) }.flat_map { |dir| ["-I", dir] }
    cmd = [RbConfig.ruby, *load_path, "-e", ractor_script_prelude + script]

    Open3.popen3(*cmd) do |stdin, out, err, wait_thr|
      stdin.close
      out_reader = Thread.new { out.read }
      err_reader = Thread.new { err.read }

      unless wait_thr.join(ractor_script_timeout)
        Process.kill(:KILL, wait_thr.pid)
        flunk("Ractor script did not finish within #{ractor_script_timeout}s:\n#{script}")
      end

      output = out_reader.value
      assert_predicate(wait_thr.value, :success?, "Ractor script failed:\n#{output}#{err_reader.value}")
      assert_equal(expected, output)
    end
  end

  before do
    skip("Ractors are a CRuby feature") unless RUBY_ENGINE == "ruby"
    skip("Ractor support requires libxml2 >= 2.14") unless Nokogiri.uses_libxml?(">= 2.14")

    # valgrind may follow the child processes, and a Ruby process that has created a Ractor
    # can't exit cleanly under it: with RUBY_FREE_AT_EXIT, Ruby 4.0.7 reads freed memory in
    # ractor_free (RUBY_FREE_AT_EXIT=1 valgrind ruby -e 'Ractor.new { 1 }.value'); without it,
    # everything Ruby allocated is reported as leaked.
    skip("Ractor processes can't exit cleanly under valgrind") if ENV["LD_PRELOAD"]&.match?(/valgrind|vgpreload/)
  end

  it "has constants that every Ractor can read" do
    assert_ractor_script(<<~RUBY, "")
      # Module-level state that is only used from the main Ractor, by design.
      MAIN_RACTOR_ONLY = [
        [Nokogiri::CSS::SelectorCache, :@cache],
        [Nokogiri::CSS::SelectorCache, :@mutex],
        [Nokogiri::VersionInfo, :@singleton__mutex__],
      ].freeze

      unshareable = []
      seen = {}
      walk = lambda do |mod|
        next if seen[mod]

        seen[mod] = true
        mod.constants(false).each do |name|
          next if mod.autoload?(name)

          value = mod.const_get(name, false)
          if value.is_a?(Module)
            walk.call(value) if value.name&.start_with?("Nokogiri")
          elsif !Ractor.shareable?(value)
            unshareable << "\#{mod}::\#{name}"
          end
        end
        mod.instance_variables.each do |ivar|
          next if MAIN_RACTOR_ONLY.include?([mod, ivar])

          unshareable << "\#{mod}.\#{ivar}" unless Ractor.shareable?(mod.instance_variable_get(ivar))
        end
      end
      walk.call(Nokogiri)
      print unshareable.join("\n")
    RUBY
  end

  it "parses, searches, modifies, and serializes documents in Ractors" do
    assert_ractor_script(<<~RUBY, "ok,ok,ok,ok")
      ractors = 4.times.map do |i|
        Ractor.new(i) do |i|
          xml = Nokogiri::XML("<root><a id='\#{i}'>x</a><b/></root>")
          xml.root.add_child("<c>\#{i}</c>")
          raise "xml" unless xml.at_css("a")["id"] == i.to_s && xml.xpath("//c").text == i.to_s
          raise "xml out" unless xml.to_xml(indent: 2).include?("<c>\#{i}</c>")
          raise "dup" unless xml.dup.root.name == "root"

          html4 = Nokogiri::HTML4("<p class='x'>\#{i}</p>")
          raise "html4" unless html4.css("p.x").text == i.to_s
          raise "fragment" unless Nokogiri::HTML4.fragment("<b>\#{i}</b>").to_html == "<b>\#{i}</b>"

          if defined?(Nokogiri::HTML5)
            html5 = Nokogiri::HTML5("<p>\#{i}<td>x")
            raise "html5" unless html5.at_css("p").text.start_with?(i.to_s)
            raise "html5 out" unless html5.to_html.include?("<p>\#{i}")
          end

          builder = Nokogiri::XML::Builder.new { |x| x.root { x.n(i) } }
          raise "builder" unless builder.doc.at("n").text == i.to_s

          raise "errors" if Nokogiri::XML("<a><b></a>").errors.empty?
          "ok"
        end
      end
      print ractors.map { ractor_value(_1) }.join(",")
    RUBY
  end

  it "compiles schemas in many Ractors at once" do
    # libxml2 builds its table of built-in schema types on first use, without a lock
    assert_ractor_script(<<~RUBY, "16")
      XSD = <<~X
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
          <xs:element name="root" type="xs:string"/>
        </xs:schema>
      X
      RNG = <<~X
        <element name="root" xmlns="http://relaxng.org/ns/structure/1.0"
                 datatypeLibrary="http://www.w3.org/2001/XMLSchema-datatypes">
          <data type="string"/>
        </element>
      X
      ractors = 16.times.map do
        Ractor.new do
          doc = Nokogiri::XML("<root>x</root>")
          Nokogiri::XML::Schema(XSD).valid?(doc) && Nokogiri::XML::RelaxNG(RNG).valid?(doc)
        end
      end
      print ractors.count { ractor_value(_1) }
    RUBY
  end

  it "reports each Ractor's XSLT errors to that Ractor" do
    # libxslt reports stylesheet compilation errors through a process-wide handler
    assert_ractor_script(<<~RUBY, "0")
      ractors = 8.times.map do |id|
        Ractor.new(id) do |id|
          bad = <<~X
            <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
              <xsl:bogus\#{id}/>
            </xsl:stylesheet>
          X
          stop = Nokogiri::XSLT(<<~X)
            <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
              <xsl:template match="/"><xsl:message terminate="yes">stop\#{id}</xsl:message></xsl:template>
            </xsl:stylesheet>
          X
          doc = Nokogiri::XML("<r/>")
          wrong = 0
          100.times do
            begin
              Nokogiri::XSLT(bad)
              wrong += 1
            rescue RuntimeError => e
              wrong += 1 unless e.message.include?("bogus\#{id}") && !e.message.match?(/bogus(?!\#{id}\\b)\\d+/)
            end
            begin
              stop.transform(doc)
              wrong += 1
            rescue RuntimeError => e
              wrong += 1 unless e.message.include?("stop\#{id}") && !e.message.match?(/stop(?!\#{id}\\b)\\d+/)
            end
          end
          wrong
        end
      end
      print ractors.sum { ractor_value(_1) }
    RUBY
  end

  it "uses XSLT extension modules registered in the main Ractor" do
    assert_ractor_script(<<~RUBY, "TWO")
      class Shout
        def shout(s) = s.to_s.upcase
      end
      Nokogiri::XSLT.register("urn:shout", Shout)

      r = Ractor.new do
        xsl = Nokogiri::XSLT(<<~X)
          <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                          xmlns:my="urn:shout" extension-element-prefixes="my">
            <xsl:template match="/"><out><xsl:value-of select="my:shout(string(//b))"/></out></xsl:template>
          </xsl:stylesheet>
        X
        xsl.transform(Nokogiri::XML("<a><b>two</b></a>")).root.text
      end
      print ractor_value(r)
    RUBY
  end

  it "keeps a CSS selector cache for each Ractor" do
    assert_ractor_script(<<~RUBY, "[\"x\"],nil,1")
      r = Ractor.new do
        Nokogiri::CSS::SelectorCache["key"] = ["x"]
        Nokogiri::XML("<a><b/></a>").css("a > b").size # uses the cache
        Nokogiri::CSS::SelectorCache["key"]
      end
      in_ractor = ractor_value(r)
      print [in_ractor.inspect, Nokogiri::CSS::SelectorCache["key"].inspect, Nokogiri::XML("<a><b/></a>").css("a > b").size].join(",")
    RUBY
  end
end
