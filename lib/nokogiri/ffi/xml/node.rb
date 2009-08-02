module Nokogiri
  module XML
    class Node
      # :stopdoc:

      attr_accessor :cstruct

      def pointer_id
        cstruct.pointer
      end

      def encode_special_chars(string)
        char_ptr = LibXML.xmlEncodeSpecialChars(self[:doc], string)
        encoded = char_ptr.read_string
        # TODO: encoding?
        LibXML.xmlFree(char_ptr)
        encoded
      end

      def internal_subset
        return nil if cstruct[:doc].null?
        doc = cstruct.document
        dtd = LibXML.xmlGetIntSubset(doc)
        return nil if dtd.null?
        Node.wrap(dtd)
      end

      def dup(deep = 1)
        dup_ptr = LibXML.xmlDocCopyNode(cstruct, cstruct.document, deep)
        return nil if dup_ptr.null?
        Node.wrap(dup_ptr, self.class)
      end

      def unlink
        LibXML.xmlUnlinkNode(cstruct)
        cstruct.keep_reference_from_document!
        self
      end

      def blank?
        LibXML.xmlIsBlankNode(cstruct) == 1
      end

      def next_sibling
        cstruct_node_from :next
      end

      def previous_sibling
        cstruct_node_from :prev
      end

      def replace_with_node(new_node)
        LibXML.xmlReplaceNode(cstruct, new_node.cstruct)
        Node.send(:relink_namespace, new_node.cstruct)
        self
      end

      def children
        return NodeSet.new(nil) if cstruct[:children].null?
        child = Node.wrap(cstruct[:children])

        set = NodeSet.new child.document
        set_ptr = LibXML.xmlXPathNodeSetCreate(child.cstruct)
        
        set.cstruct = LibXML::XmlNodeSet.new(set_ptr)
        return set unless child

        child_ptr = child.cstruct[:next]
        while ! child_ptr.null?
          child = Node.wrap(child_ptr)
          LibXML.xmlXPathNodeSetAdd(set.cstruct, child.cstruct)
          child_ptr = child.cstruct[:next]
        end

        return set
      end

      def child
        (val = cstruct[:children]).null? ? nil : Node.wrap(val)
      end

      def key?(attribute)
        ! (prop = LibXML.xmlHasProp(cstruct, attribute.to_s)).null?
      end

      def namespaced_key?(attribute, namespace)
        prop = LibXML.xmlHasNsProp(cstruct, attribute.to_s,
          namespace.nil? ? nil : namespace.to_s)
        prop.null? ? false : true
      end

      def []=(property, value)
        LibXML.xmlSetProp(cstruct, property, value)
        value
      end

      def get(attribute)
        return nil unless attribute
        propstr = LibXML.xmlGetProp(cstruct, attribute.to_s)
        return nil if propstr.null?
        rval = propstr.read_string # TODO: encoding?
        LibXML.xmlFree(propstr)
        rval
      end

      def set_namespace(namespace)
        LibXML.xmlSetNs(cstruct, namespace.cstruct)
        self
      end

      def attribute(name)
        raise "Node#attribute not implemented yet"
      end

      def attribute_with_ns(name, namespace)
        prop = LibXML.xmlHasNsProp(cstruct, name.to_s,
          namespace.nil? ? NULL : namespace.to_s)
        return prop if prop.null?
        Node.wrap(prop)
      end

      def attribute_nodes
        Node.node_properties cstruct
      end

      def namespace
        cstruct[:ns].null? ? nil : Namespace.wrap(cstruct.document, cstruct[:ns])
      end

      def namespace_definitions
        list = []
        ns_ptr = cstruct[:nsDef]
        return list if ns_ptr.null?
        while ! ns_ptr.null?
          ns = Namespace.wrap(cstruct.document, ns_ptr)
          list << ns
          ns_ptr = ns.cstruct[:next]
        end
        list
      end

      def node_type
        cstruct[:type]
      end

      def native_content=(content)
        LibXML.xmlNodeSetContent(cstruct, content)
        content
      end

      def content
        content_ptr = LibXML.xmlNodeGetContent(cstruct)
        return nil if content_ptr.null?
        content = content_ptr.read_string # TODO: encoding?
        LibXML.xmlFree(content_ptr)
        content
      end

      def add_child(child)
        Node.reparent_node_with(child, self) do |child_cstruct, my_cstruct|
          LibXML.xmlAddChild(my_cstruct, child_cstruct)
        end
      end

      def parent
        cstruct_node_from :parent
      end

      def node_name=(string)
        LibXML.xmlNodeSetName(cstruct, string)
        string
      end

      def node_name
        cstruct[:name] # TODO: encoding?
      end

      def path
        path_ptr = LibXML.xmlGetNodePath(cstruct)
        val = path_ptr.null? ? nil : path_ptr.read_string # TODO: encoding?
        LibXML.xmlFree(path_ptr)
        val
      end

      def add_next_sibling(next_sibling)
        Node.reparent_node_with(next_sibling, self) do |sibling_cstruct, my_cstruct|
          LibXML.xmlAddNextSibling(my_cstruct, sibling_cstruct)
        end
      end

      def add_previous_sibling(prev_sibling)
        Node.reparent_node_with(prev_sibling, self) do |sibling_cstruct, my_cstruct|
          LibXML.xmlAddPrevSibling(my_cstruct, sibling_cstruct)
        end
      end

      def native_write_to(io, encoding, indent_string, options)
        set_xml_indent_tree_output 1
        set_xml_tree_indent_string indent_string
        savectx = LibXML.xmlSaveToIO(IoCallbacks.writer(io), nil, nil, encoding, options)
        LibXML.xmlSaveTree(savectx, cstruct)
        LibXML.xmlSaveClose(savectx)
        io
      end

      def line
        cstruct[:line]
      end

      def add_namespace_definition(prefix, href)
        ns = LibXML.xmlNewNs(cstruct, href, prefix)
        if ns.null?
          ns = LibXML.xmlSearchNs(cstruct.document, cstruct,
            prefix.nil? ? nil : prefix.to_s)
        end
        LibXML.xmlSetNs(cstruct, ns) if prefix.nil?
        Namespace.wrap(cstruct.document, ns)
      end

      def self.new(name, doc, *rest)
        ptr = LibXML.xmlNewNode(nil, name.to_s)

        node_cstruct = LibXML::XmlNode.new(ptr)
        node_cstruct[:doc] = doc.cstruct[:doc]
        node_cstruct.keep_reference_from_document!

        node = Node.wrap(
          node_cstruct,
          Node == self ? nil : self
        )
        node.send :initialize, name, doc, *rest
        yield node if block_given?
        node
      end

      def dump_html
        return to_xml if type == DOCUMENT_NODE
        buffer = LibXML::XmlBuffer.new(LibXML.xmlBufferCreate())
        LibXML.htmlNodeDump(buffer, cstruct[:doc], cstruct)
        buffer[:content] # TODO: encoding?
      end

      def compare(other)
        LibXML.xmlXPathCmpNodes(other.cstruct, self.cstruct)
      end

      def self.wrap(node_struct, klass=nil)
        if node_struct.is_a?(FFI::Pointer)
          # cast native pointers up into a node cstruct
          return nil if node_struct.null?
          node_struct = LibXML::XmlNode.new(node_struct)
        end

        raise "wrapping a node without a document" unless node_struct.document

        document_struct = node_struct.document
        document_obj = document_struct.nil? ? nil : document_struct.ruby_doc
        if node_struct[:type] == DOCUMENT_NODE || node_struct[:type] == HTML_DOCUMENT_NODE
          return document_obj
        end

        ruby_node = node_struct.ruby_node
        return ruby_node unless ruby_node.nil?

        klasses = case node_struct[:type]
                  when ELEMENT_NODE then [XML::Element]
                  when TEXT_NODE then [XML::Text]
                  when ENTITY_REF_NODE then [XML::EntityReference]
                  when COMMENT_NODE then [XML::Comment]
                  when DOCUMENT_FRAG_NODE then [XML::DocumentFragment]
                  when PI_NODE then [XML::ProcessingInstruction]
                  when ATTRIBUTE_NODE then [XML::Attr]
                  when ENTITY_DECL then [XML::EntityDeclaration]
                  when CDATA_SECTION_NODE then [XML::CDATA]
                  when DTD_NODE then [XML::DTD, LibXML::XmlDtd]
                  else [XML::Node]
                  end

        if klass
          node = klass.allocate
        else
          node = klasses.first.allocate
        end
        node.cstruct = klasses[1] ? klasses[1].new(node_struct.pointer) : node_struct

        node.cstruct.ruby_node = node

        if document_obj
          node.instance_variable_set(:@document, document_obj)
          cache = document_obj.instance_variable_get(:@node_cache)
          cache << node
          document_obj.decorate(node)
        end

        node
      end

      def document
        cstruct.document.ruby_doc
      end

      class << self
        def node_properties(cstruct)
          attr = []
          prop_cstruct = cstruct[:properties]
          while ! prop_cstruct.null?
            prop = Node.wrap(prop_cstruct)
            attr << prop
            prop_cstruct = prop.cstruct[:next]
          end
          attr
        end
      end

      private

      def self.reparent_node_with(node, other, &block)
        raise(ArgumentError, "node must be a Nokogiri::XML::Node") unless node.is_a?(Nokogiri::XML::Node)

        # If a document fragment is added, we need to reparent all of it's
        # children
        if node.type == DOCUMENT_FRAG_NODE
          node.children.each do |child|
            reparent_node_with(child, other, &block)
          end
          return node
        end

        if node.cstruct[:doc] == other.cstruct[:doc]
          LibXML.xmlUnlinkNode(node.cstruct)
          if node.type == TEXT_NODE && other.type == TEXT_NODE && Nokogiri.is_2_6_16?
            other.cstruct.pointer.put_pointer(other.cstruct.offset_of(:content), LibXML.xmlStrdup(other.cstruct[:content]))
          end
          reparented_struct = block.call(node.cstruct, other.cstruct)
          raise(RuntimeError, "Could not reparent node (1)") unless reparented_struct
        else
          duped_node = LibXML.xmlDocCopyNode(node.cstruct, other.cstruct.document, 1)
          raise(RuntimeError, "Could not reparent node (xmlDocCopyNode)") unless duped_node
          reparented_struct = block.call(duped_node, other.cstruct)
          raise(RuntimeError, "Could not reparent node (2)") unless reparented_struct
          LibXML.xmlUnlinkNode(node.cstruct)
          node.cstruct.keep_reference_from_document!
        end

        reparented_struct = LibXML::XmlNode.new(reparented_struct)

        # the child was a text node that was coalesced. we need to have the object
        # point at SOMETHING, or we'll totally bomb out.
        if reparented_struct != node.cstruct
          node.cstruct = reparented_struct
        end

        relink_namespace reparented_struct

        reparented = Node.wrap(reparented_struct)
        reparented.decorate!
        reparented
      end

      def self.relink_namespace(reparented_struct)
        # Make sure that our reparented node has the correct namespaces
        if reparented_struct[:doc] != reparented_struct[:parent]
          LibXML.xmlSetNs(reparented_struct, LibXML::XmlNode.new(reparented_struct[:parent])[:ns])
        end

        # Search our parents for an existing definition
        if ! reparented_struct[:nsDef].null?
          ns = LibXML.xmlSearchNsByHref(
            reparented_struct[:doc],
            reparented_struct[:parent],
            LibXML::XmlNs.new(reparented_struct[:nsDef])[:href]
            )
          reparented_struct[:nsDef] = nil unless ns.null?
        end

        # Only walk all children if there actually is a namespace we need to reparent.
        return if reparented_struct[:ns].null?

        # When a node gets reparented, walk it's children to make sure that
        # their namespaces are reparented as well.
        child_ptr = reparented_struct[:children]
        while ! child_ptr.null?
          child_struct = LibXML::XmlNode.new(child_ptr) 
          relink_namespace child_struct
          child_ptr = child_struct[:next]
        end
      end

      def cstruct_node_from(sym)
        (val = cstruct[sym]).null? ? nil : Node.wrap(val)
      end

      def set_xml_indent_tree_output(value)
        LibXML.__xmlIndentTreeOutput.write_int(value)
      end

      def set_xml_tree_indent_string(value)
        LibXML.__xmlTreeIndentString.write_pointer(LibXML.xmlStrdup(value.to_s))
      end

      # :startdoc:
    end
  end
end
