module Nokogiri
  module LibXML # :nodoc:

    module XmlDocumentMixin # :nodoc:
      def self.included(base)
        base.class_eval do

          layout(
            :_private,  :pointer,
            :type,      :int,
            :name,      :string,
            :children,  :pointer,
            :last,      :pointer,
            :parent,    :pointer,
            :next,      :pointer,
            :prev,      :pointer,
            :doc,       :pointer,

            :compression,       :int,
            :standalone,        :int,
            :intSubset,         :pointer,
            :extSubset,         :pointer,
            :oldNs,             :pointer,
            :version,           :string,
            :encoding,          :pointer,
            :ids,               :pointer,
            :refs,              :pointer,
            :URL,               :string
            )

        end
      end

      def document
        p = self[:doc]
        p.null? ? nil : LibXML::XmlDocumentCast.new(p)
      end

      def ruby_doc
        ptr = self[:_private]
        return nil if ptr.null?
        ObjectSpace._id2ref(ptr.get_long(0))
      end

      def ruby_doc=(object)
        self[:_private].put_long(0, object.object_id)
      end

      def node_set
        LibXML::XmlNodeSetCast.new(self[:_private].get_pointer(FFI.type_size(:pointer)))
      end

      def alloc_tuple
        self[:_private] = LibXML.calloc(FFI.type_size(:pointer), 2)
        self[:_private].put_pointer(FFI.type_size(:pointer), LibXML.xmlXPathNodeSetCreate(nil))
      end
    end

    #
    #  use at the point of creation, so we can be sure the document will be GCed properly
    #
    class XmlDocument < FFI::ManagedStruct # :nodoc:
      include XmlDocumentMixin

      def initialize(ptr)
        super(ptr)
        self.alloc_tuple
      end

      def self.release ptr
        doc = LibXML::XmlDocumentCast.new(ptr)
        func = LibXML.xmlDeregisterNodeDefault(nil)
        begin
          ns  = LibXML::XmlNodeSetCast.new(doc[:_private].get_pointer(LibXML.pointer_offset(1)))

          ns[:nodeNr].times do |j|
            node_cstruct = LibXML::XmlNode.new(ns[:nodeTab].get_pointer(LibXML.pointer_offset(j)))
            case node_cstruct[:type]
            when Nokogiri::XML::Node::ATTRIBUTE_NODE
              LibXML.xmlFreePropList(node_cstruct)
            else
              LibXML.xmlAddChild(doc, node_cstruct) if node_cstruct[:parent].null?
            end
          end
          LibXML::XmlNodeSet.release(ns.pointer)

          LibXML.free(doc[:_private])
        rescue
          puts "Nokogiri::LibXML::XmlDocument.release: exception: '#{$!}'"
        ensure
          LibXML.xmlFreeDoc(ptr)
          LibXML.xmlDeregisterNodeDefault(func)
        end
      end
    end

    #
    #  use when we don't want to cause the doc to be GCed
    #
    class XmlDocumentCast < FFI::Struct # :nodoc:
      include XmlDocumentMixin
    end

    HtmlDocument = XmlDocument # implemented identically in libxml2.6
    HtmlDocumentCast = XmlDocumentCast # implemented identically in libxml2.6
  end

end
