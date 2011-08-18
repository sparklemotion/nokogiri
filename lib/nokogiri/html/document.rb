module Nokogiri
  module HTML
    class Document < Nokogiri::XML::Document
      ###
      # Get the meta tag encoding for this document.  If there is no meta tag,
      # then nil is returned.
      def meta_encoding
        meta = meta_content_type and
          /charset\s*=\s*([\w-]+)/i.match(meta['content'])[1]
      end

      ###
      # Set the meta tag encoding for this document.  If there is no meta
      # content tag, the encoding is not set.
      def meta_encoding= encoding
        meta = meta_content_type and
          meta['content'] = "text/html; charset=%s" % encoding
      end

      def meta_content_type
        css('meta[@http-equiv]').find { |node|
          node['http-equiv'] =~ /\AContent-Type\z/i
        }
      end
      private :meta_content_type

      ###
      # Get the title string of this document.  Return nil if there is
      # no title tag.
      def title
        title = at('title') and title.inner_text
      end

      ###
      # Set the title string of this document.  If there is no head
      # element, the title is not set.
      def title=(text)
        unless title = at('title')
          head = at('head') or return nil
          title = Nokogiri::XML::Node.new('title', self)
          head << title
        end
        title.children = XML::Text.new(text, self)
      end

      ####
      # Serialize Node using +options+.  Save options can also be set using a
      # block. See SaveOptions.
      #
      # These two statements are equivalent:
      #
      #  node.serialize(:encoding => 'UTF-8', :save_with => FORMAT | AS_XML)
      #
      # or
      #
      #   node.serialize(:encoding => 'UTF-8') do |config|
      #     config.format.as_xml
      #   end
      #
      def serialize options = {}
        options[:save_with] ||= XML::Node::SaveOptions::DEFAULT_HTML
        super
      end

      ####
      # Create a Nokogiri::XML::DocumentFragment from +tags+
      def fragment tags = nil
        DocumentFragment.new(self, tags, self.root)
      end

      class << self
        ###
        # Parse HTML.  +string_or_io+ may be a String, or any object that
        # responds to _read_ and _close_ such as an IO, or StringIO.
        # +url+ is resource where this document is located.  +encoding+ is the
        # encoding that should be used when processing the document. +options+
        # is a number that sets options in the parser, such as
        # Nokogiri::XML::ParseOptions::RECOVER.  See the constants in
        # Nokogiri::XML::ParseOptions.
        def parse string_or_io, url = nil, encoding = nil, options = XML::ParseOptions::DEFAULT_HTML

          options = Nokogiri::XML::ParseOptions.new(options) if Fixnum === options
          # Give the options to the user
          yield options if block_given?

          if string_or_io.respond_to?(:encoding)
            unless string_or_io.encoding.name == "ASCII-8BIT"
              encoding ||= string_or_io.encoding.name
            end
          end

          if string_or_io.respond_to?(:read)
            url ||= string_or_io.respond_to?(:path) ? string_or_io.path : nil
            if !encoding
              # Libxml2's parser has poor support for encoding
              # detection.  First, it does not recognize the HTML5
              # style meta charset declaration.  Secondly, even if it
              # successfully detects an encoding hint, it does not
              # re-decode or re-parse the preceding part which may be
              # garbled.
              #
              # EncodingReader aims to perform advanced encoding
              # detection beyond what Libxml2 does, and to emulate
              # rewinding of a stream and make Libxml2 redo parsing
              # from the start when an encoding hint is found.
              string_or_io = EncodingReader.new(string_or_io)
              begin
                return read_io(string_or_io, url, encoding, options.to_i)
              rescue EncodingFound => e
                encoding = e.found_encoding
              end
            end
            return read_io(string_or_io, url, encoding, options.to_i)
          end

          # read_memory pukes on empty docs
          return new if string_or_io.nil? or string_or_io.empty?

          encoding ||= EncodingReader.detect_encoding(string_or_io)

          read_memory(string_or_io, url, encoding, options.to_i)
        end
      end

      class EncodingFound < StandardError # :nodoc:
        attr_reader :found_encoding

        def initialize(encoding)
          @found_encoding = encoding
          super("encoding found: %s" % encoding)
        end
      end

      class EncodingReader # :nodoc:
        class SAXHandler < Nokogiri::XML::SAX::Document # :nodoc:
          def initialize(jumptag)
            @jumptag = jumptag
            super()
          end

          def found(encoding)
            throw @jumptag, encoding
          end

          def not_found
            found nil
          end

          def start_element(name, attrs = [])
            case name
            when /\A(?:div|h1|img|p|br)\z/
              not_found
            when 'meta'
              attr = Hash[attrs]
              charset = attr['charset'] and
                found charset
              http_equiv = attr['http-equiv'] and
                http_equiv.match(/\AContent-Type\z/i) and
                content = attr['content'] and
                m = content.match(/;\s*charset\s*=\s*([\w-]+)/) and
                found m[1]
            end
          end
        end

        def self.detect_encoding(chunk)
          m = chunk.match(/\A(<\?xml[ \t\r\n]+[^>]*>)/) and
            return Nokogiri.XML(m[1]).encoding

          if Nokogiri.jruby?
            m = chunk.match(/(<meta\s)(.*)(charset\s*=\s*([\w-]+))(.*)/i) and
              return m[4]
          end

          catch(*if RUBY_VERSION < '1.9' then :encoding_found end) { |tag|
            Nokogiri::HTML::SAX::Parser.new(SAXHandler.new(tag)).parse(chunk)
            nil
          }
        rescue Nokogiri::SyntaxError, RuntimeError
          # Ignore parser errors that nokogiri may raise
          nil
        end

        def initialize(io)
          @io = io
          @firstchunk = nil
          @encoding_found = nil
        end

        # This method is used by the C extension so that
        # Nokogiri::HTML::Document#read_io() does not leak memory when
        # EncodingFound is raised.
        attr_reader :encoding_found

        def read(len)
          # no support for a call without len

          if !@firstchunk
            @firstchunk = @io.read(len) or return nil

            # This implementation expects that the first call from
            # htmlReadIO() is made with a length long enough (~1KB) to
            # achieve advanced encoding detection.
            if encoding = EncodingReader.detect_encoding(@firstchunk)
              # The first chunk is stored for the next read in retry.
              raise @encoding_found = EncodingFound.new(encoding)
            end
          end
          @encoding_found = nil

          ret = @firstchunk.slice!(0, len)
          if (len -= ret.length) > 0
            rest = @io.read(len) and ret << rest
          end
          if ret.empty?
            nil
          else
            ret
          end
        end
      end
    end
  end
end
