# frozen_string_literal: true

require "helper"

describe Nokogiri::CSS do
  describe "integration tests" do
    let(:subject) do
      subject_class.parse(<<~HTML)
        <html><body>
          <table>
            <tr><td>row1 </td></tr>
            <tr><td>row2 </td></tr>
            <tr><td>row3 </td></tr>
            <tr><td>row4 </td></tr>
            <tr><td>row5 </td></tr>
            <tr><td>row6 </td></tr>
            <tr><td>row7 </td></tr>
            <tr><td>row8 </td></tr>
            <tr><td>row9 </td></tr>
            <tr><td>row10 </td></tr>
            <tr><td>row11 </td></tr>
            <tr><td>row12 </td></tr>
            <tr><td>row13 </td></tr>
            <tr><td>row14 </td></tr>
          </table>
          <div>
            <b>bold1 </b>
            <i>italic1 </i>
            <b class="a">bold2 </b>
            <em class="a">emphasis1 </em>
            <i>italic2 </i>
            <p>para1 </p>
            <b class="a">bold3 </b>
          </div>
          <div>
            <i class="b">italic3 </i>
            <em>emphasis2 </em>
            <i class="b">italic4 </i>
            <em>emphasis3 </em>
            <i class="c">italic5 </i>
            <span><i class="b">italic6 </i></span>
            <i>italic7 </i>
          </div>
          <div>
            <p>para2 </p>
            <p>para3 </p>
          </div>
          <div>
            <p>para4 </p>
          </div>

          <div>
            <h2></h2>
            <h1 class='c'>header1 </h1>
            <h2></h2>
          </div>
          <div>
            <h1 class='c'>header2 </h1>
            <h1 class='c'>header3 </h1>
          </div>
          <div>
            <h1 class='c'>header4</h1>
          </div>

          <p class='empty'></p>
          <p class='not-empty'><b></b></p>
        </body></html>
      HTML
    end

    let(:nested) do
      subject_class.parse(<<~HTML)
        <html><body>
          <div class='unnested direct'>
            <b>bold</b>
            <p>para</p>
          </div>

          <div class='unnested indirect'>
            <b>bold</b>
            <i>...</i>
            <i>...</i>
            <p>para</p>
          </div>

          <div class='nested-parent'>
            <div class='nested-child direct'>
              <b>bold</b>
              <p>para</p>
            </div>

            <div class='nested-child indirect'>
              <b>bold</b>
              <i>...</i>
              <i>...</i>
              <p>para</p>
            </div>
          </div>

          <div class="has-bold">
            <b>bold</b>
          </div>

          <div class="has-para">
            <p>para</p>
          </div>
      HTML
    end

    def assert_result_rows(intarray, result, word = "row")
      assert_equal(
        intarray.size,
        result.size,
        "unexpected number of rows returned: '#{result.inner_text}'",
      )
      assert_equal(
        intarray.map { |j| "#{word}#{j}" }.join(" "),
        result.inner_text.strip,
        result.inner_text,
      )
    end

    doctypes = [Nokogiri::XML::Document, Nokogiri::HTML4::Document]
    doctypes << Nokogiri::HTML5::Document if defined?(Nokogiri::HTML5::Document)

    doctypes.each do |doctype|
      describe doctype do
        let(:subject_class) { doctype }

        it "selects even" do
          assert_result_rows([2, 4, 6, 8, 10, 12, 14], subject.css("table//tr:nth(even)"))
        end

        it "selects odd" do
          assert_result_rows([1, 3, 5, 7, 9, 11, 13], subject.css("table//tr:nth(odd)"))
        end

        it "selects n" do
          assert_result_rows((1..14).to_a, subject.css("table//tr:nth(n)"))
        end

        it "selects 2n" do
          assert_equal(subject.css("table//tr:nth(even)").inner_text, subject.css("table//tr:nth(2n)").inner_text)
        end

        it "selects 2np1" do
          assert_equal(subject.css("table//tr:nth(odd)").inner_text, subject.css("table//tr:nth(2n+1)").inner_text)
        end

        it "selects 4np3" do
          assert_result_rows([3, 7, 11], subject.css("table//tr:nth(4n+3)"))
        end

        it "selects 3np4" do
          assert_result_rows([4, 7, 10, 13], subject.css("table//tr:nth(3n+4)"))
        end

        it "selects mnp3" do
          assert_result_rows([1, 2, 3], subject.css("table//tr:nth(-n+3)"))
        end

        it "selects 4nm1" do
          assert_result_rows([3, 7, 11], subject.css("table//tr:nth(4n-1)"))
        end

        it "selects np3" do
          assert_result_rows([3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], subject.css("table//tr:nth(n+3)"))
        end

        it "selects first" do
          assert_result_rows([1], subject.css("table//tr:first"))
          assert_result_rows([1], subject.css("table//tr:first()"))
        end

        it "selects last" do
          assert_result_rows([14], subject.css("table//tr:last"))
          assert_result_rows([14], subject.css("table//tr:last()"))
        end

        it "selects first_child" do
          assert_result_rows([1], subject.css("div/b:first-child"), "bold")
          assert_result_rows([1], subject.css("table//tr:first-child"))
          assert_result_rows([2, 4], subject.css("div/h1.c:first-child"), "header")
        end

        it "selects last_child" do
          assert_result_rows([3], subject.css("div/b:last-child"), "bold")
          assert_result_rows([14], subject.css("table//tr:last-child"))
          assert_result_rows([3, 4], subject.css("div/h1.c:last-child"), "header")
        end

        it "selects nth_child" do
          assert_result_rows([2], subject.css("div/b:nth-child(3)"), "bold")
          assert_result_rows([5], subject.css("table//tr:nth-child(5)"))
          assert_result_rows([1, 3], subject.css("div/h1.c:nth-child(2)"), "header")
          assert_result_rows([3, 4], subject.css("div/i.b:nth-child(2n+1)"), "italic")
          assert_result_rows([3, 4], subject.css("div/i.b:nth-child(2n + 1)"), "italic")
        end

        it "selects first_of_type" do
          assert_result_rows([1], subject.css("table//tr:first-of-type"))
          assert_result_rows([1], subject.css("div/b:first-of-type"), "bold")
          assert_result_rows([2], subject.css("div/b.a:first-of-type"), "bold")
          assert_result_rows([3], subject.css("div/i.b:first-of-type"), "italic")
        end

        it "selects last_of_type" do
          assert_result_rows([14], subject.css("table//tr:last-of-type"))
          assert_result_rows([3], subject.css("div/b:last-of-type"), "bold")
          assert_result_rows([2, 7], subject.css("div/i:last-of-type"), "italic")
          assert_result_rows([2, 6, 7], subject.css("div i:last-of-type"), "italic")
          assert_result_rows([4], subject.css("div/i.b:last-of-type"), "italic")
        end

        it "selects nth_of_type" do
          assert_result_rows([1], subject.css("div/b:nth-of-type(1)"), "bold")
          assert_result_rows([2], subject.css("div/b:nth-of-type(2)"), "bold")
          assert_result_rows([2], subject.css("div/.a:nth-of-type(1)"), "bold")
          assert_result_rows([2, 4, 7], subject.css("div i:nth-of-type(2n)"), "italic")
          assert_result_rows([1, 3, 5, 6], subject.css("div i:nth-of-type(2n+1)"), "italic")
          assert_result_rows([1], subject.css("div .a:nth-of-type(2n)"), "emphasis")
          assert_result_rows([2, 3], subject.css("div .a:nth-of-type(2n+1)"), "bold")
        end

        it "selects nth_last_of_type" do
          assert_result_rows([14], subject.css("table//tr:nth-last-of-type(1)"))
          assert_result_rows([12], subject.css("table//tr:nth-last-of-type(3)"))
          assert_result_rows([2, 6, 7], subject.css("div i:nth-last-of-type(1)"), "italic")
          assert_result_rows([1, 5], subject.css("div i:nth-last-of-type(2)"), "italic")
          assert_result_rows([4], subject.css("div/i.b:nth-last-of-type(1)"), "italic")
          assert_result_rows([3], subject.css("div/i.b:nth-last-of-type(2)"), "italic")
        end

        it "selects only_of_type" do
          assert_result_rows([1, 4], subject.css("div/p:only-of-type"), "para")
          assert_result_rows([5], subject.css("div/i.c:only-of-type"), "italic")
        end

        it "selects only_child" do
          assert_result_rows([4], subject.css("div/p:only-child"), "para")
          assert_result_rows([4], subject.css("div/h1.c:only-child"), "header")
        end

        it "selects empty" do
          result = subject.css("p:empty")
          assert_equal(1, result.size, "unexpected number of rows returned: '#{result.inner_text}'")
          assert_equal("empty", result.first["class"])
        end

        it "selects parent" do
          result = subject.css("p:parent")
          assert_equal(5, result.size)
          0.upto(3) do |j|
            assert_equal("para#{j + 1} ", result[j].inner_text)
          end
          assert_equal("not-empty", result[4]["class"])
        end

        it "selects siblings" do
          html = <<~HTML
            <html><body><div>
              <p id="1">p1 </p>
              <p id="2">p2 </p>
              <p id="3">p3 </p>
              <p id="4">p4 </p>
              <p id="5">p5 </p>
          HTML
          doc = subject_class.parse(html)
          assert_equal(2, doc.css("#3 ~ p").size)
          assert_equal("p4 p5 ", doc.css("#3 ~ p").inner_text)
          assert_equal(0, doc.css("#5 ~ p").size)

          assert_equal(1, doc.css("#3 + p").size)
          assert_equal("p4 ", doc.css("#3 + p").inner_text)
          assert_equal(0, doc.css("#5 + p").size)
        end

        it "selects has_a" do
          result = nested.css("div:has(b)")
          expected = [
            nested.at_css(".unnested.direct"),
            nested.at_css(".unnested.indirect"),
            nested.at_css(".nested-parent"),
            nested.at_css(".nested-child.direct"),
            nested.at_css(".nested-child.indirect"),
            nested.at_css(".has-bold"),
          ]
          assert_equal(expected, result.to_a)
        end

        it "selects has_a_gt_b" do
          result = nested.css("body *:has(div > b)")
          expected = [
            nested.at_css(".nested-parent"),
          ]
          assert_equal(expected, result.to_a)
        end

        it "selects has_gt_b" do
          result = nested.css("body *:has(> b)")
          expected = [
            nested.at_css(".unnested.direct"),
            nested.at_css(".unnested.indirect"),
            nested.at_css(".nested-child.direct"),
            nested.at_css(".nested-child.indirect"),
            nested.at_css(".has-bold"),
          ]
          assert_equal(expected, result.to_a)
        end

        it "selects has_a_plus_b" do
          result = nested.css("div:has(b + p)")
          expected = [
            nested.at_css(".unnested.direct"),
            nested.at_css(".nested-parent"),
            nested.at_css(".nested-child.direct"),
          ]
          assert_equal(expected, result.to_a)
        end

        it "selects has_plus_b" do
          result = nested.css("b:has(+ p)")
          expected = [
            nested.at_css(".unnested.direct b"),
            nested.at_css(".nested-child.direct b"),
          ]
          assert_equal(expected, result.to_a)
        end

        it "selects has_a_tilde_b" do
          result = nested.css("div:has(b ~ p)")
          expected = [
            nested.at_css(".unnested.direct"),
            nested.at_css(".unnested.indirect"),
            nested.at_css(".nested-parent"),
            nested.at_css(".nested-child.direct"),
            nested.at_css(".nested-child.indirect"),
          ]
          assert_equal(expected, result.to_a)
        end

        it "selects has_tilde_b" do
          result = nested.css("b:has(~ p)")
          expected = [
            nested.at_css(".unnested.direct b"),
            nested.at_css(".unnested.indirect b"),
            nested.at_css(".nested-child.direct b"),
            nested.at_css(".nested-child.indirect b"),
          ].flatten
          assert_equal(expected, result.to_a)
        end

        it "selects using contains" do
          assert_equal(14, subject.css("td:contains('row')").length)
          assert_equal(6, subject.css("td:contains('row1')").length)
          assert_equal(4, subject.css("h1:contains('header')").length)
          assert_equal(4, subject.css("div :contains('header')").length)
          assert_equal(9, subject.css(":contains('header')").length) # 9 = 4xh1 + 3xdiv + body + html
        end

        it "selects class_attr_selector" do
          doc = subject_class.parse(<<~HTML)
            <html><body>
              <div class="qwer asdf zxcv">space-delimited</div>
              <div class="qwer\tasdf\tzxcv">tab-delimited</div>
              <div class="qwer\nasdf\nzxcv">newline-delimited</div>
              <div class="qwer\rasdf\rzxcv">carriage-return-delimited</div>
            </body></html>
          HTML

          result = doc.css("div[class~='asdf']")
          assert_equal(4, result.length)

          result = doc.css("div[@class~='asdf']")
          assert_equal(4, result.length)

          expected = doc.css("div")
          assert_equal(expected, result)
        end

        it "handles xpath attribute selectors" do
          doc = subject_class.parse(<<~HTML)
            <html><body>
              <div class="first">
                <span class="child"></span>
              </div>
              <div class="second"></div>
              <div class="third"></div>
              <div class="fourth"></div>
            </body></html>
          HTML

          result = doc.css("div > @class")
          assert_equal(["first", "second", "third", "fourth"], result.map(&:to_s))

          result = doc.css("div/@class")
          assert_equal(["first", "second", "third", "fourth"], result.map(&:to_s))

          result = doc.css("div @class")
          assert_equal(["first", "child", "second", "third", "fourth"], result.map(&:to_s))
        end

        it "handles xpath functions" do
          doc = subject_class.parse(<<~HTML)
            <html><body>
              <div>first<span>child</span></div>
              <div>second</div>
              <div>third</div>
              <div>fourth</div>
            </body></html>
          HTML

          result = doc.css("div > text()")
          assert_equal(["first", "second", "third", "fourth"], result.map(&:to_s))

          result = doc.css("div/text()")
          assert_equal(["first", "second", "third", "fourth"], result.map(&:to_s))

          result = doc.css("div text()")
          assert_equal(["first", "child", "second", "third", "fourth"], result.map(&:to_s))
        end
      end
    end
  end
end
