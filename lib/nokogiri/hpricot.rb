require 'nokogiri'

module Nokogiri
  module Hpricot
    class << self
      def parse(*args)
        doc = Nokogiri.parse(*args)
        doc.extend(Decorators::Hpricot)
        (doc.node_decorators ||= []) << Decorators::Hpricot
        doc
      end

      def XML(string)
        doc = Nokogiri::XML.parse(string)
        (doc.node_decorators ||= []) << Decorators::Hpricot
        doc.decorate!
        doc
      end
    end
  end
  
  def Hpricot(*args, &block)
    if block_given?
      builder = Nokogiri::HTML::Builder.new(&block)
      return builder.doc
    else
      doc = Nokogiri::HTML.parse(*args)
      (doc.node_decorators ||= []) << Decorators::Hpricot
      doc.decorate!
      doc
    end
  end

end
