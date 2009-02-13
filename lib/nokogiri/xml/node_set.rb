module Nokogiri
  module XML
    class NodeSet
      include Enumerable

      attr_accessor :document

      def initialize document, list = []
        @document = document
        list.each { |x| self << x }
        yield self if block_given?
      end

      ###
      # Get the first element of the NodeSet.
      def first
        self[0]
      end

      ###
      # Get the last element of the NodeSet.
      def last
        self[length - 1]
      end

      ###
      # Is this NodeSet empty?
      def empty?
        length == 0
      end

      ###
      # Insert +datum+ before the first Node in this NodeSet
      def before datum
        first.before datum
      end

      ###
      # Insert +datum+ after the last Node in this NodeSet
      def after datum
        last.after datum
      end

      alias :<< :push

      ###
      # Unlink this NodeSet and all Node objects it contains from their
      # current context.
      def unlink
        each { |node| node.unlink }
        self
      end
      alias :remove :unlink

      ###
      # Search this document for +paths+
      def search *paths
        sub_set = NodeSet.new(document)
        document.decorate(sub_set)
        each do |node|
          node.search(*paths).each do |sub_node|
            sub_set << sub_node
          end
        end
        sub_set
      end
      alias :/ :search
      alias :xpath :search
      alias :css :search

      ###
      # If path is a string, search this document for +path+ returning the
      # first Node.  Otherwise, index in to the array with +path+.
      def at path, ns = {}
        return self[path] if path.is_a?(Numeric)
        search(path, ns).first
      end

      ###
      # Append the class attribute +name+ to all Node objects in the NodeSet.
      def add_class name
        each do |el|
          next unless el.respond_to? :get_attribute
          classes = el.get_attribute('class').to_s.split(" ")
          el.set_attribute('class', classes.push(name).uniq.join(" "))
        end
        self
      end

      ###
      # Remove the class attribute +name+ from all Node objects in the NodeSet.
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

      ###
      # Set the attribute +key+ to +value+ or the return value of +blk+
      # on all Node objects in the NodeSet.
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

      ###
      # Remove the attributed named +name+ from all Node objects in the NodeSet
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

      ###
      # Get the inner text of all contained Node objects
      def inner_text
        collect{|j| j.inner_text}.join('')
      end
      alias :text :inner_text

      ###
      # Get the inner html of all contained Node objects
      def inner_html
        collect{|j| j.inner_html}.join('')
      end

      ###
      # Wrap this NodeSet with +html+ or the results of the builder in +blk+
      def wrap(html, &blk)
        each do |j|
          new_parent = Nokogiri.make(html, &blk)
          j.parent.add_child(new_parent)
          new_parent.add_child(j)
        end
        self
      end

      def to_s
        map { |x| x.to_s }.join
      end

      def to_html *args
        map { |x| x.to_html(*args) }.join('')
      end

      def to_xhtml *args
        map { |x| x.to_xhtml(*args) }.join('')
      end

      def to_xml *args
        map { |x| x.to_xml(*args) }.join('')
      end

      alias :size :length
      alias :to_ary :to_a
    end
  end
end
