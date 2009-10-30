module Nokogiri
  module XML
    class FragmentHandler < Nokogiri::XML::SAX::Document # :nodoc:
      QNAME_REGEX = /(.*):(.*)/

      def initialize node, original_html
        @doc_started    = false
        @document       = node.document
        @stack          = [node]
        @html_eh        = node.kind_of? HTML::DocumentFragment

        # the regexes used in start_element() and characters() anchor at
        # start-of-line, but we really only want them to anchor at
        # start-of-doc. so let's only save up to the first newline.
        #
        # this implementation choice was the result of some benchmarks, if
        # you're curious: http://gist.github.com/115936
        #
        @original_html = original_html.lstrip
        newline_index = @original_html.index("\n")
        @original_html = @original_html[0,newline_index] if newline_index
      end

      def start_element name, attrs = []
        regex = @html_eh ? %r{^\s*<#{Regexp.escape(name)}}i :
                           %r{^\s*<#{Regexp.escape(name)}}

        @doc_started = true if @original_html =~ regex
        return unless @doc_started

        if match = name.match(QNAME_REGEX)
          prefix, name = match[1], match[2]
          ns = @document.root.namespace_definitions.detect { |x|
            x.prefix == prefix
          }
        else
          ns = nil
        end

        node = Element.new(name, @document)
        attrs << "" unless (attrs.length % 2) == 0
        Hash[*attrs].each do |k,v|
          node[k] = v
        end

        node.namespace = ns if ns

        @stack.last << node
        @stack << node
      end

      def characters string
        @doc_started = true if @original_html.strip =~ %r{^\s*#{Regexp.escape(string.strip)}}
        @stack.last << Text.new(string, @document)
      end

      def comment string
        @stack.last << Comment.new(@document, string)
      end

      def cdata_block string
        @stack.last << CDATA.new(@document, string)
      end

      def end_element name
        return unless @stack.last.name == name
        @stack.pop
      end
    end
  end
end
