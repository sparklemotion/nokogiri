module Nokogiri
  module XML
    module SAX
      # :stopdoc:
      module LegacyHandlers
        def start_element_namespace name,
                                    attrs   = [],
                                    prefix  = nil,
                                    uri     = nil,
                                    ns      = []

          ##
          # Deal with legacy interface
          if @document.respond_to? :start_element_ns
            unless @warned
              warn <<-eowarn
Nokogiri::XML::SAX::Document#start_element_ns and end_element_ns are deprecated,
please change to start_element_namespace.  start_element_ns will be removed by
version 1.4.0 or by August 1st, whichever comes first.
              eowarn
              @warned = true
            end
            attr_hash = {}
            attrs.each do |attr|
              attr_hash[attr.localname] = attr.value
            end
            ns_hash = Hash[*ns.flatten]
            @document.start_element_ns name, attr_hash, prefix, uri, ns_hash
          end

          ###
          # Deal with SAX v1 interface
          name = [prefix, name].compact.join(':')
          attributes = ns.map { |ns_prefix,ns_uri|
            [['xmlns', ns_prefix].compact.join(':'), ns_uri]
          } + attrs.map { |attr|
            [[attr.prefix, attr.localname].compact.join(':'), attr.value]
          }.flatten
          @document.start_element name, attributes
        end

        def end_element_namespace name, prefix = nil, uri = nil
          ##
          # Deal with legacy interface
          if @document.respond_to? :end_element_ns
            unless @warned
              warn <<-eowarn
Nokogiri::XML::SAX::Document#start_element_ns and end_element_ns are deprecated,
please change to start_element_namespace.  start_element_ns will be removed by
version 1.4.0 or by August 1st, whichever comes first.
              eowarn
              @warned = true
            end
            @document.end_element_ns name, prefix, uri
          end

          ###
          # Deal with SAX v1 interface
          @document.end_element [prefix, name].compact.join(':')
        end
      end
      # :startdoc:
    end
  end
end
