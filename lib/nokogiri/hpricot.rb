require 'nokogiri'

module Nokogiri
  module Hpricot
    class << self
      def parse(*args)
        doc = Nokogiri.parse(*args)
        doc.extend(Decorators::Hpricot)
        doc.decorators['node'] << Decorators::Hpricot
        doc.decorators['document'] << Decorators::Hpricot
        doc.decorate!
        doc
      end

      def XML(string)
        doc = Nokogiri::XML.parse(string)
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
        doc = builder.doc
        doc.decorators['node'] << Decorators::Hpricot
        doc.decorators['document'] << Decorators::Hpricot
        doc.decorate!
        return doc
      else
        doc = Nokogiri::HTML.parse(*args)
        doc.decorators['node'] << Decorators::Hpricot
        doc.decorators['document'] << Decorators::Hpricot
        doc.decorate!
        doc
      end
    end
  end

end
