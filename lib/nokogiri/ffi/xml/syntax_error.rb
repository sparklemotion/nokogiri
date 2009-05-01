module Nokogiri
  module XML
    class SyntaxError < ::Nokogiri::SyntaxError

      attr_accessor :cstruct

      def domain
        cstruct[:domain]
      end

      def code
        cstruct[:code]
      end

      def message
        cstruct[:message]
      end
      alias_method :inspect, :message
      alias_method :to_s, :message

      def level
        cstruct[:level]
      end

      def file
        cstruct[:file].null? ? nil : cstruct[:file]
      end

      def line
        cstruct[:line]
      end

      def str1
        cstruct[:str1].null? ? nil : cstruct[:str1]
      end

      def str2
        cstruct[:str].null? ? nil : cstruct[:str]
      end

      def str3
        cstruct[:str3].null? ? nil : cstruct[:str3]
      end

      def int1
        cstruct[:int1]
      end

      def column
        cstruct[:int2]
      end
      alias_method :int2, :column

      class << self
        def error_array_pusher(array)
          Proc.new do |_ignored_, error|
            array << wrap(error) if array
          end
        end

        def wrap(error_ptr)
          error_struct = LibXML::XmlSyntaxError.allocate
          LibXML.xmlCopyError(error_ptr, error_struct)
          error_cstruct = LibXML::XmlSyntaxError.new(error_struct)
          error = self.new # will generate XML::XPath::SyntaxError or XML::SyntaxError
          error.cstruct = error_cstruct
          error
        end
      end

    end
  end

end
