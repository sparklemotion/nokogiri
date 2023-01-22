---
name: "Help Request"
about: "If something is confusing or you need a helping hand ..."
title: "[help]"
labels: "meta/user-help"
assignees: ""

---

**What problem are you trying to solve?**

<!--
A clear and concise description of what you're trying to do. Please try to describe the problem you're solving, rather than the solution you're implementing -- avoid the XY Problem! http://xyproblem.info/
-->

**Please show your code!**

<!--
If possible, please include whatever code you've written so far. We can give more focused advice if we are able to read and run some code.

Here's an example of how you might write such a script:

```ruby
#! /usr/bin/env ruby

require 'nokogiri'

xml = <<-EOF
<root>
  <bicycles>
    <bicycle color=red>Schwinn</bicycle>
  </bicycles>
</root>"
EOF

doc = Nokogiri::XML::Document.parse(xml)
puts doc.css("bicycle").count
```

Please provide whatever code you can, the inputs (if any), along with the output that you're seeing. We need to reproduce what you're seeing to be able to help!
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
