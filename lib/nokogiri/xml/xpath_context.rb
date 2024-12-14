# frozen_string_literal: true

module Nokogiri
  module XML
    class XPathContext
      ###
      # Register namespaces in +namespaces+
      def register_namespaces(namespaces)
        namespaces.each do |key, value|
          key = key.to_s.gsub(/.*:/, "") # strip off 'xmlns:' or 'xml:'

          register_ns(key, value)
        end
      end

      def register_variables(binds)
        return if binds.nil?

        binds.each do |key, value|
          key = key.to_s

          register_variable(key, value)
        end
      end

      if Nokogiri.uses_libxml?
        def reset
          return unless

          @registered_namespaces.each do |key, _|
            register_ns(key, nil)
          end
          unless @registered_namespaces.empty?
            warn "Nokogiri::XML::XPathContext#reset: unexpected registered namespaces: #{@registered_namespaces.keys}"
            @registered_namespaces.clear
          end

          @registered_variables.each do |key, _|
            register_variable(key, nil)
          end
          unless @registered_variables.empty?
            warn "Nokogiri::XML::XPathContext#reset: unexpected registered variables: #{@registered_variables.keys}"
            @registered_variables.clear
          end
        end
      end
    end
  end
end
