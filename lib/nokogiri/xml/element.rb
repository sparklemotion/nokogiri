module Nokogiri
  module XML
    class Element

      def wrap(html)
        new_parent = document.parse(html).first
        add_next_sibling(new_parent)
        new_parent.add_child(self)
        self
      end
    end
  end
end