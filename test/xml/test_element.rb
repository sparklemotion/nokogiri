require "helper"

module Nokogiri
  module XML
    class TestElementContent < Nokogiri::TestCase

      def test_wrap
        xml = '<document>
                 <thing>
                   <div class="title">important thing</div>
                 </thing>
                 <thing>
                   <div class="content">stuff</div>
                 </thing>
                 <thing>
                   <p class="blah">more stuff</div>
                 </thing>
               </document>'
        document = Nokogiri::XML(xml)
        things = document.xpath(".//thing")
        things[0].wrap("<wrapper/>")
        assert_equal 'wrapper', things[0].parent.name
        assert_equal 'thing', document.search("//wrapper").first.children[0].name
      end

    end
  end
end
