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
        cstruct[:nodeNr].times do |j|
          if cstruct.nodeTab[j].address == node.cstruct.pointer.address
            LibXML.xmlXPathNodeSetRemove(cstruct, j)
            return node
          end
        end        
        return nil
      end

      def [](number)
        return nil if (number >= cstruct[:nodeNr] || number.abs > cstruct[:nodeNr])
        number = number + cstruct[:nodeNr] if number < 0
        Node.wrap(cstruct.nodeTab[number])
      end

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

    end
  end
end
