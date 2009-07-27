require 'nokogiri'

#
#  to use this in your Rails view or controller tests, simply:
#
#  require 'action-nokogiri'
#
#  class KittehControllerTest < ActionController::TestCase
#  def test_i_can_does_test_with_nokogiri
#    get(:index, {:wants => "cheezburgers"})
#    assert @response.html.at("h2.lolcats")
#  end
#
module ActionController
  module TestResponseBehavior # :nodoc:

    ###
    # Get your response as a Nokogiri::XML::Document using the
    # Nokogiri.HTML parser
    def html(flavor=nil)
      warn "@response.html is deprecated and will be removed in nokogiri 1.4.0"
      if flavor == :hpricot
        @_nokogiri_html_hpricot ||= Nokogiri::Hpricot(body)
      else
        @_nokogiri_html_vanilla ||= Nokogiri::HTML(body)
      end
    end

    ###
    # Get your response as a Nokogiri::XML::Document using the
    # Nokogiri.XML parser
    def xml
      warn "@response.html is deprecated and will be removed in nokogiri 1.4.0"
      @_nokogiri_xml ||= Nokogiri::XML(body)
    end

  end
end
