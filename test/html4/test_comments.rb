# frozen_string_literal: true

require "helper"

module Nokogiri
  module HTML
    # testing error edge cases of HTML comments from the living WHATWG spec
    # as of 2020-08-03
    # https://html.spec.whatwg.org/multipage/parsing.html
    class TestComment < Nokogiri::TestCase
      # https://html.spec.whatwg.org/multipage/parsing.html#parse-error-abrupt-closing-of-empty-comment
      #
      # This error occurs if the parser encounters an empty comment
      # that is abruptly closed by a U+003E (>) code point (i.e.,
      # <!--> or <!--->). The parser behaves as if the comment is
      # closed correctly.
      describe "abrupt closing of empty comment" do
        let(:doc) { Nokogiri::HTML4(html) }
        let(:subject) { doc.at_css("div#under-test") }
        let(:other_div) { doc.at_css("div#also-here") }

        describe "two dashes" do
          let(:html) { "<html><body><div id=under-test><!--></div><div id=also-here></div></body></html>" }

          if Nokogiri.uses_libxml?(">= 2.10.0")
            it "behaves as if the comment is closed correctly" do # COMPLIANT
              assert_equal 1, subject.children.length
              assert_predicate subject.children.first, :comment?
              assert_equal "", subject.children.first.content
              assert other_div
            end
          elsif Nokogiri.uses_libxml?
            it "behaves as if the comment is unterminated and doesn't exist" do # NON-COMPLIANT
              assert_equal 0, subject.children.length
              assert_equal 1, doc.errors.length
              assert_match(/Comment not terminated/, doc.errors.first.to_s)
              refute other_div
            end
          elsif Nokogiri.jruby?
            it "behaves as if the comment is closed correctly" do # COMPLIANT
              assert_equal 1, subject.children.length
              assert_predicate subject.children.first, :comment?
              assert_equal "", subject.children.first.content
              assert other_div
            end
          end
        end

        describe "three dashes" do
          let(:html) { "<html><body><div id=under-test><!---></div><div id=also-here></div></body></html>" }

          if Nokogiri.uses_libxml?(">= 2.10.0")
            it "behaves as if the comment is closed correctly" do # COMPLIANT
              assert_equal 1, subject.children.length
              assert_predicate subject.children.first, :comment?
              assert_equal "", subject.children.first.content
              assert other_div
            end
          elsif Nokogiri.uses_libxml?
            it "behaves as if the comment is unterminated and doesn't exist" do # NON-COMPLIANT
              assert_equal 0, subject.children.length
              assert_equal 1, doc.errors.length
              assert_match(/Comment not terminated/, doc.errors.first.to_s)
              refute other_div
            end
          elsif Nokogiri.jruby?
            it "behaves as if the comment is closed correctly" do # COMPLIANT
              assert_equal 1, subject.children.length
              assert_predicate subject.children.first, :comment?
              assert_equal "", subject.children.first.content
              assert other_div
            end
          end
        end

        describe "four dashes" do
          let(:html) { "<html><body><div id=under-test><!----></div><div id=also-here></div></body></html>" }

          it "behaves as if the comment is closed correctly" do # COMPLIANT
            assert_equal 1, subject.children.length
            assert_predicate subject.children.first, :comment?
            assert_equal "", subject.children.first.content
            assert other_div
          end
        end
      end

      # https://html.spec.whatwg.org/multipage/parsing.html#parse-error-eof-in-comment
      #
      # This error occurs if the parser encounters the end of the
      # input stream in a comment. The parser treats such comments as
      # if they are closed immediately before the end of the input
      # stream.
      describe "eof in comment" do
        let(:html) { "<html><body><div id=under-test><!--start of unterminated comment" }
        let(:doc) { Nokogiri::HTML4(html) }
        let(:subject) { doc.at_css("div#under-test") }

        if Nokogiri.uses_libxml?(">= 2.14.0")
          it "behaves as if the comment is closed immediately before the end of the input stream" do # COMPLIANT
            assert_pattern do
              subject => {
                name: "div",
                attributes: [{ name: "id", value: "under-test" }],
                children: [
                  { name: "comment", content: "start of unterminated comment" }
                ]
              }
            end
          end
        elsif Nokogiri.uses_libxml?
          it "behaves as if the comment is unterminated and doesn't exist" do # NON-COMPLIANT
            assert_equal 0, subject.children.length
            assert_equal 1, doc.errors.length
            assert_match(/Comment not terminated/, doc.errors.first.to_s)
          end
        elsif Nokogiri.jruby?
          it "behaves as if the comment is closed immediately before the end of the input stream" do # COMPLIANT
            assert_equal 1, subject.children.length
            assert_predicate subject.children.first, :comment?
            assert_equal "start of unterminated comment", subject.children.first.content
          end
        end
      end

      # https://html.spec.whatwg.org/multipage/parsing.html#parse-error-incorrectly-closed-comment
      #
      # This error occurs if the parser encounters a comment that is
      # closed by the "--!>" code point sequence. The parser treats
      # such comments as if they are correctly closed by the "-->"
      # code point sequence.
      describe "incorrectly closed comment" do
        let(:html) { "<html><body><div id=under-test><!--foo--!><div id=do-i-exist></div><!--bar--></div></body></html>" }
        let(:doc) { Nokogiri::HTML4(html) }
        let(:subject) { doc.at_css("div#under-test") }
        let(:inner_div) { doc.at_css("div#do-i-exist") }

        if Nokogiri::VersionInfo.instance.libxml2_using_packaged? || (Nokogiri::VersionInfo.instance.libxml2_using_system? && Nokogiri.uses_libxml?(">= 2.9.11"))
          it "behaves as if the comment is normally closed" do # COMPLIANT
            assert_equal 3, subject.children.length
            assert_predicate subject.children[0], :comment?
            assert_equal "foo", subject.children[0].content
            assert inner_div
            assert_equal inner_div, subject.children[1]
            assert_predicate subject.children[2], :comment?
            assert_equal "bar", subject.children[2].content
            if Nokogiri.uses_libxml?(">= 2.14.0")
              assert_empty doc.errors
            else
              assert_equal 1, doc.errors.length
              assert_match(/Comment incorrectly closed/, doc.errors.first.to_s)
            end
          end
        else # jruby, or libxml2 system lib less than 2.9.11
          it "behaves as if the comment encompasses the inner div" do # NON-COMPLIANT
            assert_equal 1, subject.children.length
            assert_predicate subject.children.first, :comment?
            refute inner_div
            assert_match(/id=do-i-exist/, subject.children.first.content)
            assert_equal 0, doc.errors.length
          end
        end
      end

      # https://html.spec.whatwg.org/multipage/parsing.html#parse-error-incorrectly-opened-comment
      #
      # This error occurs if the parser encounters the "<!" code point
      # sequence that is not immediately followed by two U+002D (-)
      # code points and that is not the start of a DOCTYPE or a CDATA
      # section. All content that follows the "<!" code point sequence
      # up to a U+003E (>) code point (if present) or to the end of
      # the input stream is treated as a comment.
      describe "incorrectly opened comment" do
        let(:html) { "<html><body><div id=under-test><! comment <div id=do-i-exist>inner content</div>-->hello</div></body></html>" }

        let(:doc) { Nokogiri::HTML4(html) }
        let(:body) { doc.at_css("body") }
        let(:subject) { doc.at_css("div#under-test") }

        if Nokogiri.uses_libxml?(">= 2.14.0")
          it "parses as comments" do # COMPLIANT
            assert_pattern do
              body.children => [
                {
                  name: "div",
                  children: [
                    { name: "comment", content: " comment <div id=do-i-exist" },
                    { name: "text", content: "inner content" },
                  ]
                },
                { name: "text", content: "-->hello" },
              ]
            end
          end
        elsif Nokogiri.uses_libxml?("= 2.9.14")
          it "parses as PCDATA" do # NON-COMPLIANT
            assert_equal 1, body.children.length
            assert_equal subject, body.children.first

            assert_equal 3, subject.children.length
            subject.children[0].tap do |child|
              assert_predicate(child, :text?)
              assert_equal("<! comment ", child.content)
            end
            subject.children[1].tap do |child|
              assert_predicate(child, :element?)
              assert_equal("div", child.name)
              assert_equal("inner content", child.content)
            end
            subject.children[2].tap do |child|
              assert_predicate(child, :text?)
              assert_equal("-->hello", child.content)
            end
          end
        elsif Nokogiri.uses_libxml? # before or after 2.9.14
          it "ignores up to the next '>'" do # NON-COMPLIANT
            assert_equal 2, body.children.length
            assert_equal body.children[0], subject
            assert_equal 1, subject.children.length
            assert_predicate subject.children[0], :text?
            assert_equal "inner content", subject.children[0].content
            assert_predicate body.children[1], :text?
            assert_equal "-->hello", body.children[1].content
          end
        elsif Nokogiri.jruby?
          it "ignores up to the next '-->'" do # NON-COMPLIANT
            assert_equal 1, body.children.length
            assert_equal subject, body.children.first

            assert_equal 1, subject.children.length
            assert_predicate subject.children[0], :text?
            assert_equal "hello", subject.children[0].content
          end
        end
      end

      # conditional HTML comments, variation of the above
      # https://gitlab.gnome.org/GNOME/libxml2/-/issues/380
      describe "conditional HTML comments" do
        let(:html) { "<html><body><div id=under-test><![if foo]><div id=do-i-exist>inner content</div><![endif]></div></body></html>" }

        let(:doc) { Nokogiri::HTML4(html) }
        let(:body) { doc.at_css("body") }
        let(:subject) { doc.at_css("div#under-test") }

        if Nokogiri.uses_libxml?(">= 2.14.0")
          it "parses the <! tags as comments" do
            assert_pattern do
              body.children => [
                {
                  name: "div", children: [
                    { name: "comment", content: "[if foo]" },
                    { name: "div", attributes: [{name: "id", value: "do-i-exist"}] },
                    { name: "comment", content: "[endif]" },
                  ]
                }
              ]
            end
          end
        elsif Nokogiri.uses_libxml?("= 2.9.14")
          it "parses the <! tags as PCDATA" do
            assert_equal(1, body.children.length)
            assert_equal(subject, body.children.first)

            assert_equal(3, subject.children.length)
            subject.children[0].tap do |child|
              assert_predicate(child, :text?)
              assert_equal("<![if foo]>", child.content)
            end
            subject.children[1].tap do |child|
              assert_predicate(child, :element?)
              assert_equal("div", child.name)
              assert_equal("do-i-exist", child["id"])
            end
            subject.children[2].tap do |child|
              assert_predicate(child, :text?)
              assert_equal("<![endif]>", child.content)
            end
          end
        else # libxml before or after 2.9.14, or jruby
          it "drops the <! tags" do
            assert_equal(1, body.children.length)
            assert_equal(subject, body.children.first)

            assert_equal(1, subject.children.length)
            assert_equal("div", subject.children.first.name)
            assert_equal("do-i-exist", subject.children.first["id"])
          end
        end
      end

      # https://html.spec.whatwg.org/multipage/parsing.html#parse-error-nested-comment
      #
      # This error occurs if the parser encounters a nested comment
      # (e.g., <!-- <!-- nested --> -->). Such a comment will be
      # closed by the first occurring "-->" code point sequence and
      # everything that follows will be treated as markup.
      describe "nested comment" do
        let(:html) { "<html><body><div id=under-test><!-- outer <!-- inner --><div id=do-i-exist></div>--></div></body></html>" }
        let(:doc) { Nokogiri::HTML4(html) }
        let(:subject) { doc.at_css("div#under-test") }
        let(:inner_div) { doc.at_css("div#do-i-exist") }

        it "ignores to the next '-->'" do # COMPLIANT
          assert_equal 3, subject.children.length
          assert_predicate subject.children[0], :comment?
          assert_equal " outer <!-- inner ", subject.children[0].content
          assert inner_div
          assert_equal inner_div, subject.children[1]
          assert_predicate subject.children[2], :text?
          assert_equal "-->", subject.children[2].content
        end
      end
    end
  end
end
