# coding: utf-8
# frozen_string_literal: true

module Nokogiri
  module XML
    class << self
      #
      # :call-seq:
      #   Schema(input) → Nokogiri::XML::Schema
      #   Schema(input, parse_options) → Nokogiri::XML::Schema
      #
      # Parse an XSD schema definition and create a new {Schema} object. This is a convenience
      # method for Nokogiri::XML::Schema.new
      #
      # See related: Nokogiri::XML::Schema.new
      #
      # [Parameters]
      # - +input+ (String, IO) XSD schema definition
      # - +parse_options+ (Nokogiri::XML::ParseOptions)
      # [Returns] Nokogiri::XML::Schema
      #
      def Schema(input, parse_options = ParseOptions::DEFAULT_SCHEMA)
        Schema.new(input, parse_options)
      end
    end

    # Nokogiri::XML::Schema is used for validating XML against an XSD schema definition.
    #
    # *Example:* Determine whether an XML document is valid.
    #
    #   schema = Nokogiri::XML::Schema(File.read(XSD_FILE))
    #   doc = Nokogiri::XML(File.read(XML_FILE))
    #   schema.valid?(doc) # Boolean
    #
    # *Example:* Validate an XML document against a Schema, and capture any errors that are found.
    #
    #   schema = Nokogiri::XML::Schema(File.read(XSD_FILE))
    #   doc = Nokogiri::XML(File.read(XML_FILE))
    #   errors = schema.validate(doc) # Array<SyntaxError>
    #
    # ⚠ As of v1.11.0, Schema treats inputs as *untrusted* by default, and so external entities are
    # not resolved from the network (+http://+ or +ftp://+). When parsing a trusted document, the
    # caller may turn off the +NONET+ option via the ParseOptions to (re-)enable external entity
    # resolution over a network connection.
    #
    # Previously, documents were "trusted" by default during schema parsing which was counter to
    # Nokogiri's "untrusted by default" security policy.
    class Schema
      # The errors found while parsing the XSD
      #
      # [Returns] Array<Nokogiri::XML::SyntaxError>
      attr_accessor :errors

      # The options used to parse the schema
      #
      # [Returns] Nokogiri::XML::ParseOptions
      attr_accessor :parse_options

      # :call-seq:
      #   new(input) → Nokogiri::XML::Schema
      #   new(input, parse_options) → Nokogiri::XML::Schema
      #
      # Parse an XSD schema definition and create a new Nokogiri::XML:Schema object.
      #
      # [Parameters]
      # - +input+ (String, IO) XSD schema definition
      # - +parse_options+ (Nokogiri::XML::ParseOptions)
      #   Defaults to Nokogiri::XML::ParseOptions::DEFAULT_SCHEMA
      #
      # [Returns] Nokogiri::XML::Schema
      #
      def self.new(input, parse_options = ParseOptions::DEFAULT_SCHEMA)
        from_document(Nokogiri::XML(input), parse_options)
      end

      #
      # :call-seq: validate(input) → Array<SyntaxError>
      #
      # Validate +input+ and return any errors that are found.
      #
      # [Parameters]
      # - +input+ (Nokogiri::XML::Document, String)
      #
      #   A parsed document, or a string containing a local filename.
      #
      # [Returns] Array<SyntaxError>
      #
      # *Example:* Validate an existing Document +document+, and capture any errors that are found.
      #
      #   schema = Nokogiri::XML::Schema(File.read(XSD_FILE))
      #   errors = schema.validate(document)
      #
      # *Example:* Validate an XML document on disk, and capture any errors that are found.
      #
      #   schema = Nokogiri::XML::Schema(File.read(XSD_FILE))
      #   errors = schema.validate("/path/to/file.xml")
      #
      def validate(input)
        if input.is_a?(Nokogiri::XML::Document)
          validate_document(input)
        elsif File.file?(input)
          validate_file(input)
        else
          raise ArgumentError, "Must provide Nokogiri::XML::Document or the name of an existing file"
        end
      end

      #
      # :call-seq: valid?(input) → Boolean
      #
      # Validate +input+ and return a Boolean indicating whether the document is valid
      #
      # [Parameters]
      # - +input+ (Nokogiri::XML::Document, String)
      #
      #   A parsed document, or a string containing a local filename.
      #
      # [Returns] Boolean
      #
      # *Example:* Validate an existing XML::Document +document+
      #
      #   schema = Nokogiri::XML::Schema(File.read(XSD_FILE))
      #   return unless schema.valid?(document)
      #
      # *Example:* Validate an XML document on disk
      #
      #   schema = Nokogiri::XML::Schema(File.read(XSD_FILE))
      #   return unless schema.valid?("/path/to/file.xml")
      #
      def valid?(input)
        validate(input).empty?
      end
    end
  end
end
