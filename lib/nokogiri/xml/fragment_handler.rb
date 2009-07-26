module Nokogiri
  module XML
    class FragmentHandler < Nokogiri::XML::SAX::Document # :nodoc:
      def initialize node, original_html
        @doc_started    = false
        @document       = node.document
        @stack          = [node]
        @klass          = if node.kind_of?(Nokogiri::HTML::DocumentFragment)
                            Nokogiri::HTML::DocumentFragment
                          else
                            Nokogiri::XML::DocumentFragment
                          end
        #
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
        regex = (@klass == Nokogiri::HTML::DocumentFragment) ? %r{^\s*<#{Regexp.escape(name)}}i \
                                                             : %r{^\s*<#{Regexp.escape(name)}}
        @doc_started = true if @original_html =~ regex
        return unless @doc_started

        node = Element.new(name, @document)
        attrs << "" unless (attrs.length % 2) == 0
        Hash[*attrs].each do |k,v|
          node[k] = v
        end
        @stack.last << node
        @stack << node
      end

      def characters string
        @doc_started = true if @original_html.strip =~ %r{^\s*#{Regexp.escape(string.strip)}}
        @stack.last << Nokogiri::XML::Text.new(string, @document)
      end

      def comment string
        @stack.last << Nokogiri::XML::Comment.new(@document, string)
      end

      def cdata_block string
        @stack.last << Nokogiri::XML::CDATA.new(@document, string)
      end

      def end_element name
        return unless @stack.last.name == name
        @stack.pop
      end
    end
  end
end
