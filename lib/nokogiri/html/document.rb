module Nokogiri
  module HTML
    class Document < Nokogiri::XML::Document

      def initialize *args
        super
      end

      ####
      # Serialize this Document with +encoding+ using +options+
      def serialize *args
        if args.first && !args.first.is_a?(Hash)
          $stderr.puts(<<-eowarn)
#{self.class}#serialize(encoding, save_opts) is deprecated and will be removed in
Nokogiri version 1.4.0 *or* after June 1 2009.
You called serialize from here:

  #{caller.join("\n")}

Please change to #{self.class}#serialize(:encoding => enc, :save_with => opts)
          eowarn
        end

        options = args.first.is_a?(Hash) ? args.shift : {
          :encoding   => args[0],
          :save_with  => args[1] || XML::Node::SaveOptions::FORMAT |
            XML::Node::SaveOptions::AS_HTML |
            XML::Node::SaveOptions::NO_DECLARATION |
            XML::Node::SaveOptions::NO_EMPTY_TAGS
        }
        super(options)
      end

      ####
      # Create a Nokogiri::XML::DocumentFragment from +tags+
      def fragment tags
        DocumentFragment.new(self, tags)
      end

      class << self
        ###
        # Parse HTML.  +thing+ may be a String, or any object that
        # responds to _read_ and _close_ such as an IO, or StringIO.
        # +url+ is resource where this document is located.  +encoding+ is the
        # encoding that should be used when processing the document. +options+
        # is a number that sets options in the parser, such as
        # Nokogiri::XML::PARSE_RECOVER.  See the constants in
        # Nokogiri::XML.
        def parse string_or_io, url = nil, encoding = nil, options = 2145, &block

          options = Nokogiri::XML::ParseOptions.new(options) if Fixnum === options
          # Give the options to the user
          yield options if block_given?

          if string_or_io.respond_to?(:encoding)
            encoding ||= string_or_io.encoding.name
          end

          if string_or_io.respond_to?(:read)
            url ||= string_or_io.respond_to?(:path) ? string_or_io.path : nil
            return self.read_io(string_or_io, url, encoding, options.to_i)
          end

          return self.new if(string_or_io.length == 0)
          self.read_memory(string_or_io, url, encoding, options.to_i)
        end
      end

    end
  end
end
