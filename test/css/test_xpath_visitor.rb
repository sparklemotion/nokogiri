# coding: utf-8
# frozen_string_literal: true

require "helper"

class TestNokogiri < Nokogiri::TestCase
  describe Nokogiri::CSS::XPathVisitor do
    let(:parser) { Nokogiri::CSS::Parser.new }

    let(:parser_with_ns) do
      Nokogiri::CSS::Parser.new({
        "xmlns" => "http://default.example.com/",
        "hoge" => "http://hoge.example.com/",
      })
    end

    let(:visitor) { Nokogiri::CSS::XPathVisitor.new }

    def assert_xpath(expecteds, asts)
      expecteds = [expecteds].flatten
      expecteds.zip(asts).each do |expected, actual|
        assert_equal(expected, actual.to_xpath("//", visitor))
      end
    end

    it "accepts some config parameters" do
      refute_nil(Nokogiri::CSS::XPathVisitor.new(builtins: Nokogiri::CSS::XPathVisitor::BuiltinsConfig::NEVER))
      refute_nil(Nokogiri::CSS::XPathVisitor.new(builtins: Nokogiri::CSS::XPathVisitor::BuiltinsConfig::ALWAYS))
      refute_nil(Nokogiri::CSS::XPathVisitor.new(builtins: Nokogiri::CSS::XPathVisitor::BuiltinsConfig::OPTIMAL))
      assert_raises(ArgumentError) { Nokogiri::CSS::XPathVisitor.new(builtins: :not_valid) }

      refute_nil(Nokogiri::CSS::XPathVisitor.new(doctype: Nokogiri::CSS::XPathVisitor::DoctypeConfig::XML))
      refute_nil(Nokogiri::CSS::XPathVisitor.new(doctype: Nokogiri::CSS::XPathVisitor::DoctypeConfig::HTML4))
      refute_nil(Nokogiri::CSS::XPathVisitor.new(doctype: Nokogiri::CSS::XPathVisitor::DoctypeConfig::HTML5))
      assert_raises(ArgumentError) { Nokogiri::CSS::XPathVisitor.new(doctype: :not_valid) }
    end

    it "exposes its configuration" do
      expected = {
        builtins: Nokogiri::CSS::XPathVisitor::BuiltinsConfig::NEVER,
        doctype: Nokogiri::CSS::XPathVisitor::DoctypeConfig::XML,
      }
      assert_equal(expected, visitor.config)
    end

    it "raises an exception on single quote" do
      assert_raises(Nokogiri::CSS::SyntaxError) { parser.parse("'") }
    end

    it "raises an exception on invalid CSS syntax" do
      assert_raises(Nokogiri::CSS::SyntaxError) { parser.parse("a[x=]") }
    end

    describe "selectors" do
      it "* universal" do
        assert_xpath("//*", parser.parse("*"))
      end

      it "type" do
        assert_xpath("//x", parser.parse("x"))
      end

      it "type with namespaces" do
        assert_xpath("//aaron:a", parser.parse("aaron|a"))
        assert_xpath("//a", parser.parse("|a"))
      end

      it ". class" do
        assert_xpath(
          "//*[contains(concat(' ',normalize-space(@class),' '),' awesome ')]",
          parser.parse(".awesome"),
        )
        assert_xpath(
          "//foo[contains(concat(' ',normalize-space(@class),' '),' awesome ')]",
          parser.parse("foo.awesome"),
        )
        assert_xpath(
          "//foo//*[contains(concat(' ',normalize-space(@class),' '),' awesome ')]",
          parser.parse("foo .awesome"),
        )
        assert_xpath(
          "//foo//*[contains(concat(' ',normalize-space(@class),' '),' awe.some ')]",
          parser.parse("foo .awe\\.some"),
        )
        assert_xpath(
          "//*[contains(concat(' ',normalize-space(@class),' '),' a ') and contains(concat(' ',normalize-space(@class),' '),' b ')]",
          parser.parse(".a.b"),
        )
        assert_xpath(
          "//*[contains(concat(' ',normalize-space(@class),' '),' pastoral ')]",
          parser.parse("*.pastoral"),
        )
      end

      it "# id" do
        assert_xpath("//*[@id='foo']", parser.parse("#foo"))
        assert_xpath("//*[@id='escape:needed,']", parser.parse("#escape\\:needed\\,"))
        assert_xpath("//*[@id='escape:needed,']", parser.parse('#escape\3Aneeded\,'))
        assert_xpath("//*[@id='escape:needed,']", parser.parse('#escape\3A needed\2C'))
        assert_xpath("//*[@id='escape:needed']", parser.parse('#escape\00003Aneeded'))
      end

      describe "attribute" do
        it "basic mechanics" do
          assert_xpath("//h1[@a='Tender Lovemaking']", parser.parse("h1[a='Tender Lovemaking']"))
          assert_xpath("//h1[@a]", parser.parse("h1[a]"))
          assert_xpath(%q{//h1[@a='gnewline\n']}, parser.parse("h1[a='\\gnew\\\nline\\\\n']"))
          assert_xpath("//h1[@a='test']", parser.parse(%q{h1[a=\te\st]}))
        end

        it "parses leading @ (non-standard)" do
          assert_xpath("//a[@id='Boing']", parser.parse("a[@id='Boing']"))
          assert_xpath("//a[@id='Boing']", parser.parse("a[@id = 'Boing']"))
          assert_xpath("//a[@id='Boing']//div", parser.parse("a[@id='Boing'] div"))
        end

        it "namespacing" do
          assert_xpath("//a[@flavorjones:href]", parser.parse("a[flavorjones|href]"))
          assert_xpath("//a[@href]", parser.parse("a[|href]"))
          assert_xpath("//*[@flavorjones:href]", parser.parse("*[flavorjones|href]"))

          ## Default namespace is not applied to attributes, so this is @class, not @xmlns:class.
          assert_xpath("//xmlns:a[@class='bar']", parser_with_ns.parse("a[class='bar']"))
          assert_xpath("//xmlns:a[@hoge:class='bar']", parser_with_ns.parse("a[hoge|class='bar']"))
        end

        it "rhs with quotes" do
          assert_xpath(%q{//h1[@a="'"]}, parser.parse(%q{h1[a="'"]}))
          assert_xpath(%q{//h1[@a=concat("'","")]}, parser.parse("h1[a='\\'']"))
          assert_xpath(%q{//h1[@a=concat("",'"',"'","")]}, parser.parse(%q{h1[a='"\'']}))
        end

        it "rhs is number or string" do
          assert_xpath("//img[@width='200']", parser.parse("img[width='200']"))
          assert_xpath("//img[@width='200']", parser.parse("img[width=200]"))
        end

        it "bare" do
          assert_xpath("//*[@a]//*[@b]", parser.parse("[a] [b]"))
        end

        it "|=" do
          assert_xpath(
            "//a[@class='bar' or starts-with(@class,concat('bar','-'))]",
            parser.parse("a[@class|='bar']"),
          )
          assert_xpath(
            "//a[@class='bar' or starts-with(@class,concat('bar','-'))]",
            parser.parse("a[@class |= 'bar']"),
          )
          assert_xpath(
            "//a[@id='Boing' or starts-with(@id,concat('Boing','-'))]",
            parser.parse("a[id|='Boing']"),
          )
        end

        it "~=" do
          assert_xpath(
            "//a[contains(concat(' ',normalize-space(@class),' '),' bar ')]",
            parser.parse("a[@class~='bar']"),
          )
          assert_xpath(
            "//a[contains(concat(' ',normalize-space(@class),' '),' bar ')]",
            parser.parse("a[@class ~= 'bar']"),
          )
          assert_xpath(
            "//a[contains(concat(' ',normalize-space(@class),' '),' bar ')]",
            parser.parse("a[@class~=bar]"),
          )
          assert_xpath(
            "//a[contains(concat(' ',normalize-space(@class),' '),' bar ')]",
            parser.parse("a[@class~=\"bar\"]"),
          )
          assert_xpath(
            "//a[contains(concat(' ',normalize-space(@data-words),' '),' bar ')]",
            parser.parse("a[data-words~=\"bar\"]"),
          )
        end

        it "^=" do
          assert_xpath("//a[starts-with(@id,'Boing')]", parser.parse("a[id^='Boing']"))
          assert_xpath("//a[starts-with(@id,'Boing')]", parser.parse("a[id ^= 'Boing']"))
        end

        it "$=" do
          assert_xpath(
            "//a[substring(@id,string-length(@id)-string-length('Boing')+1,string-length('Boing'))='Boing']",
            parser.parse("a[id$='Boing']"),
          )
          assert_xpath(
            "//a[substring(@id,string-length(@id)-string-length('Boing')+1,string-length('Boing'))='Boing']",
            parser.parse("a[id $= 'Boing']"),
          )
        end

        it "*=" do
          assert_xpath("//a[contains(@id,'Boing')]", parser.parse("a[id*='Boing']"))
          assert_xpath("//a[contains(@id,'Boing')]", parser.parse("a[id *= 'Boing']"))
        end

        it "!= (non-standard)" do
          assert_xpath("//a[@id!='Boing']", parser.parse("a[id!='Boing']"))
          assert_xpath("//a[@id!='Boing']", parser.parse("a[id != 'Boing']"))
        end
      end
    end

    describe "pseudo-classes" do
      it ":first-of-type" do
        assert_xpath("//a[position()=1]", parser.parse("a:first-of-type()"))
        assert_xpath("//a[position()=1]", parser.parse("a:first-of-type")) # no parens
        assert_xpath(
          "//a[contains(concat(' ',normalize-space(@class),' '),' b ')][position()=1]",
          parser.parse("a.b:first-of-type"),
        ) # no parens
      end

      it ":nth-of-type" do
        assert_xpath("//a[position()=99]", parser.parse("a:nth-of-type(99)"))
        assert_xpath(
          "//a[contains(concat(' ',normalize-space(@class),' '),' b ')][position()=99]",
          parser.parse("a.b:nth-of-type(99)"),
        )
      end

      it ":last-of-type" do
        assert_xpath("//a[position()=last()]", parser.parse("a:last-of-type()"))
        assert_xpath("//a[position()=last()]", parser.parse("a:last-of-type")) # no parens
        assert_xpath(
          "//a[contains(concat(' ',normalize-space(@class),' '),' b ')][position()=last()]",
          parser.parse("a.b:last-of-type"),
        ) # no parens
      end

      it ":nth-last-of-type" do
        assert_xpath("//a[position()=last()]", parser.parse("a:nth-last-of-type(1)"))
        assert_xpath("//a[position()=last()-98]", parser.parse("a:nth-last-of-type(99)"))
        assert_xpath(
          "//a[contains(concat(' ',normalize-space(@class),' '),' b ')][position()=last()-98]",
          parser.parse("a.b:nth-last-of-type(99)"),
        )
      end

      it ":nth and friends (non-standard)" do
        assert_xpath("//a[position()=1]", parser.parse("a:first()"))
        assert_xpath("//a[position()=1]", parser.parse("a:first")) # no parens
        assert_xpath("//a[position()=99]", parser.parse("a:eq(99)"))
        assert_xpath("//a[position()=99]", parser.parse("a:nth(99)"))
        assert_xpath("//a[position()=last()]", parser.parse("a:last()"))
        assert_xpath("//a[position()=last()]", parser.parse("a:last")) # no parens
        assert_xpath("//a[node()]", parser.parse("a:parent"))
      end

      it ":nth-child and friends" do
        assert_xpath("//a[count(preceding-sibling::*)=0]", parser.parse("a:first-child"))
        assert_xpath("//a[count(preceding-sibling::*)=98]", parser.parse("a:nth-child(99)"))
        assert_xpath("//a[count(following-sibling::*)=0]", parser.parse("a:last-child"))
        assert_xpath("//a[count(following-sibling::*)=0]", parser.parse("a:nth-last-child(1)"))
        assert_xpath("//a[count(following-sibling::*)=98]", parser.parse("a:nth-last-child(99)"))
      end

      it "[n] as :nth-child (non-standard)" do
        assert_xpath("//a[count(preceding-sibling::*)=1]", parser.parse("a[2]"))
      end

      it ":has()" do
        assert_xpath("//a[.//b]", parser.parse("a:has(b)"))
        assert_xpath("//a[.//b/c]", parser.parse("a:has(b > c)"))
        assert_xpath("//a[./b]", parser.parse("a:has(> b)"))
        assert_xpath("//a[./following-sibling::b]", parser.parse("a:has(~ b)"))
        assert_xpath("//a[./following-sibling::*[1]/self::b]", parser.parse("a:has(+ b)"))
      end

      it ":only-child" do
        assert_xpath(
          "//a[count(preceding-sibling::*)=0 and count(following-sibling::*)=0]",
          parser.parse("a:only-child"),
        )
      end

      it ":only-of-type" do
        assert_xpath("//a[last()=1]", parser.parse("a:only-of-type"))
      end

      it ":empty" do
        assert_xpath("//a[not(node())]", parser.parse("a:empty"))
      end

      it ":nth(an+b)" do
        assert_xpath("//a[(position() mod 2)=0]", parser.parse("a:nth-of-type(2n)"))
        assert_xpath("//a[(position()>=1) and (((position()-1) mod 2)=0)]", parser.parse("a:nth-of-type(2n+1)"))
        assert_xpath("//a[(position() mod 2)=0]", parser.parse("a:nth-of-type(even)"))
        assert_xpath("//a[(position()>=1) and (((position()-1) mod 2)=0)]", parser.parse("a:nth-of-type(odd)"))
        assert_xpath("//a[(position()>=3) and (((position()-3) mod 4)=0)]", parser.parse("a:nth-of-type(4n+3)"))
        assert_xpath("//a[position()<=3]", parser.parse("a:nth-of-type(-1n+3)"))
        assert_xpath("//a[position()<=3]", parser.parse("a:nth-of-type(-n+3)"))
        assert_xpath("//a[position()>=3]", parser.parse("a:nth-of-type(1n+3)"))
        assert_xpath("//a[position()>=3]", parser.parse("a:nth-of-type(n+3)"))

        assert_xpath("//a[((last()-position()+1) mod 2)=0]", parser.parse("a:nth-last-of-type(2n)"))
        assert_xpath("//a[((last()-position()+1)>=1) and ((((last()-position()+1)-1) mod 2)=0)]", parser.parse("a:nth-last-of-type(2n+1)"))
        assert_xpath("//a[((last()-position()+1) mod 2)=0]", parser.parse("a:nth-last-of-type(even)"))
        assert_xpath("//a[((last()-position()+1)>=1) and ((((last()-position()+1)-1) mod 2)=0)]", parser.parse("a:nth-last-of-type(odd)"))
        assert_xpath("//a[((last()-position()+1)>=3) and ((((last()-position()+1)-3) mod 4)=0)]", parser.parse("a:nth-last-of-type(4n+3)"))
        assert_xpath("//a[(last()-position()+1)<=3]", parser.parse("a:nth-last-of-type(-1n+3)"))
        assert_xpath("//a[(last()-position()+1)<=3]", parser.parse("a:nth-last-of-type(-n+3)"))
        assert_xpath("//a[(last()-position()+1)>=3]", parser.parse("a:nth-last-of-type(1n+3)"))
        assert_xpath("//a[(last()-position()+1)>=3]", parser.parse("a:nth-last-of-type(n+3)"))
      end

      it ":not()" do
        assert_xpath("//ol/*[not(self::li)]", parser.parse("ol > *:not(li)"))
        assert_xpath(
          "//*[@id='p' and not(contains(concat(' ',normalize-space(@class),' '),' a '))]",
          parser.parse("#p:not(.a)"),
        )
        assert_xpath(
          "//p[contains(concat(' ',normalize-space(@class),' '),' a ') and not(contains(concat(' ',normalize-space(@class),' '),' b '))]",
          parser.parse("p.a:not(.b)"),
        )
        assert_xpath(
          "//p[@a='foo' and not(contains(concat(' ',normalize-space(@class),' '),' b '))]",
          parser.parse("p[a='foo']:not(.b)"),
        )
      end

      it "chained :not()" do
        assert_xpath(
          "//p[not(contains(concat(' ',normalize-space(@class),' '),' a ')) and not(contains(concat(' ',normalize-space(@class),' '),' b ')) and not(contains(concat(' ',normalize-space(@class),' '),' c '))]",
          parser.parse("p:not(.a):not(.b):not(.c)"),
        )
      end

      it "combinations of :not() and nth-and-friends" do
        assert_xpath(
          "//ol/*[not(count(following-sibling::*)=0)]",
          parser.parse("ol > *:not(:last-child)"),
        )
        assert_xpath(
          "//ol/*[not(count(preceding-sibling::*)=0 and count(following-sibling::*)=0)]",
          parser.parse("ol > *:not(:only-child)"),
        )
      end

      it "miscellaneous pseudo-classes are converted into xpath function calls" do
        assert_xpath("//a[nokogiri:aaron(.)]", parser.parse("a:aaron"))
        assert_xpath("//a[nokogiri:aaron(.)]", parser.parse("a:aaron()"))
        assert_xpath("//a[nokogiri:aaron(.,12)]", parser.parse("a:aaron(12)"))
        assert_xpath("//a[nokogiri:aaron(.,12,1)]", parser.parse("a:aaron(12, 1)"))

        assert_xpath("//a[nokogiri:link(.)]", parser.parse("a:link"))
        assert_xpath("//a[nokogiri:visited(.)]", parser.parse("a:visited"))
        assert_xpath("//a[nokogiri:hover(.)]", parser.parse("a:hover"))
        assert_xpath("//a[nokogiri:active(.)]", parser.parse("a:active"))

        assert_xpath("//a[nokogiri:foo(.,@href)]", parser.parse("a:foo(@href)"))
        assert_xpath("//a[nokogiri:foo(.,@href,@id)]", parser.parse("a:foo(@href, @id)"))
        assert_xpath("//a[nokogiri:foo(.,@a,b)]", parser.parse("a:foo(@a, b)"))
        assert_xpath("//a[nokogiri:foo(.,a,@b)]", parser.parse("a:foo(a, @b)"))
        assert_xpath("//a[nokogiri:foo(.,a,10)]", parser.parse("a:foo(a, 10)"))
        assert_xpath("//a[nokogiri:foo(.,42)]", parser.parse("a:foo(42)"))
        assert_xpath("//a[nokogiri:foo(.,'bar')]", parser.parse("a:foo('bar')"))
      end

      it "bare pseudo-class matches any ident" do
        assert_xpath("//*[nokogiri:link(.)]", parser.parse(":link"))
        assert_xpath("//*[not(@id='foo')]", parser.parse(":not(#foo)"))
        assert_xpath("//*[count(preceding-sibling::*)=0]", parser.parse(":first-child"))
      end
    end

    describe "combinators" do
      it "descendant" do
        assert_xpath("//x//y", parser.parse("x y"))
      end

      it "~ general sibling" do
        assert_xpath("//E/following-sibling::F", parser.parse("E ~ F"))
        assert_xpath("//E/following-sibling::F//G", parser.parse("E ~ F G"))
      end

      it "~ general sibling prefixless is relative to context node" do
        assert_xpath("./following-sibling::a", parser.parse("~a"))
        assert_xpath("./following-sibling::a", parser.parse("~ a"))
        assert_xpath("./following-sibling::a//b/following-sibling::i", parser.parse("~a b~i"))
        assert_xpath("./following-sibling::a//b/following-sibling::i", parser.parse("~ a b ~ i"))
      end

      it "+ adjacent sibling" do
        assert_xpath("//E/following-sibling::*[1]/self::F", parser.parse("E + F"))
        assert_xpath("//E/following-sibling::*[1]/self::F//G", parser.parse("E + F G"))
      end

      it "+ adjacent sibling prefixless is relative to context node" do
        assert_xpath("./following-sibling::*[1]/self::a", parser.parse("+a"))
        assert_xpath("./following-sibling::*[1]/self::a", parser.parse("+ a"))
        assert_xpath("./following-sibling::*[1]/self::a/following-sibling::*[1]/self::b", parser.parse("+a+b"))
        assert_xpath("./following-sibling::*[1]/self::a/following-sibling::*[1]/self::b", parser.parse("+ a + b"))
      end

      it "> child" do
        assert_xpath("//x/y", parser.parse("x > y"))
        assert_xpath("//a//b/i", parser.parse("a b>i"))
        assert_xpath("//a//b/i", parser.parse("a b > i"))
        assert_xpath("//a/b/i", parser.parse("a > b > i"))
      end

      it "> child prefixless is relative to context node" do
        assert_xpath("./a", parser.parse(">a"))
        assert_xpath("./a", parser.parse("> a"))
        assert_xpath("./a//b/i", parser.parse(">a b>i"))
        assert_xpath("./a/b/i", parser.parse("> a > b > i"))
      end

      it "/ (non-standard)" do
        assert_xpath("//x/y", parser.parse("x/y"))
        assert_xpath("//x/y", parser.parse("x / y"))
      end

      it "// (non-standard)" do
        assert_xpath("//x//y", parser.parse("x//y"))
        assert_xpath("//x//y", parser.parse("x // y"))
      end
    end

    describe "functions" do
      it "handles text() (non-standard)" do
        assert_xpath("//a[child::text()]", parser.parse("a[text()]"))
        assert_xpath("//child::text()", parser.parse("text()"))
        assert_xpath("//a//child::text()", parser.parse("a text()"))
        assert_xpath("//a/child::text()", parser.parse("a / text()"))
        assert_xpath("//a/child::text()", parser.parse("a > text()"))
        assert_xpath("//a//child::text()", parser.parse("a text()"))
      end

      it "handles comment() (non-standard)" do
        assert_xpath("//script//comment()", parser.parse("script comment()"))
      end

      it "handles contains() (non-standard)" do
        # https://api.jquery.com/contains-selector/
        assert_xpath(%{//div[contains(.,"youtube")]}, parser.parse(%{div:contains("youtube")}))
      end

      it "handles gt() (non-standard)" do
        # https://api.jquery.com/gt-selector/
        assert_xpath("//td[position()>3]", parser.parse("td:gt(3)"))
      end

      it "handles self()" do
        # TODO: it's unclear how this is useful and we should consider deprecating it
        assert_xpath("//self::div", parser.parse("self(div)"))
      end

      it "supports custom functions" do
        visitor = Class.new(Nokogiri::CSS::XPathVisitor) do
          attr_accessor :awesome

          def visit_function_aaron(node)
            @awesome = true
            "aaron() = 1"
          end
        end.new
        ast = parser.parse("a:aaron()").first
        assert_equal "a[aaron() = 1]", visitor.accept(ast)
        assert visitor.awesome
      end

      it "supports custom pseudo-classes" do
        visitor = Class.new(Nokogiri::CSS::XPathVisitor) do
          attr_accessor :awesome

          def visit_pseudo_class_aaron(node)
            @awesome = true
            "aaron() = 1"
          end
        end.new
        ast = parser.parse("a:aaron").first
        assert_equal "a[aaron() = 1]", visitor.accept(ast)
        assert visitor.awesome
      end
    end

    it "handles pseudo-class with class selector" do
      assert_xpath(
        "//a[nokogiri:active(.) and contains(concat(' ',normalize-space(@class),' '),' foo ')]",
        parser.parse("a:active.foo"),
      )
      assert_xpath(
        "//a[contains(concat(' ',normalize-space(@class),' '),' foo ') and nokogiri:active(.)]",
        parser.parse("a.foo:active"),
      )
    end

    it "handles pseudo-class with an id selector" do
      assert_xpath("//a[@id='foo' and nokogiri:active(.)]", parser.parse("a#foo:active"))
      assert_xpath("//a[nokogiri:active(.) and @id='foo']", parser.parse("a:active#foo"))
    end

    it "handles function with pseudo-class" do
      assert_xpath("//child::text()[position()=99]", parser.parse("text():nth-of-type(99)"))
    end

    it "handles multiple selectors" do
      assert_xpath(["//x/y", "//y/z"], parser.parse("x > y, y > z"))
      assert_xpath(["//x/y", "//y/z"], parser.parse("x > y,y > z"))
      ###
      # TODO: should we make this work?
      # assert_xpath ['//x/y', '//y/z'], parser.parse('x > y | y > z')
    end

    describe "builtins:always" do
      let(:visitor) { Nokogiri::CSS::XPathVisitor.new(builtins: Nokogiri::CSS::XPathVisitor::BuiltinsConfig::ALWAYS) }

      it "exposes its configuration" do
        assert_equal({ builtins: Nokogiri::CSS::XPathVisitor::BuiltinsConfig::ALWAYS, doctype: Nokogiri::CSS::XPathVisitor::DoctypeConfig::XML }, visitor.config)
      end

      it ". class" do
        assert_xpath(
          "//*[nokogiri-builtin:css-class(@class,'awesome')]",
          parser.parse(".awesome"),
        )
        assert_xpath(
          "//foo[nokogiri-builtin:css-class(@class,'awesome')]",
          parser.parse("foo.awesome"),
        )
        assert_xpath(
          "//foo//*[nokogiri-builtin:css-class(@class,'awesome')]",
          parser.parse("foo .awesome"),
        )
        assert_xpath(
          "//foo//*[nokogiri-builtin:css-class(@class,'awe.some')]",
          parser.parse("foo .awe\\.some"),
        )
        assert_xpath(
          "//*[nokogiri-builtin:css-class(@class,'a') and nokogiri-builtin:css-class(@class,'b')]",
          parser.parse(".a.b"),
        )
      end

      it "~=" do
        assert_xpath(
          "//a[nokogiri-builtin:css-class(@class,'bar')]",
          parser.parse("a[@class~='bar']"),
        )
        assert_xpath(
          "//a[nokogiri-builtin:css-class(@class,'bar')]",
          parser.parse("a[@class ~= 'bar']"),
        )
        assert_xpath(
          "//a[nokogiri-builtin:css-class(@class,'bar')]",
          parser.parse("a[@class~=bar]"),
        )
        assert_xpath(
          "//a[nokogiri-builtin:css-class(@class,'bar')]",
          parser.parse("a[@class~=\"bar\"]"),
        )
        assert_xpath(
          "//a[nokogiri-builtin:css-class(@data-words,'bar')]",
          parser.parse("a[data-words~=\"bar\"]"),
        )
        assert_xpath(
          "//a[nokogiri-builtin:css-class(@data-words,'bar')]",
          parser.parse("a[@data-words~=\"bar\"]"),
        )
      end

      describe "XPathVisitorAlwaysUseBuiltins" do
        let(:visitor) { Nokogiri::CSS::XPathVisitorAlwaysUseBuiltins.new }

        it "supports deprecated class" do
          assert_output("", /XPathVisitorAlwaysUseBuiltins is deprecated/) { visitor }
          assert_instance_of(Nokogiri::CSS::XPathVisitor, visitor)
          assert_equal({ builtins: Nokogiri::CSS::XPathVisitor::BuiltinsConfig::ALWAYS, doctype: Nokogiri::CSS::XPathVisitor::DoctypeConfig::XML }, visitor.config)

          assert_xpath(
            "//*[nokogiri-builtin:css-class(@class,'awesome')]",
            parser.parse(".awesome"),
          )
        end
      end
    end

    describe "builtins:optimal" do
      let(:visitor) { Nokogiri::CSS::XPathVisitor.new(builtins: Nokogiri::CSS::XPathVisitor::BuiltinsConfig::OPTIMAL) }

      it "exposes its configuration" do
        assert_equal({ builtins: Nokogiri::CSS::XPathVisitor::BuiltinsConfig::OPTIMAL, doctype: Nokogiri::CSS::XPathVisitor::DoctypeConfig::XML }, visitor.config)
      end

      #
      #  only use the builtin css-class method if we're in libxml2, because incredibly the native
      #  impl is slower in JRuby:
      #
      #    ruby 2.7.2p137 (2020-10-01 revision 5445e04352) [x86_64-linux]
      #    Warming up --------------------------------------
      #    xpath("//*[contains(concat(' ', normalize-space(@class), ' '), ' xxxx ')]")
      #                            71.000  i/100ms
      #    xpath("//*[nokogiri-builtin:css-class(@class, 'xxxx')]")
      #                           135.000  i/100ms
      #    Calculating -------------------------------------
      #    xpath("//*[contains(concat(' ', normalize-space(@class), ' '), ' xxxx ')]")
      #                            681.312  (± 5.9%) i/s -      6.816k in  10.041631s
      #    xpath("//*[nokogiri-builtin:css-class(@class, 'xxxx')]")
      #                              1.343k (± 5.9%) i/s -     13.500k in  10.090504s
      #
      #    Comparison:
      #    xpath("//*[nokogiri-builtin:css-class(@class, 'xxxx')]"):     1343.0 i/s
      #    xpath("//*[contains(concat(' ', normalize-space(@class), ' '), ' xxxx ')]"):      681.3 i/s - 1.97x  (± 0.00) slower
      #
      #  but:
      #
      #    jruby 9.2.9.0 (2.5.7) 2019-10-30 458ad3e OpenJDK 64-Bit Server VM 11.0.9.1+1-Ubuntu-0ubuntu1.20.04 on 11.0.9.1+1-Ubuntu-0ubuntu1.20.04 [linux-x86_64]
      #    Warming up --------------------------------------
      #    xpath("//*[contains(concat(' ', normalize-space(@class), ' '), ' xxxx ')]")
      #                            74.000  i/100ms
      #    xpath("//*[nokogiri-builtin:css-class(@class, 'xxxx')]")
      #                            41.000  i/100ms
      #    Calculating -------------------------------------
      #    xpath("//*[contains(concat(' ', normalize-space(@class), ' '), ' xxxx ')]")
      #                            814.536  (± 9.6%) i/s -      8.066k in  10.022432s
      #    xpath("//*[nokogiri-builtin:css-class(@class, 'xxxx')]")
      #                            443.781  (± 6.8%) i/s -      4.428k in  10.029857s
      #
      #    Comparison:
      #    xpath("//*[contains(concat(' ', normalize-space(@class), ' '), ' xxxx ')]"):      814.5 i/s
      #    xpath("//*[nokogiri-builtin:css-class(@class, 'xxxx')]"):      443.8 i/s - 1.84x  (± 0.00) slower
      #
      #  If someone can explain to me why this is, and fix it, I will love you forever.
      #
      it ". class" do
        if Nokogiri.uses_libxml?
          assert_xpath(
            "//*[nokogiri-builtin:css-class(@class,'awesome')]",
            parser.parse(".awesome"),
          )
        else
          assert_xpath(
            "//*[contains(concat(' ',normalize-space(@class),' '),' awesome ')]",
            parser.parse(".awesome"),
          )
        end
      end

      it "~=" do
        if Nokogiri.uses_libxml?
          assert_xpath(
            "//a[nokogiri-builtin:css-class(@class,'bar')]",
            parser.parse("a[@class~='bar']"),
          )
        else
          assert_xpath(
            "//a[contains(concat(' ',normalize-space(@class),' '),' bar ')]",
            parser.parse("a[@class~='bar']"),
          )
        end
      end

      describe "XPathVisitorOptimallyUseBuiltins" do
        let(:visitor) { Nokogiri::CSS::XPathVisitorOptimallyUseBuiltins.new }

        it "supports deprecated class" do
          assert_output("", /XPathVisitorOptimallyUseBuiltins is deprecated/) { visitor }
          assert_instance_of(Nokogiri::CSS::XPathVisitor, visitor)
          assert_equal({ builtins: Nokogiri::CSS::XPathVisitor::BuiltinsConfig::OPTIMAL, doctype: Nokogiri::CSS::XPathVisitor::DoctypeConfig::XML }, visitor.config)

          if Nokogiri.uses_libxml?
            assert_xpath(
              "//*[nokogiri-builtin:css-class(@class,'awesome')]",
              parser.parse(".awesome"),
            )
          else
            assert_xpath(
              "//*[contains(concat(' ',normalize-space(@class),' '),' awesome ')]",
              parser.parse(".awesome"),
            )
          end
        end
      end
    end

    #
    #  HTML5 documents have namespaces, and gumbo attaches namespaces to the relevant elements; but
    #  CSS selectors should not require namespaces. See #2376 for the discussion around this design
    #  decision, along with some of the relevant benchmarks and call stack analyses.
    #
    #  (HTML5 today is only supported by CRuby/gumbo/libxml2 and so we'll ignore JRuby support for
    #  now.)
    #
    #  The way to implement this CSS search using standard XPath 1.0 queries is to check for a match
    #  with `local-name()`. However, this is about ~10x slower than a standard search along the
    #  `child` axis.
    #
    #  I've written a builtin function in C named `nokogiri-builtin:local-name-is()` which is a bit
    #  faster, but still ~7x slower than a standard search.
    #
    #  Finally, I've patched libxml2 to support wildcard namespaces, and this is ~1.1x slower but
    #  only available with the packaged libxml2.
    #
    #  In any case, the logic for the html5 builtins here goes:
    #
    #    if ALWAYS or (OPTIMAL and libxml2)
    #      if we've patched libxml2 with wildcard support
    #        use wildard namespacing
    #      else
    #        use `nokogiri-builtin:local-name-is()`
    #    else
    #      use `local-name()`
    #
    describe "doctype:html5" do
      let(:visitor) do
        Nokogiri::CSS::XPathVisitor.new(
          doctype: Nokogiri::CSS::XPathVisitor::DoctypeConfig::HTML5,
          builtins: builtins,
        )
      end

      describe "builtins:always" do
        let(:builtins) { Nokogiri::CSS::XPathVisitor::BuiltinsConfig::ALWAYS }

        it "matches on the element's local-name, ignoring namespaces" do
          if Nokogiri.libxml2_patches.include?("0009-allow-wildcard-namespaces.patch")
            assert_xpath("//*:foo", parser.parse("foo"))
          else
            assert_xpath("//*[nokogiri-builtin:local-name-is('foo')]", parser.parse("foo"))
          end
        end

        it "avoids the wildcard when using namespaces" do
          assert_xpath("//ns1:foo", parser.parse("ns1|foo"))
        end

        it "avoids the wildcard when using attribute selectors" do
          if Nokogiri.libxml2_patches.include?("0009-allow-wildcard-namespaces.patch")
            assert_xpath("//*:a/@href", parser.parse("a/@href"))
          else
            assert_xpath("//*[nokogiri-builtin:local-name-is('a')]/@href", parser.parse("a/@href"))
          end
        end
      end

      describe "builtins:never" do
        let(:builtins) { Nokogiri::CSS::XPathVisitor::BuiltinsConfig::NEVER }
        it "matches on the element's local-name, ignoring namespaces" do
          assert_xpath("//*[local-name()='foo']", parser.parse("foo"))
        end

        it "avoids the wildcard when using attribute selectors" do
          assert_xpath("//*[local-name()='a']/@href", parser.parse("a/@href"))
        end
      end

      describe "builtins:optimal" do
        let(:builtins) { Nokogiri::CSS::XPathVisitor::BuiltinsConfig::OPTIMAL }
        it "matches on the element's local-name, ignoring namespaces" do
          if Nokogiri.uses_libxml?
            if Nokogiri.libxml2_patches.include?("0009-allow-wildcard-namespaces.patch")
              assert_xpath("//*:foo", parser.parse("foo"))
            else
              assert_xpath("//*[nokogiri-builtin:local-name-is('foo')]", parser.parse("foo"))
            end
          else
            assert_xpath("//*[local-name()='foo']", parser.parse("foo"))
          end
        end
      end
    end
  end
end
