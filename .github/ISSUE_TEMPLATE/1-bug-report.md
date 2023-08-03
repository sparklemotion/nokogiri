---
name: "Bug Report"
about: "Open an issue to help us improve!"
title: "[bug]"
labels: "state/needs-triage"
assignees: ""

---

<!--
**Do not report Security Vulnerabilities here**

If you intend to report a security vulnerability, please do so at [HackerOne](https://hackerone.com/nokogiri) following the process detailed in [`SECURITY.md`](https://nokogiri.org/SECURITY.html). Do not report it through GitHub.
-->

**Please describe the bug**

<!--
A clear and concise description of what the bug is. Please include as much context as you can about what's going on.
-->

**Help us reproduce what you're seeing**

<!--
If possible, please include a complete, self-contained script that reproduces the behavior you're seeing. Please try to remove external dependencies like Rails or other libraries that may be wrapping Nokogiri.

Here's an example of how you might structure such a script:

```ruby
#! /usr/bin/env ruby

require 'nokogiri'
require 'minitest/autorun'

class Test < Minitest::Spec
  describe "Node#css" do
    it "should find a div using chained classes" do
      html = <<~HEREDOC
        <html>
          <body>
            <div class="foo"> one</div> 
            <div class="bar">two</div> 
            <div class="foo bar">three</div> 
      HEREDOC
      
      doc = Nokogiri::HTML::Document.parse(html)
      
      assert_equal 1, doc.css("div.foo.bar").length
      assert_equal "three", doc.at_css("div.foo.bar").text
    end
  end
end
```

If you haven't included a test, please provide whatever code you can, the inputs (if any), along with the output that you're seeing. We need to reproduce what you're seeing to be able to help!
-->


**Expected behavior**

<!--
If you haven't included a test above, please tell us precisely what you expected to happen.
-->


**Environment**

<!--
```
Please paste the output from `nokogiri -v` here, escaped by triple-backtick.
```

This output will tell us what version of Ruby you're using, how you installed nokogiri, what versions of the underlying libraries you're using, and what operating system you're using.
-->

**Additional context**

<!--
Add any other context about the problem here.
-->
