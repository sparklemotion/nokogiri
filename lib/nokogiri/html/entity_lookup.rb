module Nokogiri
  module HTML
    class EntityDescription < Struct.new(:value, :name, :description); end

    class EntityLookup
      def [] name
        (val = get(name)) && val.value
      end
    end
  end
end
