module Nokogiri
  module CSS
    class Parser < GeneratedTokenizer
      class << self
        def parse string
          new.parse(string)
        end
        def xpath_for string, options={}
          new.xpath_for(string, options)
        end

        def cache setting
          @cache_off = setting ? false : true
        end
        alias_method :set_cache, :cache
        def cache?
          @cache ||= {}
          instance_variable_defined?('@cache_off') ? @cache_off : false
        end
        def check_cache string
          return if cache?
          @cache[string]
        end
        def add_cache string, value
          return value if cache?
          @cache[string] = value
        end
        def clear_cache
          @cache = {}
        end
      end
      alias :parse :scan_str

      def xpath_for string, options={}
        v = self.class.check_cache(string)
        return v unless v.nil?

        prefix = options[:prefix] || nil
        visitor = options[:visitor] || nil
        args = [prefix, visitor]
        self.class.add_cache(string, parse(string).map {|ast| ast.to_xpath(prefix, visitor)})
      end

      def on_error error_token_id, error_value, value_stack
        after = value_stack.compact.last
        raise SyntaxError.new("unexpected '#{error_value}' after '#{after}'")
      end
    end
  end
end
