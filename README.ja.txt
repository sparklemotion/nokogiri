= Nokogiri (鋸)

* http://nokogiri.rubyforge.org/
* http://github.com/tenderlove/nokogiri/wikis
* http://github.com/tenderlove/nokogiri/tree/master
* http://rubyforge.org/mailman/listinfo/nokogiri-talk
* http://nokogiri.lighthouseapp.com/projects/19607-nokogiri/overview

== DESCRIPTION:

Nokogiri はHTMLやXMLやSAXやXSLTやReaderのパーサーです。

== FEATURES:

* XPath で探せる
* CSS3 のセレクターで探せる
* XML/HTMLのビルダーはある

検索出来たり、正確にCSS3とXPathをサポート出来たりする。

これはスピードテストです：

  * http://gist.github.com/24605

NokogiriはHpricotの代わりに使用出来る。
その互換性は簡単に正しいCSSとXPathを使用する事が出来る。

== SUPPORT:

ノコギリのメーリングリストは:

  * http://rubyforge.org/mailman/listinfo/nokogiri-talk

バグファイルは:

  * http://nokogiri.lighthouseapp.com/projects/19607-nokogiri/overview

== SYNOPSIS:

  require 'nokogiri'
  require 'open-uri'
  
  doc = Nokogiri::HTML(open('http://www.google.com/search?q=tenderlove'))
  
  ####
  # Search for nodes by css
  doc.css('h3.r a.l').each do |link|
    puts link.content
  end
  
  ####
  # Search for nodes by xpath
  doc.xpath('//h3/a[@class="l"]').each do |link|
    puts link.content
  end
  
  ####
  # Or mix and match.
  doc.search('h3.r a.l', '//h3/a[@class="l"]').each do |link|
    puts link.content
  end


== REQUIREMENTS:

* ruby 1.8 or 1.9
* libxml
* libxslt

== INSTALL:

* sudo gem install nokogiri

== LICENSE:

(The MIT License)

Copyright (c) 2008 - 2009:

* {Aaron Patterson}[http://tenderlovemaking.com]
* {Mike Dalessio}[http://mike.daless.io]

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
