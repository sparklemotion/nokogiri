# coding: utf-8
# frozen_string_literal: true

module Nokogiri
  module XML
    # :markup: markdown
    #
    # \Class to house parsing options.
    #
    # ## About the Examples
    #
    # Examples on this page assume that the following code has been executed:
    #
    # ```
    # require 'nokogiri' # Make Nokogiri available.
    # include Nokogiri   # Allow omitting leading 'Nokogiri::'.
    # include XML        # Allow omitting leading 'XML::'.
    # xml = '<root />'   # Example XML string.
    # ```
    #
    # Examples executed via `IRB` (interactive Ruby) display \ParseOptions instances
    # using method #inspect.
    #
    # ## Methods That Use \XML::ParseOptions
    #
    # These methods use \XML::ParseOptions:
    #
    # - Nokogiri.HTML
    # - Nokogiri.HTML4
    # - Nokogiri.XML
    # - Nokogiri.make
    # - Nokogiri.parse
    # - Nokogiri::HTML.fragment
    # - Nokogiri::HTML4.fragment
    # - Nokogiri::HTML4.parse
    # - Nokogiri::HTML4::Document.parse
    # - Nokogiri::HTML4::DocumentFragment.new
    # - Nokogiri::HTML4::DocumentFragment.parse
    # - Nokogiri::XML.Reader
    # - Nokogiri::XML.fragment
    # - Nokogiri::XML.parse
    # - Nokogiri::XML::Document.parse
    # - Nokogiri::XML::Document.read_io (no block)
    # - Nokogiri::XML::Document.read_memory (no block)
    # - Nokogiri::XML::Document.read_memory (no block)
    # - Nokogiri::XML::DocumentFragment.new
    # - Nokogiri::XML::DocumentFragment.parse
    # - Nokogiri::XML::Node#parse
    # - Nokogiri::XML::ParseOptions.new (no block)
    # - Nokogiri::XML::Reader.from_io (no block)
    # - Nokogiri::XML::Reader.from_memory (no block)
    # - Nokogiri::XML::RelaxNG.new (no block)
    # - Nokogiri::XML::RelaxNG.read_memory (no block)
    # - Nokogiri::XML::Schema.new (no block)
    # - XSD::XMLParser::Nokogiri.new (no block)
    #
    # Certain other parsing methods use different options;
    # see HTML5.
    #
    # ## How to Set Options
    #
    # There are three ways to set options for an instance of this class:
    #
    # - Calling setter methods on instance (recommended).
    # - Passing argument `options` with ::new.
    # - Giving a block with a parsing method.
    #
    # ### Calling Setter Methods on Instance (Recommended)
    #
    # ### Passing Argument `options` with ::new
    #
    # Each of the methods that use \XML::ParseOptions takes an optional argument `options`
    # whose value is an integer.
    #
    # You can use bitmask constants to construct a suitable integer for the options you want;
    # use logical OR to combine multiple constants:
    #
    # ```
    # options = ParseOptions::COMPACT
    # ParseOptions.new(options)
    # # => #<Nokogiri::XML::ParseOptions: ... strict, compact>
    # options = ParseOptions::COMPACT | ParseOptions::NOBLANKS
    # ParseOptions.new(options)
    # # => #<Nokogiri::XML::ParseOptions: ... strict, noblanks, compact>
    # ```
    #
    # The bitmask constants are:
    #
    #
    #
    # There are also several "shorthand" constants that can set multiple options:
    #
    # ```
    # ParseOptions.new(ParseOptions::DEFAULT_HTML)
    # # => #<Nokogiri::XML::ParseOptions: ... recover, nowarning, nonet, big_lines, default_schema, noerror, default_html, default_xml>
    # ParseOptions.new(ParseOptions::DEFAULT_SCHEMA)
    # # => #<Nokogiri::XML::ParseOptions: ... strict, nonet, big_lines, default_schema>
    # ParseOptions.new(ParseOptions::DEFAULT_XML)
    # # => #<Nokogiri::XML::ParseOptions: ... recover, nonet, big_lines, default_schema, default_xml>
    # ParseOptions.new(ParseOptions::DEFAULT_XSLT)
    # # => #<Nokogiri::XML::ParseOptions: ... recover, noent, dtdload, dtdattr, nonet, nocdata, big_lines, default_xslt, default_schema, default_xml>    #
    # ```
    #
    # ### Giving a Block with a Parsing Method
    #
    # These options directly expose libxml2's parse options, which are all boolean in the sense that
    # an option is "on" or "off".
    #
    # 💡 Note that HTML5 parsing has a separate, orthogonal set of options due to the nature of the
    # HTML5 specification. See Nokogiri::HTML5.
    #
    # ⚠ Not all parse options are supported on JRuby. Nokogiri will attempt to invoke the equivalent
    # behavior in Xerces/NekoHTML on JRuby when it's possible.
    #
    # ## Convenience Methods
    #
    # A \ParseOptions object has three sets of convenience methods,
    # each based on the name of one of the constants:
    #
    # - **Setters**: each is the downcase of an option name, and turns on an option:
    #
    #     ```
    #     options = ParseOptions.new
    #     # => #<Nokogiri::XML::ParseOptions: ... strict>
    #     options.big_lines
    #     # => #<Nokogiri::XML::ParseOptions: ... strict, big_lines>
    #     options.compact
    #     # => #<Nokogiri::XML::ParseOptions: ... strict, compact, big_lines>
    #     ```
    #
    # - **Unsetters**: each begins with `no`, and turns off an option.
    #   Note that there is no unsetter `nostrict`;
    #   the setter `recover` serves the same purpose:
    #
    #     ```
    #     options.nobig_lines
    #     # => #<Nokogiri::XML::ParseOptions: ... strict, compact>
    #     options.nocompact
    #     # => #<Nokogiri::XML::ParseOptions: ... strict>
    #     options.recover # Functionally equivalent to nostrict.
    #     # => #<Nokogiri::XML::ParseOptions: ... recover>
    #     options.noent   # Set NOENT.
    #     # => #<Nokogiri::XML::ParseOptions: ... recover, noent>
    #     options.nonoent # Unset NOENT.
    #     # => #<Nokogiri::XML::ParseOptions: ... recover>
    #     ```
    #
    # - **Queries**: each ends with `?`, and returns whether an option is on or off:
    #
    #     ```
    #     options.recover? # => true
    #     options.strict?  # => false
    #     ```
    #
    # Each setter and unsetter method returns `self`,
    # so the methods may be chained:
    #
    # ```
    # options.compact.big_lines
    # # => #<Nokogiri::XML::ParseOptions: ... strict, compact, big_lines>
    # ```
    #
    #
    # [Using Ruby Blocks]
    #
    #   Most parsing methods will accept a block for configuration of parse options, and we
    #   recommend chaining the setter methods:
    #
    #     doc = Nokogiri::XML::Document.parse(xml) { |config| config.huge.pedantic }
    #
    #
    # [ParseOptions constants]
    #
    #   You can also use the constants declared under Nokogiri::XML::ParseOptions to set various
    #   combinations. They are bits in a bitmask, and so can be combined with bitwise operators:
    #
    #     po = Nokogiri::XML::ParseOptions.new(Nokogiri::XML::ParseOptions::HUGE | Nokogiri::XML::ParseOptions::PEDANTIC)
    #     doc = Nokogiri::XML::Document.parse(xml, nil, nil, po)
    #
    class ParseOptions
      # :markup: markdown
      #
      # Strict parsing; do not recover from errors in input.
      STRICT      = 0

      # Recover from errors in input; no strict parsing.
      RECOVER     = 1 << 0

      # Substitute entities.
      #
      # ⚠ This option enables entity substitution, contrary to what the name implies.
      #
      # ⚠ <b>It is UNSAFE to set this option</b> when parsing untrusted documents.
      NOENT       = 1 << 1

      # Load external subsets.
      #
      # ⚠ <b>It is UNSAFE to set this option</b> when parsing untrusted documents.
      DTDLOAD     = 1 << 2

      # Default DTD attributes.
      DTDATTR     = 1 << 3

      # Validate with the DTD.
      DTDVALID    = 1 << 4

      # Suppress error reports.
      NOERROR     = 1 << 5

      # Suppress warning reports.
      NOWARNING   = 1 << 6

      # Enable pedantic error reporting.
      PEDANTIC    = 1 << 7

      # Remove blank nodes.
      NOBLANKS    = 1 << 8

      # Use the SAX1 interface internally.
      SAX1        = 1 << 9

      # Implement XInclude substitution.
      XINCLUDE    = 1 << 10

      # Forbid network access.
      #
      # ⚠ <b>It is UNSAFE to unset this option</b> when parsing untrusted documents.
      NONET       = 1 << 11

      # Do not reuse the context dictionary.
      NODICT      = 1 << 12

      # Remove redundant namespaces declarations.
      NSCLEAN     = 1 << 13

      # Merge CDATA as text nodes.
      NOCDATA     = 1 << 14

      # Do not generate XInclude START/END nodes.
      NOXINCNODE  = 1 << 15

      # Compact small text nodes.
      #
      # ⚠ No modification of the DOM tree is allowed after parsing.
      COMPACT     = 1 << 16

      # Parse using XML-1.0 before update 5.
      OLD10       = 1 << 17

      # Do not fixup XInclude xml:base URIs.
      NOBASEFIX   = 1 << 18

      # Relax any hardcoded limit from the parser.
      #
      # ⚠ <b>It is UNSAFE to set this option</b> when parsing untrusted documents.
      HUGE        = 1 << 19

      # Support line numbers up to `long int` (default is a `short int`).
      BIG_LINES   = 1 << 22

      # Shorthand options mask useful for parsing XML:
      # sets RECOVER,  NONET,  BIG_LINES.
      DEFAULT_XML  = RECOVER | NONET | BIG_LINES

      # Shorthand options mask useful for parsing XSLT stylesheets:
      # sets RECOVER, NONET, NOENT, DTDLOAD, DTDATTR, NOCDATA, BIG_LINES.
      DEFAULT_XSLT = RECOVER | NONET | NOENT | DTDLOAD | DTDATTR | NOCDATA | BIG_LINES

      # Shorthand options mask useful for parsing HTML4:
      # sets RECOVER, NOERROR, NOWARNING, NONET, BIG_LINES.
      DEFAULT_HTML = RECOVER | NOERROR | NOWARNING | NONET | BIG_LINES

      # Shorthand options mask useful for parsing \XML schemas:
      # sets NONET, BIG_LINES.
      DEFAULT_SCHEMA = NONET | BIG_LINES

      attr_accessor :options

      # :markup: markdown
      #
      # Returns a new \ParseOptions object with all options off
      # (`strict` means `norecover`):
      #
      # ```
      # ParseOptions.new
      # # => #<Nokogiri::XML::ParseOptions: ... strict>
      # ```
      #
      def initialize(options = STRICT)
        @options = options
      end

      constants.each do |constant|
        next if constant.to_sym == :STRICT

        class_eval <<~RUBY, __FILE__, __LINE__ + 1
          def #{constant.downcase}
            @options |= #{constant}
            self
          end

          def no#{constant.downcase}
            @options &= ~#{constant}
            self
          end

          def #{constant.downcase}?
            #{constant} & @options == #{constant}
          end
        RUBY
      end

      def strict # :nodoc:
        @options &= ~RECOVER
        self
      end

      def strict? # :nodoc:
        @options & RECOVER == STRICT
      end

      # :markup: markdown
      #
      # :call-seq:
      #    self == object
      #
      # Returns whether `object` is equal to `self` (`object.to_i == to_i`):
      #
      # ```
      # options = ParseOptions.new
      # # => #<Nokogiri::XML::ParseOptions: ... strict>
      # options == options.dup         # => true
      # options == options.dup.recover # => false
      # ```
      #
      def ==(other)
        other.to_i == to_i
      end

      alias_method :to_i, :options

      # :markup: markdown
      #
      # :call-seq:
      #    inspect
      #
      # Returns a string representation of +self+ that includes
      # the numeric value of `@options`:
      #
      # ```
      # options = ParseOptions.new
      # options.inspect
      # # => "#<Nokogiri::XML::ParseOptions: @options=0 strict>"
      #
      # ```
      #
      # In general, the returned string also includes the (downcased) names of the options
      # that are **on** (but omits the names of those that are **off**):
      #
      # ```
      # options.recover.big_lines
      # options.inspect
      # # => "#<Nokogiri::XML::ParseOptions: @options=4194305 recover, big_lines>"
      # ```
      #
      # The exception is that always either `recover` (i.e, *not strict*)
      # or the pseudo-option `strict` is reported:
      #
      # ```
      # options.norecover
      # options.inspect
      # # => "#<Nokogiri::XML::ParseOptions: @options=4194304 strict, big_lines>"
      # ```
      #
      def inspect
        options = []
        self.class.constants.each do |k|
          options << k.downcase if send(:"#{k.downcase}?")
        end
        super.sub(/>$/, " " + options.join(", ") + ">")
      end
    end
  end
end
