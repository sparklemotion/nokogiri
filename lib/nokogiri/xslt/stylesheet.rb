module Nokogiri
  module XSLT
    class Stylesheet
      class << self
        def wrap(ptr)
          new { |i| i.ptr = DL::XSLT::Stylesheet.new(ptr) }
        end
      end

      attr_accessor :ptr

      def initialize
        yield self if block_given?
      end

      ###
      # Apply this xslt to +document+
      def apply_to(document, params = [])
        my_params = params.dup
        my_params << nil if my_params.length == 0 || my_params.last
        ptr = DL::XSLT::Params.malloc
        ptr.params = my_params
        DL::XSLT.xsltApplyStylesheet(self, document, ptr)
      end

      def to_ptr
        ptr.to_ptr
      end

      private
      def super_serialize(document)
        #msgpt = ::DL.malloc(::DL.sizeof('P'))
        #sizep = ::DL.malloc(::DL.sizeof('I'))
        #DL::XSLT.xsltSaveResultToString(msgpt.ref, sizep, document, self)
      end
    end
  end
end
