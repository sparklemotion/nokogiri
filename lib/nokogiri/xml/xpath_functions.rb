module Nokogiri
  module XML
    class XPathFunctions
      @@handler = nil
      class << self
        def handler
          @@handler ||= create_handler
        end

        ###
        # call-seq: define :sym, &block
        #
        # Define a new global XPath function.
        #
        #   Nokogiri::XML::XPathFunctions.define(:regex) do |node_set, regex|
        #     node_set.find_all { |node| node['some_attribute'] =~ /#{regex}/ }
        #   end
        #
        #   node.xpath('.//title[regex(., "\w+")]')
        # 
        # Any custom handler passed to Node#xpath the normal way will override
        # the default internal handler. Passing +nil+ will evaluate the expression
        # with no custom function handler at all.
        #
        def define sym, &block
          handler.__class__.send(:define_method, sym, &block)
        end
        
        ###
        # call-seq: undef :sym
        #
        # Undefine a previously-defined global XPath function.
        #
        #   Nokogiri::XML::XPathFunctions.undef(:regex)
        # 
        def undef sym
          handler.__class__.send(:undef_method, sym)
        end
        
        ###
        # call-seq: reset!
        #
        # Reset the global XPath function handler to its default state
        # (i.e., no user-defined functions)
        #
        #   Nokogiri::XML::XPathFunctions.reset!
        # 
        def reset!
          @@handler = nil
        end

        ###
        # Create a handler class with NO normal methods but the bare
        # necessities: #send and #method_missing.
        # 
        # All other methods will be aliased as __#{method}__ and invoked
        # via #method_missing if they haven't been overridden via #define
        def create_handler
          klazz = Class.new
          klazz.instance_methods.each do |method|
            unless method =~ /(^__)|(^send$)/
              klazz.send(:alias_method,:"__#{method}__", method.to_sym)
              klazz.send(:undef_method,method.to_sym)
            end
          end
          klazz.send(:define_method, :method_missing) do |sym, *args|
            if sym.to_s =~ /^__(.+)__$/
              super $1.to_sym, *args
            else
              self.send(:"__#{sym.to_s}__", *args)
            end
          end
          klazz.new
        end
        protected :create_handler
      end
    end
  end
end
