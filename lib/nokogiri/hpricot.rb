require 'nokogiri'

module Nokogiri
  module Hpricot
    class << self
      def parse(*args)
        doc = Nokogiri.parse(*args)
        add_decorators(doc)
      end

      def XML(string)
        doc = Nokogiri::XML.parse(string)
        add_decorators(doc)
      end

      def add_decorators(doc)
        doc.decorators['node'] << Decorators::Hpricot
        doc.decorators['document'] << Decorators::Hpricot
        doc.decorate!
        doc
      end
    end
  end
  
  class << self
    def Hpricot(*args, &block)
      if block_given?
        builder = Nokogiri::HTML::Builder.new(&block)
        Nokogiri::Hpricot.add_decorators(builder.doc)
      else
        doc = Nokogiri::HTML.parse(*args)
        Nokogiri::Hpricot.add_decorators(doc)
      end
    end
  end
end
