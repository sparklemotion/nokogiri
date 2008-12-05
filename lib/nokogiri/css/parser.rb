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

        def parse string
          new.parse(string)
        end

        def xpath_for string, options={}
          new.xpath_for(string, options)
        end

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
      end
      alias :parse :scan_str

      def xpath_for string, options={}
        v = self.class[string]
        return v if v

        prefix = options[:prefix] || nil
        visitor = options[:visitor] || nil
        args = [prefix, visitor]
        self.class[string] = parse(string).map { |ast|
          ast.to_xpath(prefix, visitor)
        }
      end

      def on_error error_token_id, error_value, value_stack
        after = value_stack.compact.last
        raise SyntaxError.new("unexpected '#{error_value}' after '#{after}'")
      end
    end
  end
end
