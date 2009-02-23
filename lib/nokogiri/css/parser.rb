require 'thread'

module Nokogiri
  module CSS
    class Parser < GeneratedTokenizer
      @cache_on = true
      @cache    = {}
      @mutex    = Mutex.new

      class << self
        attr_accessor :cache_on
        alias :cache_on? :cache_on
        alias :set_cache :cache_on=

        def [] string
          return unless @cache_on
          @mutex.synchronize { @cache[string] }
        end

        def []= string, value
          return value unless @cache_on
          @mutex.synchronize { @cache[string] = value }
        end

        def clear_cache
          @mutex.synchronize { @cache = {} }
        end

        def without_cache &block
          tmp = @cache_on
          @cache_on = false
          block.call
          @cache_on = tmp
        end

        ###
        # Parse this CSS selector in +selector+.  Returns an AST.
        def parse selector
          @warned ||= false
          unless @warned
            $stderr.puts('Nokogiri::CSS::Parser.parse is deprecated, call Nokogiri::CSS.parse()')
            @warned = true
          end
          new.parse selector
        end
      end

      def initialize namespaces = {}
        @namespaces = namespaces
        super()
      end
      alias :parse :scan_str

      def xpath_for string, options={}
        v = self.class[string]
        return v if v

        args = [
          options[:prefix] || '//',
          options[:visitor] || XPathVisitor.new
        ]
        self.class[string] = parse(string).map { |ast|
          ast.to_xpath(*args)
        }
      end

      def on_error error_token_id, error_value, value_stack
        after = value_stack.compact.last
        raise SyntaxError.new("unexpected '#{error_value}' after '#{after}'")
      end
    end
  end
end
