# coding: utf-8
# frozen_string_literal: true

# :markup: markdown

module Nokogiri
  module XML
    # \Class to contain options for parsing \XML or \HTML4 (but not \HTML5).
    #
    # 💡 Note that \HTML5 parsing has a separate, orthogonal set of options due to the API of the
    # \HTML5 library used. See Nokogiri::HTML5.
    #
    # ## About the Examples
    #
    # Examples on this page assume that the following code has been executed:
    #
    # ```
    # require 'nokogiri'           # Make Nokogiri available.
    # include Nokogiri             # Allow omitting leading 'Nokogiri::'.
    # xml_s = "<root />\n"         # String containing XML.
    # File.write('t.xml', xml_s)   # File containing XML.
    # html_s = "<html />\n"        # String containing HTML.
    # File.write('t.html', html_s) # File containing HTML.
    # ```
    #
    # Examples executed via `IRB` (interactive Ruby) display \ParseOptions instances
    # using method #inspect.
    #
    # ## Parsing Methods
    #
    # Each of the parsing methods performs parsing for an \XML or \HTML4 source:
    #
    # - Each requires a leading argument that specifies the source of the text to be parsed;
    #   except as noted, the argument's value may be either:
    #
    #     - A string.
    #     - An open IO stream (must respond to methods `read` and `close`).
    #
    #     Examples:
    #
    #     ```
    #     XML::parse(xml_s)
    #     HTML4.parse(html_s)
    #     XML::parse(File.open('t.xml'))
    #     HTML4.parse(File.open('t.html'))
    #     ```
    #
    # - Each accepts a trailing optional argument `options`
    #   (or keyword argument `options`)
    #   that specifies parsing options;
    #   the argument's value may be either:
    #
    #     - An integer: see [Bitmap Constants](rdoc-ref:ParseOptions@Bitmap+Constants).
    #     - An instance of \ParseOptions: see ParseOptions.new.
    #
    #     Examples:
    #
    #     ```
    #     XML::parse(xml_s, options: XML::ParseOptions::STRICT)
    #     HTML4::parse(html_s, options: XML::ParseOptions::BIG_LINES)
    #     XML::parse(xml_s, options: XML::ParseOptions.new.strict)
    #     HTML4::parse(html_s, options: XML::ParseOptions.new.big_lines)
    #     ```
    #
    # - Each (except as noted) accepts a block that allows parsing options to be specified;
    #   see [Options-Setting Blocks](rdoc-ref:ParseOptions@Options-Setting+Blocks).
    #
    # Certain other parsing methods use different options;
    # see \HTML5.
    #
    # ⚠ Not all parse options are supported on JRuby.
    # \Nokogiri attempts to invoke the equivalent
    # behavior in Xerces/NekoHTML on JRuby when it's possible.
    #
    # ## Bitmap Constants
    #
    # Each of the [parsing methods](rdoc-ref:ParseOptions@Parsing+Methods)
    # discussed here accept an integer argument `options` that specifies parsing options.
    #
    # That integer value may be constructed using the bitmap constants defined in \ParseOptions.
    #
    # Except for `STRICT` (see note below),
    # each of the bitmap constants has a non-zero value
    # that represents a bit in an integer value;
    # to illustrate, here are a few of the constants, displayed in binary format (base 2):
    #
    # ```
    # ParseOptions::RECOVER.to_s(2)  # => "1"
    # ParseOptions::NOENT.to_s(2)    # => "10"
    # ParseOptions::DTDLOAD.to_s(2)  # => "100"
    # ParseOptions::DTDATTR.to_s(2)  # => "1000"
    # ParseOptions::DTDVALID.to_s(2) # => "10000"
    # ```
    #
    # Any of these constants may be used alone to specify a single option:
    #
    # ```
    # ParseOptions.new(ParseOptions::DTDLOAD)
    # # => #<Nokogiri::XML::ParseOptions: ... strict, dtdload>
    # ParseOptions.new(ParseOptions::DTDATTR)
    # # => #<Nokogiri::XML::ParseOptions: ... strict, dtdattr>
    # ```
    #
    # Multiple constants may be ORed together to specify multiple options:
    #
    # ```
    # options = ParseOptions::BIG_LINES | ParseOptions::COMPACT | ParseOptions::NOCDATA
    # ParseOptions.new(options)
    # # => #<Nokogiri::XML::ParseOptions: ... strict, nocdata, compact, big_lines>
    # ```
    #
    # **Note**:
    # The value of constant `STRICT` is zero;
    # it may be used alone to turn all options **off**:
    #
    # ```
    # XML.parse('<root />') {|options| puts options.inspect }
    # #<Nokogiri::XML::ParseOptions: recover, nonet, big_lines, default_schema, default_xml>
    # XML.parse('<root />', nil, nil, ParseOptions::STRICT) {|options| puts options.inspect }
    # #<Nokogiri::XML::ParseOptions: strict>
    # ```
    #
    # The single-option bitmask constants are:
    # BIG_LINES,
    # COMPACT,
    # DTDATTR,
    # DTDLOAD,
    # DTDVALID,
    # HUGE,
    # NOBASEFIX,
    # NOBLANKS,
    # NOCDATA,
    # NODICT,
    # NOENT,
    # NOERROR,
    # NONET,
    # NOWARNING,
    # NOXINCNODE,
    # NSCLEAN,
    # OLD10,
    # PEDANTIC,
    # RECOVER,
    # SAX1,
    # STRICT,
    # XINCLUDE.
    #
    # There are also several "shorthand" constants that can set multiple options:
    # DEFAULT_HTML,
    # DEFAULT_SCHEMA,
    # DEFAULT_XML,
    # DEFAULT_XSLT.
    #
    # Examples:
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
    # \Nokogiri itself uses these shorthand constants for its parsing,
    # and they are generally most suitable for \Nokogiri users' code.
    #
    # ## Options-Setting Blocks
    #
    # Many of the [parsing methods](rdoc-ref:ParseOptions@Parsing+Methods)
    # discussed here accept an options-setting block.
    #
    # The block is called with a new instance of \ParseOptions
    # created with the defaults for the specific method:
    #
    # ```
    # XML::parse(xml_s) {|options| puts options.inspect }
    # #<Nokogiri::XML::ParseOptions: @options=4196353 recover, nonet, big_lines, default_xml, default_schema>
    # HTML4::parse(html_s) {|options| puts options.inspect }
    # #<Nokogiri::XML::ParseOptions: @options=4196449 recover, nowarning, nonet, big_lines, default_html, default_xml, noerror, default_schema>
    # ```
    #
    # When the block returns, the parsing is performed using those `options`.
    #
    # The block may modify those options, which affects parsing:
    #
    # ```
    # bad_xml = '<root>'                              # End tag missing.
    # XML::parse(bad_xml)                             # No error because option RECOVER is on.
    # XML::parse(bad_xml) {|options| options.strict } # Raises SyntaxError because option STRICT is on.
    # ```
    #
    # ## Convenience Methods
    #
    # A \ParseOptions object has three sets of convenience methods,
    # each based on the name of one of the constants:
    #
    # - **Setters**: each is the downcase of an option name, and turns **on** an option:
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
    # - **Unsetters**: each begins with `no`, and turns **off** an option.
    #
    #     Note that there is no unsetter `nostrict`,
    #     but the setter `recover` serves the same purpose:
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
    #     💡 Note that some options begin with `no`, leading to the logical but perhaps unintuitive
    #     double negative:
    #
    #     ```
    #     po.nocdata # Set the NOCDATA parse option
    #     po.nonocdata # Unset the NOCDATA parse option
    #     ```
    #
    # - **Queries**: each ends with `?`, and returns whether an option is **on** or **off**:
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
    class ParseOptions
      # Strict parsing; do not recover from errors in input.
      STRICT      = 0

      # Recover from errors in input; no strict parsing.
      RECOVER     = 1 << 0

      # Substitute entities. Off by default.
      #  ⚠ This option enables entity substitution, contrary to what the name implies.
      #  ⚠ <b>It is UNSAFE to set this option</b> when parsing untrusted documents.
      NOENT       = 1 << 1

      # Load external subsets. On by default for XSLT::Stylesheet.
      #  ⚠ <b>It is UNSAFE to set this option</b> when parsing untrusted documents.
      DTDLOAD     = 1 << 2

      # Default DTD attributes. On by default for XSLT::Stylesheet.
      DTDATTR     = 1 << 3

      # Validate with the DTD. Off by default.
      DTDVALID    = 1 << 4

      # Suppress error reports. On by default for HTML4::Document and HTML4::DocumentFragment.
      NOERROR     = 1 << 5

      # Suppress warning reports.  On by default for HTML4::Document and HTML4::DocumentFragment.
      NOWARNING   = 1 << 6

      # Enable pedantic error reporting. Off by default.
      PEDANTIC    = 1 << 7

      # Remove blank nodes. Off by default.
      NOBLANKS    = 1 << 8

      # Use the SAX1 interface internally. Off by default.
      SAX1        = 1 << 9

      # Implement XInclude substitution. Off by default.
      XINCLUDE    = 1 << 10

      # Forbid network access.
      # On by default for XML::Document, XML::DocumentFragment,
      # HTML4::Document, HTML4::DocumentFragment, XSLT::Stylesheet, and XML::Schema.
      #  ⚠ <b>It is UNSAFE to unset this option</b> when parsing untrusted documents.
      NONET       = 1 << 11

      # Do not reuse the context dictionary. Off by default.
      NODICT      = 1 << 12

      # Remove redundant namespaces declarations. Off by default.
      NSCLEAN     = 1 << 13

      # Merge CDATA as text nodes. On by default for XSLT::Stylesheet.
      NOCDATA     = 1 << 14

      # Do not generate XInclude START/END nodes. Off by default.
      NOXINCNODE  = 1 << 15

      # Compact small text nodes. Off by default.
      #  ⚠ No modification of the DOM tree is allowed after parsing.
      COMPACT     = 1 << 16

      # Parse using XML-1.0 before update 5. Off by default.
      OLD10       = 1 << 17

      # Do not fixup XInclude xml:base URIs. Off by default.
      NOBASEFIX   = 1 << 18

      # Relax any hardcoded limit from the parser. Off by default.
      #  ⚠ <b>It is UNSAFE to set this option</b> when parsing untrusted documents.
      HUGE        = 1 << 19

      # Support line numbers up to `long int` (default is a `short int`).
      # On by default for for XML::Document, XML::DocumentFragment, HTML4::Document,
      # HTML4::DocumentFragment, XSLT::Stylesheet, and XML::Schema.
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

      # Returns or sets and returns the integer value of `self`:
      #
      # ```
      # options = ParseOptions.new(ParseOptions::DEFAULT_HTML)
      # # => #<Nokogiri::XML::ParseOptions: ... recover, nowarning, nonet, big_...
      # options.options # => 4196449
      # options.options = ParseOptions::STRICT
      # options.options # => 0
      # ```
      #
      attr_accessor :options

      # :markup: markdown
      #
      # :call-seq:
      #   ParseOptions.new(options = ParseOptions::STRICT)
      #
      # Returns a new \ParseOptions object with options as specified by integer argument `options`.
      # The value of `options` may be constructed
      # using [Bitmap Constants](rdoc-ref:ParseOptions@Bitmap+Constants).
      #
      # With the simple constant `ParseOptions::STRICT` (the default), all options are **off**
      # (`strict` means `norecover`):
      #
      # ```
      # ParseOptions.new
      # # => #<Nokogiri::XML::ParseOptions: ... strict>
      # ```
      #
      # With a different simple constant, one option may be set:
      #
      # ```
      # ParseOptions.new(ParseOptions::RECOVER)
      # # => #<Nokogiri::XML::ParseOptions: ... recover>
      # ParseOptions.new(ParseOptions::COMPACT)
      # # => #<Nokogiri::XML::ParseOptions:  ... strict, compact>
      # ```
      #
      # With multiple ORed constants, multiple options may be set:
      #
      # ```
      # options = ParseOptions::COMPACT | ParseOptions::RECOVER | ParseOptions::BIG_LINES
      # ParseOptions.new(options)
      # # => #<Nokogiri::XML::ParseOptions: ... recover, compact, big_lines>
      # ```
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

      # :call-seq:
      #   strict
      #
      # Turns **off** option `recover`:
      #
      # ```
      # options = ParseOptions.new.recover.compact.big_lines
      # # => #<Nokogiri::XML::ParseOptions: ... recover, compact, big_lines>
      # options.strict
      # # => #<Nokogiri::XML::ParseOptions: ... strict, compact, big_lines>
      # ```
      def strict
        @options &= ~RECOVER
        self
      end

      # :call-seq:
      #   strict?
      #
      # Returns whether option `strict` is **on**:
      #
      # ```
      # options = ParseOptions.new.recover.compact.big_lines
      # # => #<Nokogiri::XML::ParseOptions: ... recover, compact, big_lines>
      # options.strict? # => false
      # options.strict
      # # => #<Nokogiri::XML::ParseOptions: ... strict, compact, big_lines>
      # options.strict? # => true
      # ```
      def strict?
        @options & RECOVER == STRICT
      end

      # :call-seq:
      #    self == object
      #
      # Returns true if the same options are set in `self` and `object`.
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
