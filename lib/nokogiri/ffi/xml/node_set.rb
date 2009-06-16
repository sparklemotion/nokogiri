module Nokogiri
  module XML
    class NodeSet

      attr_accessor :cstruct # :nodoc:

      def dup # :nodoc:
        dup = LibXML.xmlXPathNodeSetMerge(nil, self.cstruct)
        NodeSet.wrap(dup)
      end

      def length # :nodoc:
        cstruct.pointer.null? ? 0 : cstruct[:nodeNr]
      end

      def push(node) # :nodoc:
        raise(ArgumentError, "node must be a Nokogiri::XML::Node") unless node.is_a?(XML::Node)
        LibXML.xmlXPathNodeSetAdd(cstruct, node.cstruct)
        self
      end

      def +(node_set) # :nodoc:
        raise(ArgumentError, "node_set must be a Nokogiri::XML::NodeSet") unless node_set.is_a?(XML::NodeSet)
        new_set_ptr = LibXML::xmlXPathNodeSetMerge(nil, self.cstruct)
        new_set_ptr = LibXML::xmlXPathNodeSetMerge(new_set_ptr, node_set.cstruct)
        NodeSet.wrap(new_set_ptr)
      end

      def -(node_set) # :nodoc:
        raise(ArgumentError, "node_set must be a Nokogiri::XML::NodeSet") unless node_set.is_a?(XML::NodeSet)
        new_set_ptr = LibXML.xmlXPathNodeSetMerge(nil, self.cstruct)

        other_nodetab = node_set.cstruct.nodeTab
        node_set.cstruct[:nodeNr].times do |j|
          LibXML.xmlXPathNodeSetDel(new_set_ptr, other_nodetab[j])
        end        
        NodeSet.wrap(new_set_ptr)
      end

      def delete(node) # :nodoc:
        raise(ArgumentError, "node must be a Nokogiri::XML::Node") unless node.is_a?(XML::Node)
        if LibXML.xmlXPathNodeSetContains(cstruct, node.cstruct) != 0
          LibXML.xmlXPathNodeSetDel(cstruct, node.cstruct)
          return node
        end
        return nil
      end

      def [](*args) # :nodoc:
        raise(ArgumentError, "got #{args.length} arguments, expected 1 (or 2)") if args.length > 2

        if args.length == 2
          beg = args[0]
          len = args[1]
          beg += cstruct[:nodeNr] if beg < 0
          return subseq(beg, len)
        end
        arg = args[0]

        return subseq(arg.first, arg.last-arg.first+1) if arg.is_a?(Range)

        index_at(arg)
      end
      alias_method :slice, :[]

      def &(node_set) # :nodoc:
        raise(ArgumentError, "node_set must be a Nokogiri::XML::NodeSet") unless node_set.is_a?(XML::NodeSet)
        new_set_ptr = LibXML.xmlXPathIntersection(cstruct, node_set.cstruct)
        NodeSet.wrap(new_set_ptr)
      end

      def include?(node) # :nodoc:
        raise(ArgumentError, "node must be a Nokogiri::XML::Node") unless node.is_a?(XML::Node)
        (LibXML.xmlXPathNodeSetContains(cstruct, node.cstruct) != 0) ? true : false
      end

      def to_a # :nodoc:
        cstruct.nodeTab.collect { |node| Node.wrap(node) }
      end

      def unlink # :nodoc:
        # TODO: is this simpler implementation viable:
        #  cstruct.nodeTab.collect {|node| Node.wrap(node)}.each(&:unlink)
        # ?
        nodetab = cstruct.nodeTab
        cstruct[:nodeNr].times do |j|
          node = Node.wrap(nodetab[j])
          node.unlink
          nodetab[j] = node.cstruct.pointer
        end
        cstruct.nodeTab = nodetab
        self
      end

      def self.new document, list = [] # :nodoc:
        set = NodeSet.wrap(LibXML.xmlXPathNodeSetCreate(nil))
        set.document = document
        list.each { |x| set << x }
        yield set if block_given?
        set
      end

      private

      def self.wrap(ptr) # :nodoc:
        set = allocate
        set.cstruct = LibXML::XmlNodeSet.new(ptr)
        set
      end

      def index_at(number) # :nodoc:
        return nil if (number >= cstruct[:nodeNr] || number.abs > cstruct[:nodeNr])
        number = number + cstruct[:nodeNr] if number < 0
        Node.wrap(cstruct.nodeAt(number))
      end

      def subseq(beg, len) # :nodoc:
        return nil if beg > cstruct[:nodeNr]
        return nil if beg < 0 || len < 0

        set = NodeSet.wrap(LibXML.xmlXPathNodeSetCreate(nil))
        beg.upto(beg+len-1) do |j|
          LibXML.xmlXPathNodeSetAdd(set.cstruct, cstruct.nodeAt(j));
        end
        set
      end

    end
  end
end
