module Nokogiri
  module Decorators
    module Hpricot
      module NodeSet

        # Select nodes matching the supplied rule.
        # Note that positional rules (like <tt>:nth()</tt>) aren't currently supported.
        #
        # example:
        #   node_set.filter('.ohmy')          # selects nodes from the set with class "ohmy"
        #   node_set.filter('a#link2')        # selects nodes from the set with child node <a id='link2'>
        #   node_set.filter('a[@id="link2"]') # selects nodes from the set with child node <a id='link2'>
        def filter(rule)
          filter_transformer( lambda {|j| j}, rule ) # identity transformer
        end

        # The complement to filter, select nodes <em>not</em> matching the supplied rule.
        # Note that positional rules (like <tt>:nth()</tt>) aren't currently supported.
        #
        # See filter for examples.
        #
        # Also note that you can pass a XML::Node object instead of a
        # rule to remove that object from the node set (if it is
        # present):
        #    node_set.not(node_to_exclude) # selects all nodes EXCEPT node_to_exclude
        #
        def not(rule)
          filter_transformer( lambda {|j| !j}, rule ) # negation transformer
        end

      private
        def filter_transformer(transformer, rule) # :nodoc:
          sub_set = XML::NodeSet.new(document)
          document.decorate(sub_set)

          if rule.is_a?(XML::Node)
            each { |node| sub_set << node if transformer.call(node == rule) }
            return sub_set
          end

          ctx = CSS.parse(rule.to_s)
          visitor = CSS::XPathVisitor.new
          visitor.extend(Hpricot::XPathVisitor)
          each do |node|
            if transformer.call(node.at(".//self::" + visitor.accept(ctx.first)))
              sub_set << node
            end
          end
          sub_set
        end
      end
    end
  end
end
