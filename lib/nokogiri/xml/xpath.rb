module Nokogiri
  module XML
    class XPath
      class << self
        def munge_search_path(search_path)
          search_path.gsub(%r{^(//.*)},'.\1')
        end
      end
    end
  end
end
