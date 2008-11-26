module Nokogiri
  module Decorators
    module Explorable
      def method_missing name, *args, &block
        results = xpath "./#{name}"
        super if results.empty?
        results.length == 1 ? results.first : results
      end
    end
  end
end
