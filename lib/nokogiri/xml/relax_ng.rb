# frozen_string_literal: true

module Nokogiri
  module XML
    class << self
      # See related: Nokogiri::XML::RelaxNG.read_memory
      #
      # [Parameters]
      # - +input+ (String, IO) RELAX NG schema definition
      # - +parse_options+ (Nokogiri::XML::ParseOptions)
      #   Defaults to ParseOptions::DEFAULT_SCHEMA
      #
      # [Returns] Nokogiri::XML::RelaxNG
      #
      def RelaxNG(...)
        RelaxNG.new(...)
      end
    end

    # Nokogiri::XML::RelaxNG is used for validating XML against a RELAX NG schema definition.
    #
    # *Example:* Determine whether an XML document is valid.
    #
    #   schema = Nokogiri::XML::RelaxNG(File.read(RELAX_NG_FILE))
    #   doc = Nokogiri::XML(File.read(XML_FILE))
    #   schema.valid?(doc) # Boolean
    #
    # *Example:* Validate an XML document against a RelaxNG schema, and capture any errors that are found.
    #
    #   schema = Nokogiri::XML::RelaxNG(File.open(RELAX_NG_FILE))
    #   doc = Nokogiri::XML(File.open(XML_FILE))
    #   errors = schema.validate(doc) # Array<SyntaxError>
    #
    # ⚠ RELAX NG input is always treated as *trusted*, meaning that the underlying parsing libraries
    # *will access network resources*. This is counter to Nokogiri's "untrusted by default" security
    # policy, but is an unfortunate limitation of the underlying libraries. Please do not use this
    # class for untrusted schema documents.
    class RelaxNG < Nokogiri::XML::Schema
      # Parse a RELAX NG schema definition and create a new Schema object.
      # See related: Nokogiri::XML::RelaxNG.read_memory
      #
      # [Parameters]
      # - +input+ (String, IO) RELAX NG schema definition
      # - +parse_options+ (Nokogiri::XML::ParseOptions)
      #   Defaults to ParseOptions::DEFAULT_SCHEMA  ⚠ Unused
      #
      # [Returns] Nokogiri::XML::RelaxNG
      #
      # ⚠ +parse_options+ is currently unused by this method and is present only as a placeholder for
      # future functionality.
      def self.new(...)
        read_memory(...)
      end

      # :call-seq:
      #   read_memory(input) → Nokogiri::XML::RelaxNG
      #   read_memory(input, options:) → Nokogiri::XML::RelaxNG
      #
      # Parse a RELAX NG schema definition and create a new Schema object.
      #
      # [Parameters]
      # - +input+ (String) RELAX NG schema definition
      # - +options:+ (Nokogiri::XML::ParseOptions)
      #   Defaults to ParseOptions::DEFAULT_SCHEMA  ⚠ Unused
      #
      # [Returns] Nokogiri::XML::RelaxNG
      #
      # ⚠ +parse_options+ is currently unused by this method and is present only as a placeholder for
      # future functionality.
      def self.read_memory(input, parse_options_ = ParseOptions::DEFAULT_SCHEMA, options: parse_options_)
        from_document(Nokogiri::XML::Document.parse(input), options)
      end
    end
  end
end
