module Nokogiri
  module HTML
    class ElementDescription

      attr_accessor :cstruct

      def required_attributes
        get_string_array_from :attrs_req
      end

      def deprecated_attributes
        get_string_array_from :attrs_depr
      end

      def optional_attributes
        get_string_array_from :attrs_opt
      end

      def default_sub_element
        cstruct[:defaultsubelt]
      end

      def sub_elements
        get_string_array_from :subelts
      end

      def description
        cstruct[:desc]
      end

      def inline?
        cstruct[:isinline] != 0
      end

      def deprecated?
        cstruct[:depr] != 0
      end

      def empty?
        cstruct[:empty] != 0
      end

      def save_end_tag?
        cstruct[:saveEndTag] != 0
      end

      def implied_end_tag?
        cstruct[:endTag] != 0
      end

      def implied_start_tag?
        cstruct[:startTag] != 0
      end

      def name
        cstruct[:name]
      end

      def self.[](tag_name)
        ptr = LibXML.htmlTagLookup(tag_name)
        return nil if ptr.null?

        desc = allocate
        desc.cstruct = LibXML::HtmlElemDesc.new(ptr)
        desc
      end

      private

      def get_string_array_from(sym)
        list = []
        return list if cstruct[sym].null?

        j = 0
        while (ptr = cstruct[sym].get_pointer(j * FFI.type_size(:pointer))) && ! ptr.null?
          list << ptr.read_string
          j += 1
        end

        list
      end

    end
  end
end
