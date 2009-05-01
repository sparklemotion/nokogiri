module Nokogiri
  module XML
    class NodeSet

      attr_accessor :cstruct

      def dup
        dup = LibXML.xmlXPathNodeSetCreate(nil)
        cstruct.nodeTab.each do |node|
          LibXML.xmlXPathNodeSetAdd(dup, node)
        end
        
        set = NodeSet.allocate
        set.cstruct = LibXML::XmlNodeSet.new(dup)
        set
      end

      def length
        cstruct.pointer.null? ? 0 : cstruct[:nodeNr]
      end

      def push(node)
        raise ArgumentError("node must be a Nokogiri::XML::Node") unless node.is_a?(XML::Node)
        LibXML.xmlXPathNodeSetAdd(cstruct, node.cstruct)
        self
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
