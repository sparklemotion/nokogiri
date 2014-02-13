module Nokogiri
  module XML
    module BangFinders

      def at!(*args)
        at(*args).tap       { |v| raise Nokogiri::XML::NotFound if v.nil? }
      end

      def at_xpath!(*args)
        at_xpath(*args).tap { |v| raise Nokogiri::XML::NotFound if v.nil? }
      end

      def at_css!(*args)
        at_css(*args).tap   { |v| raise Nokogiri::XML::NotFound if v.nil? }
      end
    end

    NotFound = Class.new(StandardError)
  end
end
