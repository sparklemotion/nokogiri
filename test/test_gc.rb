require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TestGc < Nokogiri::TestCase

  def test_dont_hurt_em_why
    content = File.open("#{File.dirname(__FILE__)}/files/dont_hurt_em_why.xml").read
    ndoc = Nokogiri::XML(content)
    2.times do
      info = ndoc.search('status text').first.inner_text
      url = ndoc.search('user name').first.inner_text
      GC.start
    end
  end

end
