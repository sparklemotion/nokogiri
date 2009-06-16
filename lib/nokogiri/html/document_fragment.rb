module Nokogiri
  module HTML
    class DocumentFragment < Nokogiri::XML::DocumentFragment

      class << self
        ####
        # Create a Nokogiri::XML::DocumentFragment from +tags+
        def parse tags
          HTML::DocumentFragment.new(HTML::Document.new, tags)
        end
      end

    end
  end
end
