module Nokogiri
  module XML
    module PP
      module CharacterData
        def pretty_print pp
          nice_name = self.class.name.split('::').last
          pp.group(2, "#(#{nice_name} ", ')') do
            pp.pp text
          end
        end
      end
    end
  end
end
