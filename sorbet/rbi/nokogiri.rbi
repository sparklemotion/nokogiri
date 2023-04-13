
# classes defined in the native extension
class Nokogiri::XML::Element < Nokogiri::XML::Node
end

class Nokogiri::XML::CharacterData < Nokogiri::XML::Node
end

class Nokogiri::XML::Comment < Nokogiri::XML::CharacterData
end
