require 'nokogiri/xslt/stylesheet'

module Nokogiri
  module XSLT
    class << self
      def parse(string)
        Stylesheet.parse_stylesheet_doc(XML.parse(string))
      end
      
      def quote_params params
        parray = (params.instance_of?(Hash) ? params.to_a.flatten : params).dup
        parray.each_with_index do |v,i|
          if i % 2 > 0
            parray[i]=
              if v =~ /'/
                "concat('#{ v.gsub(/'/, %q{', "'", '}) }')"
              else
                "'#{v}'";
              end
          else
            parray[i] = v.to_s
          end
        end
        parray.flatten
      end
    end
  end
end
