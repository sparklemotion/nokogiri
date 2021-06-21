# frozen_string_literal: true
module Nokogiri
  class << self
    ###
    # Create a Nokogiri::XSLT::Stylesheet with +stylesheet+.
    #
    # Example:
    #
    #   xslt = Nokogiri::XSLT(File.read(ARGV[0]))
    #
    def XSLT stylesheet, modules = {}
      XSLT.parse(stylesheet, modules)
    end
  end

  ###
  # See Nokogiri::XSLT::Stylesheet for creating and manipulating
  # Stylesheet object.
  module XSLT
    class << self
      ###
      # Parse the stylesheet in +string+, register any +modules+
      def parse(string, modules = {})
        modules.each do |url, klass|
          XSLT.register(url, klass)
        end

        doc = XML::Document.parse(string, nil, nil, XML::ParseOptions::DEFAULT_XSLT)
        if Nokogiri.jruby?
          Stylesheet.parse_stylesheet_doc(doc, string)
        else
          Stylesheet.parse_stylesheet_doc(doc)
        end
      end

      ###
      # Quote parameters in +params+ for stylesheet safety
      def quote_params(params)
        parray = (params.instance_of?(Hash) ? params.to_a.flatten : params).dup
        parray.each_with_index do |v, i|
          parray[i] = if i % 2 > 0
            if v =~ /'/
              "concat('#{v.gsub(/'/, %q{', "'", '})}')"
            else
              "'#{v}'"
            end
          else
            v.to_s
          end
        end
        parray.flatten
      end
    end
  end
end

require_relative "xslt/stylesheet"
