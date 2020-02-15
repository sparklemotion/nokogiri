require "helper"

module Nokogiri
  class TestSlop < Nokogiri::TestCase
    SLOP_HTML = <<~END
      <html>
        <body>
          <ul>
            <li class='red'>one</li>
            <li class='blue'>two</li>
          </ul>
          <div>
            one
            <div>div two</div>
          </div>
        </body>
      </html>
    END

    def test_slop
      doc = Nokogiri::Slop(SLOP_HTML)

      assert_equal "one", doc.html.body.ul.li.first.text
      assert_equal "two", doc.html.body.ul.li(".blue").text
      assert_equal "div two", doc.html.body.div.div.text

      assert_equal "two", doc.html.body.ul.li(:css => ".blue").text

      assert_equal "two", doc.html.body.ul.li(:xpath => "position()=2").text
      assert_equal "one", doc.html.body.ul.li(:xpath => ["contains(text(),'o')"]).first.text
      assert_equal "two", doc.html.body.ul.li(:xpath => ["contains(text(),'o')", "contains(text(),'t')"]).text

      assert_raise(NoMethodError) { doc.nonexistent }
    end

    def test_slop_decorator
      doc = Nokogiri(SLOP_HTML)
      assert !doc.decorators(Nokogiri::XML::Node).include?(Nokogiri::Decorators::Slop)

      doc.slop!
      assert doc.decorators(Nokogiri::XML::Node).include?(Nokogiri::Decorators::Slop)

      doc.slop!
      assert_equal 1, doc.decorators(Nokogiri::XML::Node).select { |d| d == Nokogiri::Decorators::Slop }.size
    end

    def test_slop_css
      doc = Nokogiri::Slop(<<-eohtml)
        <html>
          <body>
            <div>
              one
              <div class='foo'>
                div two
                <div class='foo'>
                  div three
                </div>
              </div>
            </div>
          </body>
        </html>
      eohtml
      assert_equal "div", doc.html.body.div.div(".foo").name
    end

    def test_description_tag
      doc = Nokogiri.Slop(<<-eoxml)
        <item>
          <title>foo</title>
          <description>this is the foo thing</description>
        </item>
      eoxml

      assert doc.item.respond_to?(:title)
      assert_equal "foo", doc.item.title.text

      assert doc.item.respond_to?(:_description), "should have description"
      assert_equal "this is the foo thing", doc.item._description.text

      assert !doc.item.respond_to?(:foo)
      assert_raise(NoMethodError) { doc.item.foo }
    end
  end
end
