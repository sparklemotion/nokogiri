module Nokogiri
  module XML
    class Attr < Node
      alias :value :content
      alias :to_s :content
      alias :content= :value=
    end
  end
end
