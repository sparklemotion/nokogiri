# Contributing to Nokogiri

**This document is still a work-in-progress.**

This doc is intended to be a short introduction on how to modify and maintain Nokogiri.

If you're looking for guidance on filing a bug report or getting support, please visit the ["Getting Help" tutorial](http://www.nokogiri.org/tutorials/getting_help.html) at the [nokogiri.org](http://nokogiri.org) site.

## Contents

<!-- regenerate with `markdown-toc --maxdepth=2 -i CONTRIBUTING.md` -->

<!-- toc -->

- [Introduction](#introduction)
- [Some guiding principles of the project](#some-guiding-principles-of-the-project)
- [Where to start getting involved](#where-to-start-getting-involved)
- [Submitting Pull Requests](#submitting-pull-requests)
- [How to set up your local development environment](#how-to-set-up-your-local-development-environment)
- [How to run the tests](#how-to-run-the-tests)
- [Style Guide](#style-guide)
- [How Continuous Integration ("CI") is configured](#how-continuous-integration-ci-is-configured)
- [Building gems](#building-gems)
- [Other utilities](#other-utilities)
- [Rake tasks](#rake-tasks)
- [Making a release](#making-a-release)
- [Code of Conduct](#code-of-conduct)

<!-- tocstop -->

## Introduction

Hello there! I'm super excited that you're interested in contributing to Nokogiri. Welcome!

This document is intended only to provide a brief introduction on how to contribute to Nokogiri. It's not a complete specification of everything you need to know, so if you want to know more, I encourage you to reach out to the maintainers in the [Discord channel](https://nokogiri.org/tutorials/getting_help.html#ask-for-help). We'd love to get to know you a bit better!

## Some guiding principles of the project

The top guiding principles, as noted in the README are:

- be secure-by-default by treating all documents as **untrusted** by default
- be a **thin-as-reasonable layer** on top of the underlying parsers, and don't attempt to fix behavioral differences between the parsers


Nokogiri supports both CRuby and JRuby, and has native code specific to each (though much Ruby code is shared between them). Some related secondary principles are:

- Whenever possible, implement the same functionality for both CRuby and JRuby.
- Whenever possible, implement shared behavior as shared Ruby code (i.e., write as little native code as reasonable).
- Whenever possible, write tests that are not platform-specific (which includes skipping).

Notably, despite all parsers being standards-compliant, there are behavioral inconsistencies between the parsers used in the CRuby and JRuby implementations, and Nokogiri does not and should not attempt to remove these inconsistencies. Instead, we surface these differences in the test suite when they are important/semantic; or we intentionally write tests to depend only on the important/semantic bits (omitting whitespace from regex matchers on results, for example).


Nokogiri is widely used in the Ruby ecosystem, and so extra care should be taken to avoid introducing breaking changes. Please read our [Semantic Versioning Policy](https://nokogiri.org/index.html#semantic-versioning-policy) to understand what we consider to be a breaking change.


## Where to start getting involved

Please take a look at our [Issues marked "Help Wanted"](https://github.com/sparklemotion/nokogiri/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22).

Also, [pull requests for documentation improvements are always welcome](#documentation)!


## Submitting Pull Requests

Pull requests that introduce behavior change must always contain a test demonstrating the behavior being introduced, fixed, or changed. These tests should ideally communicate to the maintainers the problem being solved. We will ask you for clarification if we don't understand the problem you're trying to solve.

Please do not submit pull requests that make purely cosmetic changes to the code (style, naming, etc.). While we recognize that the code can always be improved, we would prefer you to focus on more impactful contributions.

Feel free to push a "work in progress" to take advantage of the feedback loops from CI. But then please indicate that it's still in progress by marking it as a [Draft Pull Request](https://docs.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-requests#draft-pull-requests).


## How to set up your local development environment

### Basic

Clone https://github.com/sparklemotion/nokogiri and run `bundle install`.


### Advanced

Please install the latest or previous version of CRuby (e.g., 3.0 or 2.7 as of 2021-02), and a recent version of JRuby. We recommend using `rbenv`, which is used in test scripts when necessary to test gems against multiple rubies.

Please install a system version of libxml2/libxslt (see [Installing Nokogiri](https://nokogiri.org/tutorials/installing_nokogiri.html#installing-using-standard-system-libraries) for details) so that you can test against both the packaged libraries and your system libraries.

We recommend that you install `valgrind` if you can, but it's only necessary for debugging problems so feel free to wait until you need it. (I'm not sure valgrind is easily available on MacOS.)

If you plan to package precompiled native gems, make sure `docker` is installed and is working properly.


## How to run the tests

Note that `rake test` does not compile the native extension, and this is intentional. If you're modifying the extension code, please make sure you re-compile each time you run the tests to ensure you're testing your changes.


### The short version

``` sh
bundle exec rake compile test
```


### CRuby advanced usage

Test using your system's libraries:

``` sh
bundle exec rake clean # blow away pre-existing libraries using packaged libs
NOKOGIRI_USE_SYSTEM_LIBRARIES=t bundle exec rake compile test
```

Run tests using valgrind:

``` sh
bundle exec rake compile test:valgrind
```


Run tests in the debugger:

``` sh
bundle exec rake compile test:gdb
```


Note that by default the test suite will run a major GC after each test completes. This has shown to be useful for localizing entire classes of memory bugs, but does slow the suite down. Some variations of the test suite behavior are available (see `test/helper.rb` for more info):

``` sh
# see failure messages immediately
NOKOGIRI_TEST_FAIL_FAST=t bundle exec rake compile test

# ordinary GC behavior
NOKOGIRI_TEST_GC_LEVEL=normal bundle exec rake compile test

# minor GC after each test
NOKOGIRI_TEST_GC_LEVEL=minor bundle exec rake compile test

# major GC after each test
NOKOGIRI_TEST_GC_LEVEL=major bundle exec rake compile test

# major GC after each test and GC compaction after every 20 tests
NOKOGIRI_TEST_GC_LEVEL=compact bundle exec rake compile test

# verify references after compaction after every 20 tests
# (see https://alanwu.space/post/check-compaction/)
NOKOGIRI_TEST_GC_LEVEL=verify bundle exec rake compile test

# run with GC "stress mode" on
NOKOGIRI_TEST_GC_LEVEL=stress bundle exec rake compile test
```


### libxml2 advanced usage

If you want to build Nokogiri against a modified version of libxml2, clone libxml2 to `../libxml2` and then run `scripts/compile-against-libxml2-source`.

That script also takes an optional command to run with the proper environment variables set to use the local libxml2 library, which can be useful when trying to `git bisect` against libxml2.


### gumbo HTML5 parser

To run the test suite for the gumbo parser:

``` sh
bundle exec rake gumbo
```

To make sure to run additional html5lib tests for Nokogiri's HTML5 parser:

``` sh
git submodule update --init # test/html5lib-tests
bundle exec rake compile test
```


## Style Guide

### Documentation

We use `rdoc` to build Nokogiri's documentation. Run `rake rdoc` to build into the `./html` directory, and see the rdoc tasks in [rakelib/rdoc.rake](rakelib/rdoc.rake).

Previously we made some effort to move towards `yard` but that work was stopped (and the decision record can be found at [RFC: convert to use `yard` for documentation · Issue #1996 · sparklemotion/nokogiri](https://github.com/sparklemotion/nokogiri/issues/1996)).

I would prefer docstrings to be in `RDoc::Markup` format, though simple docstrings may be in Markdown (using `:markup: markdown`).

If you submit pull requests that improve documentation, **I will happily merge them** and credit you in the CHANGELOG.

Some guidelines (see [lib/nokogiri/xml/node.rb](lib/nokogiri/xml/node.rb) and [ext/nokogiri/xml/node.c](ext/nokogiri/xml/node.c) for examples):

- use `:call-seq:` to:
  - note the return type of the method whenever possible, e.g. `:call-seq: upcase(name) → String`
  - to name all the aliases of a method
  - to indicate block/yield usage of a method
- briefly explain the purpose of the method, what it returns, and what side effects it has
- use a `[Parameters]` definition to note the expected types of all the parameters as a bulleted list
- use a `[Returns]` definition to note the return type
- use a `[Yields]` definition to note the block parameters
- use a `⚠` character to warn the user about tricky usage
- use a `💡` character to call attention to important notes
- `See also:` should be used to call out related methods
- `Since` should be used to indicate the version that code was introduced
- prefer to show nuanced behavior in code examples, rather than by explaining it


### Code

I don't feel very strongly about code style, but when possible I follow [Shopify's Ruby Style Guide](https://shopify.github.io/ruby-style-guide/), and for C and Java code I use the `astyle` settings laid out in `/rakelib/format.rake`.

You can format the C, Java, and Ruby code with `rake format`.

There are likely some pending Rubocop rules in `.rubocop_todo.yml` which I'd be happy to merge if you enabled them and submit a PR.

No, I don't want to talk to you about any of the style choices.


## How Continuous Integration ("CI") is configured

The bulk of CI is running in Github Actions since May 2021: https://github.com/sparklemotion/nokogiri/actions

However, we also run tests against 32-bit windows (which aren't supported by GA as of this writing) in Appveyor: https://ci.appveyor.com/project/flavorjones/nokogiri

Please note that there are some known holes in CI coverage due to github actions limitations:

- installing ruby and native gems on 32-bit Linux, see:
  - [Error: /etc/*release "no such file or directory" · Issue #334 · actions/checkout](https://github.com/actions/checkout/issues/334)
  - [actions/cache is not working as expected in 32-bit linux containers · Issue #675 · actions/cache](https://github.com/actions/cache/issues/675)
  - [actions/upload-artifact is not working as expected in 32-bit linux containers · Issue #266 · actions/upload-artifact](https://github.com/actions/upload-artifact/issues/266)


### Coverage

The `ci.yml` pipeline includes jobs to:

- basic security sanity check: run rubocop
- fast feedback for obvious failures: run against system libraries on vanilla ubuntu
- run the gumbo parser tests on ubuntu, macos, and windows
- run on all supported versions of CRuby:
    - once with packaged libraries
    - once with system libraries
    - once on valgrind (to look for memory bugs)
- run on JRuby
- run on a Musl (Alpine) system:
    - against system libraries
    - with valgrind using packaged libraries
- run with libxml-ruby loaded (because this interacts with libxml2 in conflicting ways)
    - against system libraries
    - with valgrind using packaged libraries

The `upstream.yml` pipeline includes jobs to:

- run against CRuby head (linux, windows, macos) including valgrind
- run against JRuby head
- run against libxml2 and libxslt head (linux only today) including valgrind

The `gem-install.yml` pipeline includes jobs to:

- build a "ruby" platform gem
    - install and test on linux, macos, and windows
- build a native 64-bit gem (linux, macos, windows)
    - install and test against all supported versions of CRuby
    - install and test on musl
- build a jruby gem, install and test it

The `truffle.yml` pipeline tests TruffleRuby nightlies with a few different compile-time flags. TruffleRuby support is still experimental due to Sulong limitations, and the test suite is exceedingly slow when run by TR, so this pipeline doesn't run on pushes and PRs. Instead, it runs periodically on a timer to give us some signal without slowing down developer feedback loops.


### Valgrind

We rely heavily on Valgrind to catch memory bugs by running in combination with every version of CRuby. We use suppressions, too -- because some Rubies seem to have memory issues? See the files in the `/suppressions` directory and `/rakelib/test.rake` for more information.


### Conventions

- Always checkout the source code including submodules (for the html5lib tests)
- When testing packaged libraries (not system libraries), cache either `ports/` (for compiled libraries) or `ports/archives/` (for just tarballs)
  - note that `libgumbo` is built outside of `ports/` to allow us to do this caching safely


## Building gems

As a prerequisite please make sure you have `docker` correctly installed.

Run `scripts/build-gems` which will package gems for all supported platforms, and run some basic sanity tests on those packages using `scripts/test-gem-set`, `scripts/test-gem-file-contents`, and `scripts/test-gem-installation`.


## Other utilities

`scripts/test-exported-symbols` checks the compiled `nokogiri.so` library for surprising exported symbols. This script likely only works on Linux, sorry.

`scripts/test-nokogumbo-compatibility` is used by CI to ensure that Nokogumbo installs correctly against the currently-installed version of Nokogiri. Nokogumbo receives this extra care because it compiles against Nokogiri's and libxml2's header files, and makes assumptions about what symbols are exported by Nokogiri's extension library.

`scripts/files-modified-by-open-prs` is a hack to see what files are being proposed to change in the set of open pull requests. This might be useful if you're thinking about radically changing a file, to be aware of what merge conflicts might result. This could probably be a rake task.

There's a `Vagrantfile` in the project root which I've used once or twice to try to reproduce problems non-Linux systems (like OpenBSD). It's not well-maintained so YMMV.


## Rake tasks

The `Rakefile` used to be a big fat mess. It's now decomposed into a small set of files in `/rakelib`. If you've got a new rake task you'd like to introduce, please consider whether it belongs in one of the existing concerns, or needs a new file. Please don't add it to `Rakefile` without compelling reasons.


## Making a release

A quick checklist:

- [ ] make sure CI is green!
- [ ] update `CHANGELOG.md` and `lib/nokogiri/version/constant.rb`
- [ ] create a git tag
- [ ] run `scripts/build-gems` and make sure it completes and all the tests pass
- [ ] `for g in gems/*.gem ; do gem push $g ; done`
- [ ] create a release at https://github.com/sparklemotion/nokogiri/releases and provide sha2 checksums
- [ ] if security-related, email ruby-security-ann@googlegroups.com and ruby-talk@ruby-lang.org
- [ ] update nokogiri.org


## Code of Conduct

Our full Code of Conduct is in [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).

For best results, be nice. Remember that Nokogiri maintainers are volunteers, and treat them with respect.

Do not act entitled to service. Do not be rude. Do not use judgmental or foul language.

The maintainers reserve the right to delete comments that are rude, or that contain foul language. The maintainers reserve the right to delete comments that they deem harassing or offensive.
