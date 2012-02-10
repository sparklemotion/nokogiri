module Nokogiri
  module Decorators
    ###
    # The Slop decorator implements method missing such that a methods may be
    # used instead of XPath or CSS.  See Nokogiri.Slop
    module Slop
      ###
      # look for node with +name+.  See Nokogiri.Slop
      def method_missing name, *args, &block
        prefix = implied_xpath_context

        if args.empty?
          s_name = name =~ /\?$/ ? name.to_s.chop! : name.to_s
          list = xpath("#{prefix}#{s_name.sub(/^_/, '')}")
          return !list.empty? if name.to_s != s_name 
        elsif args.first.is_a? Hash
          hash = args.first
          if hash[:css]
            list = css("#{name}#{hash[:css]}")
          elsif hash[:xpath]
            conds = Array(hash[:xpath]).join(' and ')
            list = xpath("#{prefix}#{name}[#{conds}]")
          end
        else
          CSS::Parser.without_cache do
            list = xpath(
              *CSS.xpath_for("#{name}#{args.first}", :prefix => prefix)
            )
          end
        end

        super if list.empty?
        list.length == 1 ? list.first : list
      end
      ###
      # look for node with +name+
      def respond_to?(name)
        super || self.send(name.to_s << '?')
      end
    end
  end
end
