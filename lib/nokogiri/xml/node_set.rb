module Nokogiri
  module XML
    class NodeSet
      include Enumerable

      def first
        self[0]
      end

      def last
        self[length - 1]
      end

      def << node
        push(node)
      end

      def search path
        sub_set = NodeSet.new
        each do |node|
          node.search(path).each do |sub_node|
            sub_set << sub_node
          end
        end
        sub_set
      end

      def add_class name
        each do |el|
          next unless el.respond_to? :get_attribute
          classes = el.get_attribute('class').to_s.split(" ")
          el.set_attribute('class', classes.push(name).uniq.join(" "))
        end
        self
      end

      def remove_class name = nil
        each do |el|
          next unless el.respond_to? :get_attribute
          if name
            classes = el.get_attribute('class').to_s.split(" ")
            el.set_attribute('class', (classes - [name]).uniq.join(" "))
          else
            el.remove_attribute("class")
          end
        end
        self
      end

      def attr key, value = nil, &blk
        if value or blk
          each do |el|
            el.set_attribute(key, value || blk[el])
          end
          return self      
        end    
        if key.is_a? Hash
          key.each { |k,v| self.attr(k,v) }
          return self
        else
          return self[0].get_attribute(key)
        end
      end
      alias_method :set, :attr

      def remove_attr name
        each do |el|
          next unless el.respond_to? :remove_attribute
          el.remove_attribute(name)
        end
        self      
      end

      ###
      # Iterate over each node, yielding  to +block+
      def each(&block)
        x = 0
        while x < length
          yield self[x]
          x += 1
        end
      end

      def inner_text
        collect{|j| j.inner_text}.join('')
      end
      alias :text :inner_text
    end
  end
end
