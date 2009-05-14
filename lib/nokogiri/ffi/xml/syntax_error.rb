module Nokogiri
  module XML
    class SyntaxError < ::Nokogiri::SyntaxError

      attr_accessor :cstruct # :nodoc:

      def domain # :nodoc:
        cstruct[:domain]
      end

      def code # :nodoc:
        cstruct[:code]
      end

      def message # :nodoc:
        cstruct[:message]
      end
      undef_method :inspect
      alias_method :inspect, :message
      undef_method :to_s
      alias_method :to_s, :message

      def level # :nodoc:
        cstruct[:level]
      end

      def file # :nodoc:
        cstruct[:file].null? ? nil : cstruct[:file]
      end

      def line # :nodoc:
        cstruct[:line]
      end

      def str1 # :nodoc:
        cstruct[:str1].null? ? nil : cstruct[:str1]
      end

      def str2 # :nodoc:
        cstruct[:str].null? ? nil : cstruct[:str]
      end

      def str3 # :nodoc:
        cstruct[:str3].null? ? nil : cstruct[:str3]
      end

      def int1 # :nodoc:
        cstruct[:int1]
      end

      def column # :nodoc:
        cstruct[:int2]
      end
      alias_method :int2, :column

      class << self
        def error_array_pusher(array) # :nodoc:
          Proc.new do |_ignored_, error|
            array << wrap(error) if array
          end
        end

        def wrap(error_ptr) # :nodoc:
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
