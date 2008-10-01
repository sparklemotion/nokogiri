module Nokogiri
  module XML
    class XPathContext

      def register_namespaces(namespaces)
        namespaces.each do |k, v|
          k = k.gsub(/.*:/,'') # strip off 'xmlns:' or 'xml:'
          register_ns(k, v)
        end
      end

    end
  end
end
