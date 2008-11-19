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
  module TestResponseBehavior

    def html(flavor=nil)
      if flavor == :hpricot
        @_nokogiri_html_hpricot ||= Nokogiri::Hpricot(body)
      else
        @_nokogiri_html_vanilla ||= Nokogiri::HTML(body)
      end
    end

    def xml
      @_nokogiri_xml ||= Nokogiri::XML(body)
    end

  end
end
