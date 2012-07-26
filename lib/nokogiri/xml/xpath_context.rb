module Nokogiri
  module XML
    class XPathContext

      ###
      # Register namespaces in +namespaces+
      def register_namespaces(namespaces)
        namespaces.each do |k, v|
          k = k.dup if k.frozen?
          begin
            k = k.gsub(/.*:/,'') # strip off 'xmlns:' or 'xml:'
          rescue Encoding::CompatibilityError
            k = k.force_encoding('UTF-8')
            retry
          end
          register_ns(k, v)
        end
      end

    end
  end
end
