module Nokogiri
  module XML
    class NodeSet

      attr_accessor :cstruct

      def dup
        dup = LibXML.xmlXPathNodeSetMerge(nil, self.cstruct)
        set = NodeSet.allocate
        set.cstruct = LibXML::XmlNodeSet.new(dup)
        set
      end

      def length
        cstruct.pointer.null? ? 0 : cstruct[:nodeNr]
      end

      def push(node)
        raise(ArgumentError, "node must be a Nokogiri::XML::Node") unless node.is_a?(XML::Node)
        LibXML.xmlXPathNodeSetAdd(cstruct, node.cstruct)
        self
      end

      def +(node_set)
        raise(ArgumentError, "node_set must be a Nokogiri::XML::NodeSet") unless node_set.is_a?(XML::NodeSet)
        new_set_ptr = LibXML::xmlXPathNodeSetMerge(nil, self.cstruct)
        new_set_ptr = LibXML::xmlXPathNodeSetMerge(new_set_ptr, node_set.cstruct)
        
        new_set = NodeSet.allocate
        new_set.cstruct = LibXML::XmlNodeSet.new(new_set_ptr)
        new_set
      end

      def delete(node)
        raise(ArgumentError, "node must be a Nokogiri::XML::Node") unless node.is_a?(XML::Node)
        if LibXML.xmlXPathNodeSetContains(cstruct, node.cstruct) != 0
          LibXML.xmlXPathNodeSetDel(cstruct, node.cstruct)
          return node
        end
        return nil
      end

      def [](*args)
        raise(ArgumentError, "got #{args.length} arguments, expected 1 (or 2)") if args.length > 2

        if args.length == 2
          beg = args[0]
          len = args[1]
          beg += cstruct[:nodeNr] if beg < 0
          return subseq(beg, len)
        end
        arg = args[0]

        return subseq(arg.first, arg.last) if arg.is_a?(Range)

        index_at(arg)
      end
      alias_method :slice, :[]

      def to_a
        cstruct.nodeTab.collect { |node| Node.wrap(node) }
      end

      def unlink
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

      def self.new document, list = []
        set = allocate
        set.document = document
        set.cstruct = LibXML::XmlNodeSet.new(LibXML.xmlXPathNodeSetCreate(nil))
        list.each { |x| set << x }
        yield set if block_given?
        set
      end

      private

      def index_at(number)
        return nil if (number >= cstruct[:nodeNr] || number.abs > cstruct[:nodeNr])
        number = number + cstruct[:nodeNr] if number < 0
        Node.wrap(cstruct.nodeTab[number])
      end

      def subseq(beg, len)
        return nil if beg > cstruct[:nodeNr]
        return nil if beg < 0 || len < 0

        nodetab = cstruct.nodeTab
        set = self.class.allocate
        set.cstruct = LibXML::XmlNodeSet.new(LibXML.xmlXPathNodeSetCreate(nil))
        beg.upto(beg+len-1) do |j|
          LibXML.xmlXPathNodeSetAdd(set.cstruct, nodetab[j]);
        end
        set
      end

    end
  end
end
