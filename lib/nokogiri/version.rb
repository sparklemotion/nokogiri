module Nokogiri
  # The version of Nokogiri you are using
  VERSION = "1.10.3"

  class VersionInfo # :nodoc:
    def jruby?
      ::JRUBY_VERSION if RUBY_PLATFORM == "java"
    end

    def engine
      defined?(RUBY_ENGINE) ? RUBY_ENGINE : "mri"
    end

    def loaded_parser_version
      LIBXML_PARSER_VERSION.
        scan(/^(\d+)(\d\d)(\d\d)(?!\d)/).first.
        collect(&:to_i).
        join(".")
    end

    def compiled_parser_version
      LIBXML_VERSION
    end

    def libxml2?
      defined?(LIBXML_VERSION)
    end

    def libxml2_using_system?
      !libxml2_using_packaged?
    end

    def libxml2_using_packaged?
      NOKOGIRI_USE_PACKAGED_LIBRARIES
    end

    def warnings
      return [] unless libxml2?

      if compiled_parser_version != loaded_parser_version
        ["Nokogiri was built against LibXML version #{compiled_parser_version}, but has dynamically loaded #{loaded_parser_version}"]
      else
        []
      end
    end

    def to_hash
      {}.tap do |vi|
        vi["warnings"] = []
        vi["nokogiri"] = Nokogiri::VERSION
        vi["ruby"] = {}.tap do |ruby|
          ruby["version"] = ::RUBY_VERSION
          ruby["platform"] = ::RUBY_PLATFORM
          ruby["description"] = ::RUBY_DESCRIPTION
          ruby["engine"] = engine
          ruby["jruby"] = jruby? if jruby?
        end

        if libxml2?
          vi["libxml"] = {}.tap do |libxml|
            libxml["binding"] = "extension"
            if libxml2_using_packaged?
              libxml["source"] = "packaged"
              libxml["libxml2_path"] = NOKOGIRI_LIBXML2_PATH
              libxml["libxslt_path"] = NOKOGIRI_LIBXSLT_PATH
              libxml["libxml2_patches"] = NOKOGIRI_LIBXML2_PATCHES
              libxml["libxslt_patches"] = NOKOGIRI_LIBXSLT_PATCHES
            else
              libxml["source"] = "system"
            end
            libxml["compiled"] = compiled_parser_version
            libxml["loaded"] = loaded_parser_version
          end
          vi["warnings"] = warnings
        elsif jruby?
          vi["xerces"] = Nokogiri::XERCES_VERSION
          vi["nekohtml"] = Nokogiri::NEKO_VERSION
        end
      end
    end

    def to_markdown
      begin
        require "psych"
      rescue LoadError
      end
      require "yaml"
      "# Nokogiri (#{Nokogiri::VERSION})\n" +
      YAML.dump(to_hash).each_line.map { |line| "    #{line}" }.join
    end

    # FIXME: maybe switch to singleton?
    @@instance = new
    @@instance.warnings.each do |warning|
      warn "WARNING: #{warning}"
    end
    def self.instance; @@instance; end
  end

  def self.uses_libxml? # :nodoc:
    VersionInfo.instance.libxml2?
  end

  def self.jruby? # :nodoc:
    VersionInfo.instance.jruby?
  end

  # Ensure constants used in this file are loaded
  if Nokogiri.jruby?
    require "nokogiri/jruby/dependencies"
  end
  require "nokogiri/nokogiri"

  # More complete version information about libxml
  VERSION_INFO = VersionInfo.instance.to_hash
end
