module Nokogiri
  module HTML
    class DocumentFragment < Nokogiri::XML::DocumentFragment

      class << self
        ####
        # Create a Nokogiri::XML::DocumentFragment from +tags+
        def parse tags
          doc = HTML::Document.new
          doc.encoding = 'UTF-8'
          self.new(doc, tags)
        end
      end

    end
  end
end
