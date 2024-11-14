# frozen_string_literal: true

module Nokogiri
  module HTML4
    class DocumentFragment < Nokogiri::XML::DocumentFragment
      #
      # :call-seq:
      #   parse(tags) => DocumentFragment
      #   parse(tags, encoding) => DocumentFragment
      #   parse(tags, encoding, options) => DocumentFragment
      #   parse(tags, encoding) { |options| ... } => DocumentFragment
      #
      # Parse an HTML4 fragment.
      #
      # [Parameters]
      # - +tags+ (optional String, or any object that responds to +#read+ such as an IO, or
      #   StringIO)
      # - +encoding+ (optional String) the name of the encoding that should be used when processing
      #   the document.  (default +nil+ for auto-detection)
      # - +options+ (optional) configuration object that sets options during parsing, such as
      #   Nokogiri::XML::ParseOptions::RECOVER. See Nokogiri::XML::ParseOptions for more
      #   information.
      #
      # [Yields] If present, the block will be passed a Nokogiri::XML::ParseOptions object to modify
      #   before the fragment is parsed. See Nokogiri::XML::ParseOptions for more information.
      #
      # [Returns] DocumentFragment
      #
      # *Example:* Parsing a string
      #
      #   fragment = DocumentFragment.parse("<div>Hello World</div>")
      #
      # *Example:* Parsing an IO
      #
      #   fragment = File.open("fragment.html") do |file|
      #     DocumentFragment.parse(file)
      #   end
      #
      # *Example:* Specifying encoding
      #
      #   fragment = DocumentFragment.parse(input, "EUC-JP")
      #
      # *Example:* Setting parse options dynamically
      #
      #   DocumentFragment.parse("<div>Hello World") do |options|
      #     options.huge.pedantic
      #   end
      #
      def self.parse(tags, encoding = nil, options = XML::ParseOptions::DEFAULT_HTML, &block)
        doc = HTML4::Document.new

        if tags.respond_to?(:read)
          # Handle IO-like objects (IO, File, StringIO, etc.)
          # The _read_ method of these objects doesn't accept an +encoding+ parameter.
          # Encoding is usually set when the IO object is created or opened,
          # or by using the _set_encoding_ method.
          #
          # 1. If +encoding+ is provided and the object supports _set_encoding_,
          #    set the encoding before reading.
          # 2. Read the content from the IO-like object.
          #
          # Note: After reading, the content's encoding will be:
          # - The encoding set by _set_encoding_ if it was called
          # - The default encoding of the IO object otherwise
          #
          # For StringIO specifically, _set_encoding_ affects only the internal string,
          # not how the data is read out.
          tags.set_encoding(encoding) if encoding && tags.respond_to?(:set_encoding)
          tags = tags.read
        end

        encoding ||= if tags.respond_to?(:encoding)
          encoding = tags.encoding
          if encoding == ::Encoding::ASCII_8BIT
            "UTF-8"
          else
            encoding.name
          end
        else
          "UTF-8"
        end

        doc.encoding = encoding

        new(doc, tags, nil, options, &block)
      end

      # It's recommended to use either DocumentFragment.parse or XML::Node#parse rather than call this
      # method directly.
      def initialize(document, tags_ = nil, ctx_ = nil, options_ = XML::ParseOptions::DEFAULT_HTML, tags: tags_, ctx: ctx_, options: options_) # rubocop:disable Lint/MissingSuper
        return self unless tags

        options = Nokogiri::XML::ParseOptions.new(options) if Integer === options
        @parse_options = options
        yield options if block_given?

        if ctx
          preexisting_errors = document.errors.dup
          node_set = ctx.parse("<div>#{tags}</div>", options)
          node_set.first.children.each { |child| child.parent = self } unless node_set.empty?
          self.errors = document.errors - preexisting_errors
        else
          # This is a horrible hack, but I don't care
          path = if /^\s*?<body/i.match?(tags)
            "/html/body"
          else
            "/html/body/node()"
          end

          temp_doc = HTML4::Document.parse("<html><body>#{tags}", nil, document.encoding, options)
          temp_doc.xpath(path).each { |child| child.parent = self }
          self.errors = temp_doc.errors
        end
        children
      end
    end
  end
end
