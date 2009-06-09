module Nokogiri
  module XML
    ####
    # A NodeSet contains a list of Nokogiri::XML::Node objects.  Typically
    # a NodeSet is return as a result of searching a Document via
    # Nokogiri::XML::Node#css or Nokogiri::XML::Node#xpath
    class NodeSet
      include Enumerable

      # The Document this NodeSet is associated with
      attr_accessor :document

      # Create a NodeSet with +document+ defaulting to +list+
      def initialize document, list = []
        @document = document
        list.each { |x| self << x }
        yield self if block_given?
      end

      ###
      # Get the first element of the NodeSet.
      def first n = nil
        return self[0] unless n
        list = []
        0.upto(n - 1) do |i|
          list << self[i]
        end
        list
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
      # Returns the index of the first node in self that is == to +node+. Returns nil if no match is found. 
      def index(node)
        each_with_index { |member, j| return j if member == node }
        nil
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
      alias :remove :unlink

      ###
      # Search this document for +paths+
      #
      # For more information see Nokogiri::XML::Node#css and
      # Nokogiri::XML::Node#xpath
      def search *paths
        ns = paths.last.is_a?(Hash) ? paths.pop :
          (document.root ? document.root.namespaces : {})

        sub_set = NodeSet.new(document)
        each do |node|
          paths.each do |path|
            sub_set +=
              send(path =~ /^(\.\/|\/)/ ? :xpath : :css, *(paths + [ns]))
          end
        end
        document.decorate(sub_set)
        sub_set
      end
      alias :/ :search

      ###
      # Search this NodeSet for css +paths+
      #
      # For more information see Nokogiri::XML::Node#css
      def css *paths
        ns = paths.last.is_a?(Hash) ? paths.pop :
          (document.root ? document.root.namespaces : {})

        sub_set = NodeSet.new(document)

        xpaths = paths.map { |rule|
          [
            CSS.xpath_for(rule.to_s, :prefix => ".//", :ns => ns),
            CSS.xpath_for(rule.to_s, :prefix => "self::", :ns => ns)
          ].join(' | ')
        }
        each do |node|
          sub_set += node.xpath(*(xpaths + [ns]))
        end
        document.decorate(sub_set)
        sub_set
      end

      ###
      # Search this NodeSet for XPath +paths+
      #
      # For more information see Nokogiri::XML::Node#xpath
      def xpath *paths
        ns = paths.last.is_a?(Hash) ? paths.pop :
          (document.root ? document.root.namespaces : {})

        sub_set = NodeSet.new(document)
        each do |node|
          sub_set += node.xpath(*(paths + [ns]))
        end
        document.decorate(sub_set)
        sub_set
      end

      ###
      # If path is a string, search this document for +path+ returning the
      # first Node.  Otherwise, index in to the array with +path+.
      def at path, ns = document.root ? document.root.namespaces : {}
        return self[path] if path.is_a?(Numeric)
        search(path, ns).first
      end
      alias :% :at

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
        0.upto(length - 1) do |x|
          yield self[x]
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

      ###
      # Convert this NodeSet to a string.
      def to_s
        map { |x| x.to_s }.join
      end

      ###
      # Convert this NodeSet to HTML
      def to_html *args
        map { |x| x.to_html(*args) }.join
      end

      ###
      # Convert this NodeSet to XHTML
      def to_xhtml *args
        map { |x| x.to_xhtml(*args) }.join
      end

      ###
      # Convert this NodeSet to XML
      def to_xml *args
        map { |x| x.to_xml(*args) }.join
      end

      alias :size :length
      alias :to_ary :to_a

      ###
      # Removes the last element from set and returns it, or +nil+ if
      # the set is empty
      def pop
        return nil if length == 0
        delete last
      end

      ###
      # Returns the first element of the NodeSet and removes it.  Returns
      # +nil+ if the set is empty.
      def shift
        return nil if length == 0
        delete first
      end

      ###
      # Equality -- Two NodeSets are equal if the contain the same number
      # of elements and if each element is equal to the corresponding
      # element in the other NodeSet
      def == other
        return false unless other.is_a?(Nokogiri::XML::NodeSet)
        return false unless length == other.length
        each_with_index do |node, i|
          return false unless node == other[i]
        end
        true
      end
    end
  end
end
