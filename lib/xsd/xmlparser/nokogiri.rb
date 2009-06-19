require 'nokogiri'

module XSD # :nodoc:
  module XMLParser # :nodoc:
    ###
    # Nokogiri XML parser for soap4r.
    #
    # Nokogiri may be used as the XML parser in soap4r.  Simply require
    # 'xsd/xmlparser/nokogiri' in your soap4r applications, and soap4r
    # will use Nokogiri as it's XML parser.  No other changes should be
    # required to use Nokogiri as the XML parser.
    #
    # Example (using UW ITS Web Services):
    #
    #   require 'rubygems'
    #   gem 'soap4r'
    #   require 'nokogiri'
    #   require 'defaultDriver'
    #   require 'xsd/xmlparser/nokogiri'
    #
    #   obj = AvlPortType.new
    #   obj.getLatestByRoute(obj.getAgencies, 8).each do |event|
    #     ...
    #   end
    class Nokogiri < XSD::XMLParser::Parser
      ###
      # Create a new XSD parser with +host+ and +opt+
      def initialize host, opt = {}
        super
        @parser = ::Nokogiri::XML::SAX::Parser.new(self, @charset || 'UTF-8')
      end

      ###
      # Start parsing +string_or_readable+
      def do_parse string_or_readable
        @parser.parse(string_or_readable)
      end

      def start_element_ns *args
        p args
      end

      ###
      # Handle the start_element event with +name+ and +attrs+
      def start_element name, attrs = []
        super(name, Hash[*attrs.flatten])
      end

      def end_element name
        super
      end

      ###
      # Handle errors with message +msg+
      def error msg
        raise ParseError.new(msg)
      end
      alias :warning :error

      ###
      # Handle cdata_blocks containing +string+
      def cdata_block string
        characters string
      end

      %w{ start_document start_element_ns end_element_ns end_document comment }.each do |name|
        class_eval %{ def #{name}(*args); end }
      end
      add_factory(self)
    end
  end
end
