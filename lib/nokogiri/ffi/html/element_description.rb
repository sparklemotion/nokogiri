module Nokogiri
  module HTML
    class ElementDescription

      attr_accessor :cstruct # :nodoc:

      def required_attributes # :nodoc:
        get_string_array_from :attrs_req
      end

      def deprecated_attributes # :nodoc:
        get_string_array_from :attrs_depr
      end

      def optional_attributes # :nodoc:
        get_string_array_from :attrs_opt
      end

      def default_sub_element # :nodoc:
        cstruct[:defaultsubelt]
      end

      def sub_elements # :nodoc:
        get_string_array_from :subelts
      end

      def description # :nodoc:
        cstruct[:desc]
      end

      def inline? # :nodoc:
        cstruct[:isinline] != 0
      end

      def deprecated? # :nodoc:
        cstruct[:depr] != 0
      end

      def empty? # :nodoc:
        cstruct[:empty] != 0
      end

      def save_end_tag? # :nodoc:
        cstruct[:saveEndTag] != 0
      end

      def implied_end_tag? # :nodoc:
        cstruct[:endTag] != 0
      end

      def implied_start_tag? # :nodoc:
        cstruct[:startTag] != 0
      end

      def name # :nodoc:
        cstruct[:name]
      end

      def self.[](tag_name) # :nodoc:
        ptr = LibXML.htmlTagLookup(tag_name)
        return nil if ptr.null?

        desc = allocate
        desc.cstruct = LibXML::HtmlElemDesc.new(ptr)
        desc
      end

      private

      def get_string_array_from(sym) # :nodoc:
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
