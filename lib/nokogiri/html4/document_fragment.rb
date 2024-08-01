# frozen_string_literal: true

module Nokogiri
  module HTML4
    class DocumentFragment < Nokogiri::XML::DocumentFragment
      ####
      # Parse HTML fragment. +tags+ may be a String, or any object that
      # responds to _read_ and _close_ such as an IO, or StringIO.
      #
      # +encoding+ is the encoding that should be used when processing the document.
      # If not specified, it will be automatically detected.
      #
      # +options+ is a number that sets options in the parser, such as
      # Nokogiri::XML::ParseOptions::DEFAULT_HTML. See the constants in
      # Nokogiri::XML::ParseOptions.
      #
      # This method returns a new DocumentFragment. If a block is given, it will be
      # passed to the new DocumentFragment as an argument.
      #
      # Examples:
      #   fragment = DocumentFragment.parse("<div>Hello World</div>")
      #
      #   file = File.open("fragment.html")
      #   fragment = DocumentFragment.parse(file)
      #
      #   fragment = DocumentFragment.parse("<div>こんにちは世界</div>", "UTF-8")
      #
      #   DocumentFragment.parse("<div>Hello World") do |fragment|
      #     puts fragment.at_css("div").content
      #   end
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

      def initialize(document, tags = nil, ctx = nil, options = XML::ParseOptions::DEFAULT_HTML) # rubocop:disable Lint/MissingSuper
        return self unless tags

        options = Nokogiri::XML::ParseOptions.new(options) if Integer === options
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
