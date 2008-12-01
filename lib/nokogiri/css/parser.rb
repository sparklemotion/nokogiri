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

        def set_cache setting
          @cache_on = setting ? true : false
        end

        def cache_on?
          @cache ||= {}
          instance_variable_defined?('@cache_on') ? @cache_on : true
        end

        def check_cache string
          return unless cache_on?
          @cache[string]
        end

        def add_cache string, value
          return value unless cache_on?
          @cache[string] = value
        end

        def clear_cache
          @cache = {}
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
