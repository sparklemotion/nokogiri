
require 'nokogiri'
require 'nokogiri/xml/builder'
require 'nokogiri/html/builder'

module Nokogiri
  module XML
    class Node
      alias :search_without_hpricot_conversion :search
      def search(rule)
        search_path = Nokogiri::Hpricot.convert_to_xpath(rule)
        search_without_hpricot_conversion(search_path)
      end
    end
  end
end

def Nokogiri(*args, &block)
  if block_given?
    builder = Nokogiri::HTML::Builder.new
    builder.instance_eval(&block)
    return builder.doc
  end
end


module Nokogiri
  module Hpricot
    class << self
      def convert_to_xpath(rule)

        if rule =~ %r{^//}
          return ".#{rule}"
        elsif rule =~ %r{^/}
          return rule
        end

        # Shamelessly stolen from here:
        # http://www.joehewitt.com/blog/files/getElementsBySelector.js
        # Then modified to make more hpricot compatible
        rule = rule.dup
        element     = /^([#.]?)([a-z0-9\\*_-]*)((\|)([a-z0-9\\*_-]*))?/i;
        attr1       = /^\[([^\]]*)\]/i;
        attr2       = /^\[\s*([^*~$!^=\s]+)\s*([*^!$~]?=)\s*['"]?([^'"]+)['"]?\s*\]/i;
        pseudo      = /^:([a-z_-]+)(\(([^\)]*)\))?/i;
        combinator  = /^(\s*[>+\s])?/i;
        comma       = /^\s*,/i;
        comment     = /^\s*comment\(\)/

        parts = ['//', '*'];

        index = 1
        last_rule = nil

        while(rule.length > 0 && rule != last_rule)
          last_rule = rule.strip
          break unless rule.length > 0

          # Match element identifier
          if(match = rule.match(element))
            case match[1]
            when ''
              parts[index] = (match[5] == '') ? match[5] : match[2]
            when '#'
              parts << "[@id='#{match[2]}']"
            when '.'
              parts << "[contains(@class, '#{match[2]}')]"
            end
            rule = rule[match[0].length..-1]
          end

          # Match comment....  special for hpricot
          if(match = rule.match(comment))
            parts << '[child::comment()]'
            rule = rule[match[0].length..-1]
          end

          # Match attribute selectors
          if(match = rule.match(attr2))
            lhs = match[1]
            lhs = "@#{lhs.gsub(/@/, '')}" if lhs[/^[^\(\)]*$/]
            case match[2]
            when '~=', '*='
              parts << "[contains(#{lhs}, '#{match[3]}')]"
            when '$='
              parts << "[substring(#{lhs}, string-length(#{lhs}) - string-length('#{match[3]}') + 1, string-length('#{match[3]}')) = '#{match[3]}']"
            when '!='
              parts << "[not(contains(#{lhs}, '#{match[3]}'))]"
            when '^='
              parts << "[starts-with(#{lhs}, '#{match[3]}')]"
            else
              parts << "[#{lhs}='#{match[3]}']"
            end
            rule = rule[match[0].length..-1].strip
          else
            if(match = rule.match(attr1))
              lhs = match[1]
              lhs = "@#{lhs.gsub(/@/, '')}" if lhs[/^[^\(\)]*$/]
              parts << "[#{lhs}]"
              rule = rule[match[0].length..-1].strip
            end
          end

          # Match pseudo classes and pseudo elements
          while(match = rule.match(pseudo))
            case match[1]
            when 'first'
              parts << "[1]"
            when 'gt'
              parts << "[(position() - 1) > #{match[3]}]"
            when 'eq'
              parts << "[#{match[3].to_i + 1}]"
            when 'nth-child', 'nth'
              parts << "[#{match[3]}]"
            when 'last'
              parts << "[position() = last()]"
            when 'last-of-type'
              parts << "[@class][position() = last()]"
            else
              raise "unknown pseudo class '#{match[1]}'"
            end
            rule = rule[match[0].length..-1].strip
          end

          # Match combinators
          if((match = rule.match(combinator)) && match[0].length > 0)
            case match[0]
            when />/
              parts << "/"
            when /\+/
              parts << "/following-sibling::"
            else
              parts << "//"
            end
            index = parts.length
            parts << "*"
            rule = rule[match[0].length..-1].strip
          end

          if(match = rule.match(comma))
            parts += [' | ', '//', '*']
            index = parts.length - 1
            rule = rule[match[0].length..-1].strip
          end
        end
        parts.join
      end
    end
  end
end
