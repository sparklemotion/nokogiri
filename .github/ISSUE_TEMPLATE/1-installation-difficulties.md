---
name: "Installation Difficulties"
about: "If you're having trouble installing Nokogiri ..."
title: "[install]"
labels: "topic/installation"
assignees: ""

---

**Have you read and followed the installation tutorial at http://www.nokogiri.org/tutorials/installing_nokogiri.html?**

- [ ] Yes!


**What is the complete output of `gem install` or `bundle install`?**

<!-- Please make sure to escape the file contents with triple-backticks. -->

```
the output goes here
```


**If installation completed but is broken, what is the complete output from `nokogiri -v`?**

<!-- Please make sure to escape the file contents with triple-backticks. -->

```
the output of "nokogiri -v" goes here
```



**If installation failed during compilation, what are the complete contents of the `mkmf.log` file generated during the failed installation?**

<!-- Please make sure to escape the file contents with triple-backticks. -->

```
the mkmf.log file contents go here
```


**Tell us about your system!**

What is the output from `ruby -v`?

What is the output from `gem -v`?

What is the output from `gem env`?

```
the output of "gem env" output goes here
```


If you're using Bundler:
- what is the output from `bundle version`?
- what is the output from `bundle config`? (Take care to redact any credentials)

```
the output of "bundle config" goes here
```

If you're on MacOS, please note:
- the version of XCode you have installed (if you know)
- the output of `gcc -v` or `clang -v`

If Linux or a BSD variant, please note:
- the distro you're using
- the output of `uname -a`
- the contents of `/etc/lsb-release`.

If Windows, please note:
- whether you're installing the precompiled gems, or compiling yourself with DevKit
- the version of RubyInstaller you've installed
- or if you're not using RubyInstaller, how did you install Ruby?
