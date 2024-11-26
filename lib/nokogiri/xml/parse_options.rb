# coding: utf-8
# frozen_string_literal: true

module Nokogiri
  module XML
    # :markup: markdown
    #
    # \Class to house parsing options.
    #
    # ## Methods That Use \XML::ParseOptions
    #
    # These methods use \XML::ParseOptions:
    #
    # - Nokogiri.parse (but only when _not_ parsing HTML5).
    # - HTML4.parse.
    # - HTML4.parse.
    # - HTML4::Document.parse.
    # - HTML4::DocumentFragment.parse.
    # - XML.parse.
    # - XML::Document.parse.
    # - XML::DocumentFragment.parse.
    #
    # Certain other parsing methods use different options;
    # see HTML5.
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
    # # => #<Nokogiri::XML::ParseOptions:0x00000198119ca3d8 ... strict, compact>
    # options = ParseOptions::COMPACT | ParseOptions::NOBLANKS
    # ParseOptions.new(options)
    # # => #<Nokogiri::XML::ParseOptions:0x0000019811d5f098 ... strict, noblanks, compact>
    # ```
    #
    # The bitmask constants are:
    #
    # | Constant | Default | Meaning |
    # |------|:-------:|---------|
    # | BIG_LINES | **On** | Store big lines numbers in text PSVI field. |
    # | COMPACT | **Off** | Compact small text nodes; no modification of the tree allowed afterwards (will possibly crash if you try to modify the tree). |
    # | DTDATTR | See Note 1. | Default DTD attributes. |
    # | DTDLOAD | See Note 1. | Load the external subset. |
    # | DTDVALID | **Off** | Validate with the DTD. |
    # | HUGE | **Off** | Relax any hardcoded limit from the parser. |
    # | NOBASEFIX | **Off** | Do not fixup XINCLUDE xml:base uris. |
    # | NOBLANKS | **Off** | Remove blank nodes. |
    # | NOCDATA | See Note 1. | Merge CDATA as text nodes. |
    # | NODICT | **Off** | Do not reuse the context dictionary. |
    # | NOENT | **Off** | Substitute entities. |
    # | NOERROR | **On** | Suppress error reports. |
    # | NONET | See Note 2. | Forbid network access. |
    # | NOWARNING | **On** | Suppress warning reports. |
    # | NOXINCNODE | **Off** | Do not generate XINCLUDE START/END nodes. |
    # | NSCLEAN | **Off** | Remove redundant namespaces declarations. |
    # | OLD10 | Off| Parse using XML-1.0 before update 5. |
    # | PEDANTIC | **Off** | Pedantic error reporting. |
    # | RECOVER | See Note 2. | Recover from errors in input; no strict parsing. |
    # | SAX1 | **Off** | Use the SAX1 interface internally. |
    # | STRICT | **Off** | Use strict parsing; do not recover from errors in input. See Note 3. |
    # | XINCLUDE | **Off** | Implement XInclude substitution. |
    #
    # <br>
    #
    # Notes:
    #
    # 1. **On** only for XSLT::Stylesheet; **off** otherwise.
    # 2. **On** by default for XML::Document, XML::DocumentFragment, HTML4::Document,
    #    HTML4::DocumentFragment, XSLT::Stylesheet, and XML::Schema; **off** otherwise.
    # 3. The numeric value of constant `STRICT` is zero.
    #    Therefore using it alone sets all options to **off**;
    #    ORing it with other non-zero constants is useless:
    #
    #    ```
    #
    #    ```
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
    # - DEFAULT_HTML
    # - DEFAULT_SCHEMA
    # - DEFAULT_XML
    # - DEFAULT_XSLT
    #
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
    # ## Setting and unsetting parse options
    #
    # You can build your own combinations of parse options by using any of the following methods:
    #
    # [ParseOptions method chaining]
    #
    #   Every option has an equivalent method in lowercase. You can chain these methods together to
    #   set various combinations.
    #
    #     # Set the HUGE & PEDANTIC options
    #     po = Nokogiri::XML::ParseOptions.new.huge.pedantic
    #     doc = Nokogiri::XML::Document.parse(xml, nil, nil, po)
    #
    #   Every option has an equivalent <code>no{option}</code> method in lowercase. You can call these
    #   methods on an instance of ParseOptions to unset the option.
    #
    #     # Set the HUGE & PEDANTIC options
    #     po = Nokogiri::XML::ParseOptions.new.huge.pedantic
    #
    #     # later we want to modify the options
    #     po.nohuge # Unset the HUGE option
    #     po.nopedantic # Unset the PEDANTIC option
    #
    #   💡 Note that some options begin with "no" leading to the logical but perhaps unintuitive
    #   double negative:
    #
    #     po.nocdata # Set the NOCDATA parse option
    #     po.nonocdata # Unset the NOCDATA parse option
    #
    #   💡 Note that negation is not available for STRICT, which is itself a negation of all other
    #   features.
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
      # Strict parsing; all options (including `recover`) **off**.
      STRICT      = 0

      # Recover from errors. On by default for XML::Document, XML::DocumentFragment,
      # HTML4::Document, HTML4::DocumentFragment, XSLT::Stylesheet, and XML::Schema.
      RECOVER     = 1 << 0

      # Substitute entities. Off by default.
      #
      # ⚠ This option enables entity substitution, contrary to what the name implies.
      #
      # ⚠ <b>It is UNSAFE to set this option</b> when parsing untrusted documents.
      NOENT       = 1 << 1

      # Load external subsets. On by default for XSLT::Stylesheet.
      #
      # ⚠ <b>It is UNSAFE to set this option</b> when parsing untrusted documents.
      DTDLOAD     = 1 << 2

      # Default DTD attributes. On by default for XSLT::Stylesheet.
      DTDATTR     = 1 << 3

      # Validate with the DTD. Off by default.
      DTDVALID    = 1 << 4

      # Suppress error reports. On by default for HTML4::Document and HTML4::DocumentFragment
      NOERROR     = 1 << 5

      # Suppress warning reports. On by default for HTML4::Document and HTML4::DocumentFragment
      NOWARNING   = 1 << 6

      # Enable pedantic error reporting. Off by default.
      PEDANTIC    = 1 << 7

      # Remove blank nodes. Off by default.
      NOBLANKS    = 1 << 8

      # Use the SAX1 interface internally. Off by default.
      SAX1        = 1 << 9

      # Implement XInclude substitution. Off by default.
      XINCLUDE    = 1 << 10

      # Forbid network access. On by default for XML::Document, XML::DocumentFragment,
      # HTML4::Document, HTML4::DocumentFragment, XSLT::Stylesheet, and XML::Schema.
      #
      # ⚠ <b>It is UNSAFE to unset this option</b> when parsing untrusted documents.
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
      #
      # ⚠ No modification of the DOM tree is allowed after parsing. libxml2 may crash if you try to
      # modify the tree.
      COMPACT     = 1 << 16

      # Parse using XML-1.0 before update 5. Off by default
      OLD10       = 1 << 17

      # Do not fixup XInclude xml:base uris. Off by default
      NOBASEFIX   = 1 << 18

      # Relax any hardcoded limit from the parser. Off by default.
      #
      # ⚠ <b>It is UNSAFE to set this option</b> when parsing untrusted documents.
      HUGE        = 1 << 19

      # Support line numbers up to <code>long int</code> (default is a <code>short int</code>). On
      # by default for for XML::Document, XML::DocumentFragment, HTML4::Document,
      # HTML4::DocumentFragment, XSLT::Stylesheet, and XML::Schema.
      BIG_LINES   = 1 << 22

      # The options mask used by default for parsing XML::Document and XML::DocumentFragment
      DEFAULT_XML  = RECOVER | NONET | BIG_LINES

      # The options mask used by default used for parsing XSLT::Stylesheet
      DEFAULT_XSLT = RECOVER | NONET | NOENT | DTDLOAD | DTDATTR | NOCDATA | BIG_LINES

      # The options mask used by default used for parsing HTML4::Document and HTML4::DocumentFragment
      DEFAULT_HTML = RECOVER | NOERROR | NOWARNING | NONET | BIG_LINES

      # The options mask used by default used for parsing XML::Schema
      DEFAULT_SCHEMA = NONET | BIG_LINES

      attr_accessor :options

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

      def strict
        @options &= ~RECOVER
        self
      end

      def strict?
        @options & RECOVER == STRICT
      end

      def ==(other)
        other.to_i == to_i
      end

      alias_method :to_i, :options

      # :markup: markdown
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
      # # => "#<Nokogiri::XML::ParseOptions:0x0000020700c199f0 @options=4194304 strict, big_lines>"
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
