# coding: utf-8
# frozen_string_literal: true

require "helper"

describe Nokogiri::CSS::XPathVisitor do
  let(:visitor) { Nokogiri::CSS::XPathVisitor.new }

  def assert_xpath(expecteds, input_selector_list)
    expecteds = Array(expecteds)
    actuals = Nokogiri::CSS.xpath_for(input_selector_list, visitor: visitor, cache: false)

    expecteds.zip(actuals).each do |expected, actual|
      assert_equal(expected, actual)
    end
  end

  describe ".new" do
    it "accepts some config parameters" do
      assert_equal(
        Nokogiri::CSS::XPathVisitor::BuiltinsConfig::NEVER,
        Nokogiri::CSS::XPathVisitor.new(builtins: Nokogiri::CSS::XPathVisitor::BuiltinsConfig::NEVER).builtins,
      )
      assert_equal(
        Nokogiri::CSS::XPathVisitor::BuiltinsConfig::ALWAYS,
        Nokogiri::CSS::XPathVisitor.new(builtins: Nokogiri::CSS::XPathVisitor::BuiltinsConfig::ALWAYS).builtins,
      )
      assert_equal(
        Nokogiri::CSS::XPathVisitor::BuiltinsConfig::OPTIMAL,
        Nokogiri::CSS::XPathVisitor.new(builtins: Nokogiri::CSS::XPathVisitor::BuiltinsConfig::OPTIMAL).builtins,
      )
      assert_raises(ArgumentError) { Nokogiri::CSS::XPathVisitor.new(builtins: :not_valid) }

      assert_equal(
        Nokogiri::CSS::XPathVisitor::DoctypeConfig::XML,
        Nokogiri::CSS::XPathVisitor.new(doctype: Nokogiri::CSS::XPathVisitor::DoctypeConfig::XML).doctype,
      )
      assert_equal(
        Nokogiri::CSS::XPathVisitor::DoctypeConfig::HTML4,
        Nokogiri::CSS::XPathVisitor.new(doctype: Nokogiri::CSS::XPathVisitor::DoctypeConfig::HTML4).doctype,
      )
      assert_equal(
        Nokogiri::CSS::XPathVisitor::DoctypeConfig::HTML5,
        Nokogiri::CSS::XPathVisitor.new(doctype: Nokogiri::CSS::XPathVisitor::DoctypeConfig::HTML5).doctype,
      )
      assert_raises(ArgumentError) { Nokogiri::CSS::XPathVisitor.new(doctype: :not_valid) }

      assert_equal({ foo: "bar" }, Nokogiri::CSS::XPathVisitor.new(namespaces: { foo: "bar" }).namespaces)

      assert_equal("xxx", Nokogiri::CSS::XPathVisitor.new(prefix: "xxx").prefix)
    end
  end

  describe "#config" do
    it "exposes its configuration" do
      expected = {
        builtins: Nokogiri::CSS::XPathVisitor::BuiltinsConfig::NEVER,
        doctype: Nokogiri::CSS::XPathVisitor::DoctypeConfig::XML,
        prefix: Nokogiri::XML::XPath::GLOBAL_SEARCH_PREFIX,
        namespaces: nil,
      }
      assert_equal(expected, visitor.config)

      assert_nil(visitor.namespaces)
      assert_equal(Nokogiri::XML::XPath::GLOBAL_SEARCH_PREFIX, visitor.prefix)
    end
  end

  describe "custom pseudo-classes via XPathVisitor methods" do
    it "pseudo-class functions" do
      visitor = Class.new(Nokogiri::CSS::XPathVisitor) do
        attr_accessor :called

        def visit_function_aaron(node)
          @called = true
          "aaron() = 1"
        end
      end.new

      assert_equal(
        ["//a[aaron() = 1]"],
        Nokogiri::CSS.xpath_for("a:aaron()", visitor: visitor, cache: false),
      )
      assert visitor.called
    end

    it "pseudo-classes selectors" do
      visitor = Class.new(Nokogiri::CSS::XPathVisitor) do
        attr_accessor :called

        def visit_pseudo_class_aaron(node)
          @called = true
          "aaron() = 1"
        end
      end.new

      assert_equal(
        ["//a[aaron() = 1]"],
        Nokogiri::CSS.xpath_for("a:aaron", visitor: visitor, cache: false),
      )
      assert visitor.called
    end
  end

  describe "selectors" do
    it "* universal" do
      assert_xpath("//*", "*")
    end

    it "type" do
      assert_xpath("//x", "x")
    end

    it "type with namespaces" do
      assert_xpath("//aaron:a", "aaron|a")
      assert_xpath("//a", "|a")
    end

    it ". class" do
      assert_xpath(
        "//*[contains(concat(' ',normalize-space(@class),' '),' awesome ')]",
        ".awesome",
      )
      assert_xpath(
        "//foo[contains(concat(' ',normalize-space(@class),' '),' awesome ')]",
        "foo.awesome",
      )
      assert_xpath(
        "//foo//*[contains(concat(' ',normalize-space(@class),' '),' awesome ')]",
        "foo .awesome",
      )
      assert_xpath(
        "//foo//*[contains(concat(' ',normalize-space(@class),' '),' awe.some ')]",
        "foo .awe\\.some",
      )
      assert_xpath(
        "//*[contains(concat(' ',normalize-space(@class),' '),' a ') and contains(concat(' ',normalize-space(@class),' '),' b ')]",
        ".a.b",
      )
      assert_xpath(
        "//*[contains(concat(' ',normalize-space(@class),' '),' pastoral ')]",
        "*.pastoral",
      )
    end

    describe "namespaces" do
      let(:ns) do
        {
          "xmlns" => "http://default.example.com/",
          "hoge" => "http://hoge.example.com/",
        }
      end

      it "basic mechanics" do
        assert_xpath("//a[@flavorjones:href]", "a[flavorjones|href]")
        assert_xpath("//a[@href]", "a[|href]")
        assert_xpath("//*[@flavorjones:href]", "*[flavorjones|href]")
      end

      it "default namespace is applied to elements but not attributes" do
        assert_equal(
          ["//xmlns:a[@class='bar']"],
          Nokogiri::CSS.xpath_for("a[class='bar']", ns: ns, cache: false),
        )
      end

      it "default namespace is not applied to wildcard selectors" do
        assert_equal(
          ["//xmlns:a//*"],
          Nokogiri::CSS.xpath_for("a *", ns: ns, cache: false),
        )
      end

      it "intentionally-empty namespace omits the default xmlns" do
        # An intentionally-empty namespace
        assert_equal(["//a"], Nokogiri::CSS.xpath_for("|a", ns: ns, cache: false))
      end

      it "explicit namespaces are applied to attributes" do
        assert_equal(
          ["//xmlns:a[@hoge:class='bar']"],
          Nokogiri::CSS.xpath_for("a[hoge|class='bar']", ns: ns, cache: false),
        )
      end
    end

    describe "attribute" do
      it "basic mechanics" do
        assert_xpath("//h1[@a='Tender Lovemaking']", "h1[a='Tender Lovemaking']")
        assert_xpath("//h1[@a]", "h1[a]")
        assert_xpath(%q{//h1[@a='gnewline\n']}, "h1[a='\\gnew\\\nline\\\\n']")
        assert_xpath("//h1[@a='test']", %q{h1[a=\te\st]})
      end

      it "#id escaping" do
        assert_xpath("//*[@id='foo']", "#foo")
        assert_xpath("//*[@id='escape:needed,']", "#escape\\:needed\\,")
        assert_xpath("//*[@id='escape:needed,']", '#escape\3Aneeded\,')
        assert_xpath("//*[@id='escape:needed,']", '#escape\3A needed\2C')
        assert_xpath("//*[@id='escape:needed']", '#escape\00003Aneeded')
      end

      it "parses leading @ (extended-syntax)" do
        assert_xpath("//a[@id='Boing']", "a[@id='Boing']")
        assert_xpath("//a[@id='Boing']", "a[@id = 'Boing']")
        assert_xpath("//a[@id='Boing']//div", "a[@id='Boing'] div")
      end

      it "rhs with quotes" do
        assert_xpath(%q{//h1[@a="'"]}, %q{h1[a="'"]})
        assert_xpath(%q{//h1[@a=concat("'","")]}, "h1[a='\\'']")
        assert_xpath(%q{//h1[@a=concat("",'"',"'","")]}, %q{h1[a='"\'']})
      end

      it "rhs is number or string" do
        assert_xpath("//img[@width='200']", "img[width='200']")
        assert_xpath("//img[@width='200']", "img[width=200]")
      end

      it "bare" do
        assert_xpath("//*[@a]//*[@b]", "[a] [b]")
      end

      it "|=" do
        assert_xpath(
          "//a[@class='bar' or starts-with(@class,concat('bar','-'))]",
          "a[class|='bar']",
        )
        assert_xpath(
          "//a[@class='bar' or starts-with(@class,concat('bar','-'))]",
          "a[class |= 'bar']",
        )
        assert_xpath(
          "//a[@id='Boing' or starts-with(@id,concat('Boing','-'))]",
          "a[id|='Boing']",
        )
      end

      it "|= (extended-syntax)" do
        assert_xpath(
          "//a[@class='bar' or starts-with(@class,concat('bar','-'))]",
          "a[@class|='bar']",
        )
        assert_xpath(
          "//a[@class='bar' or starts-with(@class,concat('bar','-'))]",
          "a[@class |= 'bar']",
        )
        assert_xpath(
          "//a[@id='Boing' or starts-with(@id,concat('Boing','-'))]",
          "a[@id|='Boing']",
        )
      end

      it "~=" do
        assert_xpath(
          "//a[contains(concat(' ',normalize-space(@class),' '),' bar ')]",
          "a[class~='bar']",
        )
        assert_xpath(
          "//a[contains(concat(' ',normalize-space(@class),' '),' bar ')]",
          "a[class ~= 'bar']",
        )
        assert_xpath(
          "//a[contains(concat(' ',normalize-space(@class),' '),' bar ')]",
          "a[class~=bar]",
        )
        assert_xpath(
          "//a[contains(concat(' ',normalize-space(@class),' '),' bar ')]",
          "a[class~=\"bar\"]",
        )
        assert_xpath(
          "//a[contains(concat(' ',normalize-space(@data-words),' '),' bar ')]",
          "a[data-words~=\"bar\"]",
        )
      end

      it "~= (extended-syntax)" do
        assert_xpath(
          "//a[contains(concat(' ',normalize-space(@class),' '),' bar ')]",
          "a[@class~='bar']",
        )
        assert_xpath(
          "//a[contains(concat(' ',normalize-space(@class),' '),' bar ')]",
          "a[@class ~= 'bar']",
        )
        assert_xpath(
          "//a[contains(concat(' ',normalize-space(@class),' '),' bar ')]",
          "a[@class~=bar]",
        )
        assert_xpath(
          "//a[contains(concat(' ',normalize-space(@class),' '),' bar ')]",
          "a[@class~=\"bar\"]",
        )
        assert_xpath(
          "//a[contains(concat(' ',normalize-space(@data-words),' '),' bar ')]",
          "a[@data-words~=\"bar\"]",
        )
      end

      it "^=" do
        assert_xpath("//a[starts-with(@id,'Boing')]", "a[id^='Boing']")
        assert_xpath("//a[starts-with(@id,'Boing')]", "a[id ^= 'Boing']")
      end

      it "$=" do
        assert_xpath(
          "//a[substring(@id,string-length(@id)-string-length('Boing')+1,string-length('Boing'))='Boing']",
          "a[id$='Boing']",
        )
        assert_xpath(
          "//a[substring(@id,string-length(@id)-string-length('Boing')+1,string-length('Boing'))='Boing']",
          "a[id $= 'Boing']",
        )
      end

      it "*=" do
        assert_xpath("//a[contains(@id,'Boing')]", "a[id*='Boing']")
        assert_xpath("//a[contains(@id,'Boing')]", "a[id *= 'Boing']")
      end

      it "!= (extended-syntax)" do
        assert_xpath("//a[@id!='Boing']", "a[id!='Boing']")
        assert_xpath("//a[@id!='Boing']", "a[id != 'Boing']")
      end
    end
  end

  describe "pseudo-classes" do
    it ":first-of-type" do
      assert_xpath("//a[position()=1]", "a:first-of-type()")
      assert_xpath("//a[position()=1]", "a:first-of-type") # no parens
      assert_xpath(
        "//a[contains(concat(' ',normalize-space(@class),' '),' b ')][position()=1]",
        "a.b:first-of-type",
      ) # no parens
    end

    it ":nth-of-type" do
      assert_xpath("//a[position()=99]", "a:nth-of-type(99)")
      assert_xpath(
        "//a[contains(concat(' ',normalize-space(@class),' '),' b ')][position()=99]",
        "a.b:nth-of-type(99)",
      )
    end

    it ":last-of-type" do
      assert_xpath("//a[position()=last()]", "a:last-of-type()")
      assert_xpath("//a[position()=last()]", "a:last-of-type") # no parens
      assert_xpath(
        "//a[contains(concat(' ',normalize-space(@class),' '),' b ')][position()=last()]",
        "a.b:last-of-type",
      ) # no parens
    end

    it ":nth-last-of-type" do
      assert_xpath("//a[position()=last()]", "a:nth-last-of-type(1)")
      assert_xpath("//a[position()=last()-98]", "a:nth-last-of-type(99)")
      assert_xpath(
        "//a[contains(concat(' ',normalize-space(@class),' '),' b ')][position()=last()-98]",
        "a.b:nth-last-of-type(99)",
      )
    end

    it ":nth and friends (extended-syntax)" do
      assert_xpath("//a[position()=1]", "a:first()")
      assert_xpath("//a[position()=1]", "a:first") # no parens
      assert_xpath("//a[position()=99]", "a:eq(99)")
      assert_xpath("//a[position()=99]", "a:nth(99)")
      assert_xpath("//a[position()=last()]", "a:last()")
      assert_xpath("//a[position()=last()]", "a:last") # no parens
      assert_xpath("//a[node()]", "a:parent")
    end

    it ":nth-child and friends" do
      assert_xpath("//a[count(preceding-sibling::*)=0]", "a:first-child")
      assert_xpath("//a[count(preceding-sibling::*)=98]", "a:nth-child(99)")
      assert_xpath("//a[count(following-sibling::*)=0]", "a:last-child")
      assert_xpath("//a[count(following-sibling::*)=0]", "a:nth-last-child(1)")
      assert_xpath("//a[count(following-sibling::*)=98]", "a:nth-last-child(99)")
    end

    it "[n] as :nth-child (extended-syntax)" do
      assert_xpath("//a[count(preceding-sibling::*)=1]", "a[2]")
    end

    it ":has()" do
      assert_xpath("//a[.//b]", "a:has(b)")
      assert_xpath("//a[.//b/c]", "a:has(b > c)")
      assert_xpath("//a[./b]", "a:has(> b)")
      assert_xpath("//a[./following-sibling::b]", "a:has(~ b)")
      assert_xpath("//a[./following-sibling::*[1]/self::b]", "a:has(+ b)")
    end

    it ":only-child" do
      assert_xpath(
        "//a[count(preceding-sibling::*)=0 and count(following-sibling::*)=0]",
        "a:only-child",
      )
    end

    it ":only-of-type" do
      assert_xpath("//a[last()=1]", "a:only-of-type")
    end

    it ":empty" do
      assert_xpath("//a[not(node())]", "a:empty")
    end

    it ":nth(an+b)" do
      assert_xpath("//a[(position() mod 2)=0]", "a:nth-of-type(2n)")
      assert_xpath("//a[(position()>=1) and (((position()-1) mod 2)=0)]", "a:nth-of-type(2n+1)")
      assert_xpath("//a[(position()>=1) and (((position()-1) mod 2)=0)]", "a:nth-of-type(2n + 1)")
      assert_xpath("//a[(position() mod 2)=0]", "a:nth-of-type(even)")
      assert_xpath("//a[(position()>=1) and (((position()-1) mod 2)=0)]", "a:nth-of-type(odd)")
      assert_xpath("//a[(position()>=3) and (((position()-3) mod 4)=0)]", "a:nth-of-type(4n+3)")
      assert_xpath("//a[position()<=3]", "a:nth-of-type(-1n+3)")
      assert_xpath("//a[position()<=3]", "a:nth-of-type(-1n +  3)")
      assert_xpath("//a[position()<=3]", "a:nth-of-type(-n+3)")
      assert_xpath("//a[position()>=3]", "a:nth-of-type(1n+3)")
      assert_xpath("//a[position()>=3]", "a:nth-of-type(n+3)")

      assert_xpath("//a[((last()-position()+1) mod 2)=0]", "a:nth-last-of-type(2n)")
      assert_xpath("//a[((last()-position()+1)>=1) and ((((last()-position()+1)-1) mod 2)=0)]", "a:nth-last-of-type(2n+1)")
      assert_xpath("//a[((last()-position()+1) mod 2)=0]", "a:nth-last-of-type(even)")
      assert_xpath("//a[((last()-position()+1)>=1) and ((((last()-position()+1)-1) mod 2)=0)]", "a:nth-last-of-type(odd)")
      assert_xpath("//a[((last()-position()+1)>=3) and ((((last()-position()+1)-3) mod 4)=0)]", "a:nth-last-of-type(4n+3)")
      assert_xpath("//a[(last()-position()+1)<=3]", "a:nth-last-of-type(-1n+3)")
      assert_xpath("//a[(last()-position()+1)<=3]", "a:nth-last-of-type(-n+3)")
      assert_xpath("//a[(last()-position()+1)>=3]", "a:nth-last-of-type(1n+3)")
      assert_xpath("//a[(last()-position()+1)>=3]", "a:nth-last-of-type(n+3)")
    end

    it ":not()" do
      assert_xpath("//ol/*[not(self::li)]", "ol > *:not(li)")
      assert_xpath(
        "//*[@id='p' and not(contains(concat(' ',normalize-space(@class),' '),' a '))]",
        "#p:not(.a)",
      )
      assert_xpath(
        "//p[contains(concat(' ',normalize-space(@class),' '),' a ') and not(contains(concat(' ',normalize-space(@class),' '),' b '))]",
        "p.a:not(.b)",
      )
      assert_xpath(
        "//p[@a='foo' and not(contains(concat(' ',normalize-space(@class),' '),' b '))]",
        "p[a='foo']:not(.b)",
      )
    end

    it "chained :not()" do
      assert_xpath(
        "//p[not(contains(concat(' ',normalize-space(@class),' '),' a ')) and not(contains(concat(' ',normalize-space(@class),' '),' b ')) and not(contains(concat(' ',normalize-space(@class),' '),' c '))]",
        "p:not(.a):not(.b):not(.c)",
      )
    end

    it "combinations of :not() and nth-and-friends" do
      assert_xpath(
        "//ol/*[not(count(following-sibling::*)=0)]",
        "ol > *:not(:last-child)",
      )
      assert_xpath(
        "//ol/*[not(count(preceding-sibling::*)=0 and count(following-sibling::*)=0)]",
        "ol > *:not(:only-child)",
      )
    end

    it "miscellaneous pseudo-classes are converted into xpath function calls" do
      assert_xpath("//a[nokogiri:aaron(.)]", "a:aaron")
      assert_xpath("//a[nokogiri:aaron(.)]", "a:aaron()")
      assert_xpath("//a[nokogiri:aaron(.,12)]", "a:aaron(12)")
      assert_xpath("//a[nokogiri:aaron(.,12,1)]", "a:aaron(12, 1)")

      assert_xpath("//a[nokogiri:link(.)]", "a:link")
      assert_xpath("//a[nokogiri:visited(.)]", "a:visited")
      assert_xpath("//a[nokogiri:hover(.)]", "a:hover")
      assert_xpath("//a[nokogiri:active(.)]", "a:active")

      assert_xpath("//a[nokogiri:foo(.,@href)]", "a:foo(@href)")
      assert_xpath("//a[nokogiri:foo(.,@href,@id)]", "a:foo(@href, @id)")
      assert_xpath("//a[nokogiri:foo(.,@a,b)]", "a:foo(@a, b)")
      assert_xpath("//a[nokogiri:foo(.,a,@b)]", "a:foo(a, @b)")
      assert_xpath("//a[nokogiri:foo(.,a,10)]", "a:foo(a, 10)")
      assert_xpath("//a[nokogiri:foo(.,42)]", "a:foo(42)")
      assert_xpath("//a[nokogiri:foo(.,'bar')]", "a:foo('bar')")
    end

    it "bare pseudo-class matches any ident" do
      assert_xpath("//*[nokogiri:link(.)]", ":link")
      assert_xpath("//*[not(@id='foo')]", ":not(#foo)")
      assert_xpath("//*[count(preceding-sibling::*)=0]", ":first-child")
    end
  end

  describe "combinators" do
    it "descendant" do
      assert_xpath("//x//y", "x y")
    end

    it "~ general sibling" do
      assert_xpath("//E/following-sibling::F", "E ~ F")
      assert_xpath("//E/following-sibling::F//G", "E ~ F G")
    end

    it "~ general sibling prefixless is relative to context node" do
      assert_xpath("./following-sibling::a", "~a")
      assert_xpath("./following-sibling::a", "~ a")
      assert_xpath("./following-sibling::a//b/following-sibling::i", "~a b~i")
      assert_xpath("./following-sibling::a//b/following-sibling::i", "~ a b ~ i")
    end

    it "+ adjacent sibling" do
      assert_xpath("//E/following-sibling::*[1]/self::F", "E + F")
      assert_xpath("//E/following-sibling::*[1]/self::F//G", "E + F G")
    end

    it "+ adjacent sibling prefixless is relative to context node" do
      assert_xpath("./following-sibling::*[1]/self::a", "+a")
      assert_xpath("./following-sibling::*[1]/self::a", "+ a")
      assert_xpath("./following-sibling::*[1]/self::a/following-sibling::*[1]/self::b", "+a+b")
      assert_xpath("./following-sibling::*[1]/self::a/following-sibling::*[1]/self::b", "+ a + b")
    end

    it "> child" do
      assert_xpath("//x/y", "x > y")
      assert_xpath("//a//b/i", "a b>i")
      assert_xpath("//a//b/i", "a b > i")
      assert_xpath("//a/b/i", "a > b > i")
    end

    it "> child prefixless is relative to context node" do
      assert_xpath("./a", ">a")
      assert_xpath("./a", "> a")
      assert_xpath("./a//b/i", ">a b>i")
      assert_xpath("./a/b/i", "> a > b > i")
    end

    it "/ (extended-syntax)" do
      assert_xpath("//x/y", "x/y")
      assert_xpath("//x/y", "x / y")
    end

    it "// (extended-syntax)" do
      assert_xpath("//x//y", "x//y")
      assert_xpath("//x//y", "x // y")
    end
  end

  describe "functions" do
    it "handles text() (extended-syntax)" do
      assert_xpath("//a[child::text()]", "a[text()]")
      assert_xpath("//child::text()", "text()")
      assert_xpath("//a//child::text()", "a text()")
      assert_xpath("//a/child::text()", "a / text()")
      assert_xpath("//a/child::text()", "a > text()")
      assert_xpath("//a//child::text()", "a text()")
    end

    it "handles comment() (extended-syntax)" do
      assert_xpath("//script//comment()", "script comment()")
    end

    it "handles contains() (extended-syntax)" do
      # https://api.jquery.com/contains-selector/
      assert_xpath(%{//div[contains(.,"youtube")]}, %{div:contains("youtube")})
    end

    it "handles gt() (extended-syntax)" do
      # https://api.jquery.com/gt-selector/
      assert_xpath("//td[position()>3]", "td:gt(3)")
    end

    it "handles self()" do
      # TODO: it's unclear how this is useful and we should consider deprecating it
      assert_xpath("//self::div", "self(div)")
    end
  end

  it "handles pseudo-class with class selector" do
    assert_xpath(
      "//a[nokogiri:active(.) and contains(concat(' ',normalize-space(@class),' '),' foo ')]",
      "a:active.foo",
    )
    assert_xpath(
      "//a[contains(concat(' ',normalize-space(@class),' '),' foo ') and nokogiri:active(.)]",
      "a.foo:active",
    )
  end

  it "handles pseudo-class with an id selector" do
    assert_xpath("//a[@id='foo' and nokogiri:active(.)]", "a#foo:active")
    assert_xpath("//a[nokogiri:active(.) and @id='foo']", "a:active#foo")
  end

  it "handles function with pseudo-class" do
    assert_xpath("//child::text()[position()=99]", "text():nth-of-type(99)")
  end

  it "handles multiple selectors" do
    assert_xpath(["//x/y", "//y/z"], "x > y, y > z")
    assert_xpath(["//x/y", "//y/z"], "x > y,y > z")
  end

  describe "builtins:always" do
    let(:visitor) { Nokogiri::CSS::XPathVisitor.new(builtins: Nokogiri::CSS::XPathVisitor::BuiltinsConfig::ALWAYS) }

    it "exposes its configuration" do
      expected = {
        builtins: Nokogiri::CSS::XPathVisitor::BuiltinsConfig::ALWAYS,
        doctype: Nokogiri::CSS::XPathVisitor::DoctypeConfig::XML,
        prefix: Nokogiri::XML::XPath::GLOBAL_SEARCH_PREFIX,
        namespaces: nil,
      }
      assert_equal(expected, visitor.config)
    end

    it ". class" do
      assert_xpath(
        "//*[nokogiri-builtin:css-class(@class,'awesome')]",
        ".awesome",
      )
      assert_xpath(
        "//foo[nokogiri-builtin:css-class(@class,'awesome')]",
        "foo.awesome",
      )
      assert_xpath(
        "//foo//*[nokogiri-builtin:css-class(@class,'awesome')]",
        "foo .awesome",
      )
      assert_xpath(
        "//foo//*[nokogiri-builtin:css-class(@class,'awe.some')]",
        "foo .awe\\.some",
      )
      assert_xpath(
        "//*[nokogiri-builtin:css-class(@class,'a') and nokogiri-builtin:css-class(@class,'b')]",
        ".a.b",
      )
    end

    it "~=" do
      assert_xpath(
        "//a[nokogiri-builtin:css-class(@class,'bar')]",
        "a[class~='bar']",
      )
      assert_xpath(
        "//a[nokogiri-builtin:css-class(@class,'bar')]",
        "a[class ~= 'bar']",
      )
      assert_xpath(
        "//a[nokogiri-builtin:css-class(@class,'bar')]",
        "a[class~=bar]",
      )
      assert_xpath(
        "//a[nokogiri-builtin:css-class(@class,'bar')]",
        "a[class~=\"bar\"]",
      )
      assert_xpath(
        "//a[nokogiri-builtin:css-class(@data-words,'bar')]",
        "a[data-words~=\"bar\"]",
      )
    end

    it "~= (extended-syntax)" do
      assert_xpath(
        "//a[nokogiri-builtin:css-class(@class,'bar')]",
        "a[@class~='bar']",
      )
      assert_xpath(
        "//a[nokogiri-builtin:css-class(@class,'bar')]",
        "a[@class ~= 'bar']",
      )
      assert_xpath(
        "//a[nokogiri-builtin:css-class(@class,'bar')]",
        "a[@class~=bar]",
      )
      assert_xpath(
        "//a[nokogiri-builtin:css-class(@class,'bar')]",
        "a[@class~=\"bar\"]",
      )
      assert_xpath(
        "//a[nokogiri-builtin:css-class(@data-words,'bar')]",
        "a[@data-words~=\"bar\"]",
      )
    end
  end

  describe "builtins:optimal" do
    let(:visitor) { Nokogiri::CSS::XPathVisitor.new(builtins: Nokogiri::CSS::XPathVisitor::BuiltinsConfig::OPTIMAL) }

    it "exposes its configuration" do
      expected = {
        builtins: Nokogiri::CSS::XPathVisitor::BuiltinsConfig::OPTIMAL,
        doctype: Nokogiri::CSS::XPathVisitor::DoctypeConfig::XML,
        prefix: Nokogiri::XML::XPath::GLOBAL_SEARCH_PREFIX,
        namespaces: nil,
      }
      assert_equal(expected, visitor.config)
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
          ".awesome",
        )
      else
        assert_xpath(
          "//*[contains(concat(' ',normalize-space(@class),' '),' awesome ')]",
          ".awesome",
        )
      end
    end

    it "~=" do
      if Nokogiri.uses_libxml?
        assert_xpath(
          "//a[nokogiri-builtin:css-class(@class,'bar')]",
          "a[class~='bar']",
        )
      else
        assert_xpath(
          "//a[contains(concat(' ',normalize-space(@class),' '),' bar ')]",
          "a[class~='bar']",
        )
      end
    end

    it "~= (extended-syntax)" do
      if Nokogiri.uses_libxml?
        assert_xpath(
          "//a[nokogiri-builtin:css-class(@class,'bar')]",
          "a[@class~='bar']",
        )
      else
        assert_xpath(
          "//a[contains(concat(' ',normalize-space(@class),' '),' bar ')]",
          "a[@class~='bar']",
        )
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
          assert_xpath("//*:foo", "foo")
        else
          assert_xpath("//*[nokogiri-builtin:local-name-is('foo')]", "foo")
        end
      end

      it "avoids the wildcard when using namespaces" do
        assert_xpath("//ns1:foo", "ns1|foo")
      end

      it "avoids the wildcard when using attribute selectors (extended-syntax)" do
        if Nokogiri.libxml2_patches.include?("0009-allow-wildcard-namespaces.patch")
          assert_xpath("//*:a/@href", "a/@href")
        else
          assert_xpath("//*[nokogiri-builtin:local-name-is('a')]/@href", "a/@href")
        end
      end
    end

    describe "builtins:never" do
      let(:builtins) { Nokogiri::CSS::XPathVisitor::BuiltinsConfig::NEVER }
      it "matches on the element's local-name, ignoring namespaces" do
        assert_xpath("//*[local-name()='foo']", "foo")
      end

      it "avoids the wildcard when using attribute selectors (extended-syntax)" do
        assert_xpath("//*[local-name()='a']/@href", "a/@href")
      end
    end

    describe "builtins:optimal" do
      let(:builtins) { Nokogiri::CSS::XPathVisitor::BuiltinsConfig::OPTIMAL }
      it "matches on the element's local-name, ignoring namespaces" do
        if Nokogiri.uses_libxml?
          if Nokogiri.libxml2_patches.include?("0009-allow-wildcard-namespaces.patch")
            assert_xpath("//*:foo", "foo")
          else
            assert_xpath("//*[nokogiri-builtin:local-name-is('foo')]", "foo")
          end
        else
          assert_xpath("//*[local-name()='foo']", "foo")
        end
      end
    end
  end
end
