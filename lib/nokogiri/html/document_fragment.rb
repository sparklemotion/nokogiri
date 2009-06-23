module Nokogiri
  module HTML
    class DocumentFragment < Nokogiri::XML::DocumentFragment

      class << self
        ####
        # Create a Nokogiri::XML::DocumentFragment from +tags+
        def parse tags
          self.new(HTML::Document.new, tags)
        end
      end

    end
  end
end
