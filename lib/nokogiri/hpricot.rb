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
    end
  end

  def XML(string)
    doc = Nokogiri::XML.parse(string)
    (doc.node_decorators ||= []) << Decorators::Hpricot
    doc.decorate!
    doc
  end

  def Hpricot(*args, &block)
    if block_given?
      builder = Nokogiri::HTML::Builder.new
      builder.instance_eval(&block)
      return builder.doc
    end
  end
end
