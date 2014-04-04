module Nokogiri
  module XML
    module BangFinders
      def at!(*args)
        node = at(*args);       raise NotFound.new(args, self) if node.nil?; node
      end

      def at_xpath!(*args)
        node = at_xpath(*args); raise NotFound.new(args, self) if node.nil?; node
      end

      def at_css!(*args)
        node = at_css(*args);   raise NotFound.new(args, self) if node.nil?; node
      end

    end

    class NotFound < StandardError
      attr_reader :message
      def initialize(needle, haystack)
        @message = "#{needle} in \n#{snippet(haystack)}"
      end
      def snippet(haystack)
        snippet = haystack.to_s
        snippet.length > 200 ? "#{snippet[0...200]}..." : snippet
      end
    end
  end
end
