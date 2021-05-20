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

Also, pull requests for documentation improvements are always welcome!


## Submitting Pull Requests

Pull requests that introduce behavior change must always contain a test demonstrating the behavior being introduced, fixed, or changed. These tests should ideally communicate to the maintainers the problem being solved. We will ask you for clarification if we don't understand the problem you're trying to solve.

Please do not submit pull requests that make purely cosmetic changes to the code (style, naming, etc.). While we recognize that the code can always be improved, we would prefer you to focus on more impactful contributions.

Feel free to push a "work in progress" to take advantage of the feedback loops from CI. But then please indicate that it's still in progress by marking it as a [Draft Pull Request](https://docs.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-requests#draft-pull-requests).


## How to set up your local development environment

### Basic

Clone https://github.com/sparklemotion/nokogiri and run `bundle install`.


### Advanced

Please install the latest or previous version of CRuby (e.g., 3.0 or 2.7 as of 2021-02), and a recent version of JRuby. We recommend using a Ruby manager like `rvm` or `chruby` to make it easy to switch.

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

# major GC and a compaction after each test
NOKOGIRI_TEST_GC_LEVEL=compact bundle exec rake compile test

# verify references after compaction after every test
NOKOGIRI_TEST_GC_LEVEL=verify bundle exec rake compile test

# run with GC "stress mode" on
NOKOGIRI_TEST_GC_LEVEL=stress bundle exec rake compile test
```


### libxml2 advanced usage

If you want to build Nokogiri against a modified version of libxml2, clone libxml2 to `../libxml2` and then run `scripts/compile-against-libxml2-source`.

That script also takes an optional command to run with the proper environment variables set to use the local libxml2 library, which can be useful when trying to `git bisect` against libxml2.



## Style Guide

I don't feel very strongly about code style, but when possible I follow [Shopify's Ruby Style Guide](https://shopify.github.io/ruby-style-guide/), and for C and Java code I use the `astyle` settings laid out in `/rakelib/format.rake`.

You can format the C and Java code with `rake format`. Maybe someday I'll auto-format Ruby, but not today.

No, I don't want to talk to you about this.


## How Continuous Integration ("CI") is configured

This section could probably be an entire guide unto itself, so I'll try to be as brief as reasonable.

We currently have CI tests running in three places:

- [Concourse](https://ci.nokogiri.org/?search=nokogiri): Linux, including many debugging and integration test
- [Github Actions](https://github.com/sparklemotion/nokogiri/actions/workflows/macos.yml): for MacOS only
- [Appveyor](https://ci.appveyor.com/project/flavorjones/nokogiri): for Windows only

This is ... not great. I'd love to set up everything to be in one place, but each has its advantages. It might be possible to move Windows testing to Github Actions, but honestly I'm kinda waiting for someone from the Ruby Windows community to figure that out.

I've set up "required" builds for the `main` branch in Github so that PRs can see and be bound by all these tests passing.

### Concourse

We run the bulk of our tests under Concourse. Concourse is great for me because

- I can hijack a container if a test fails and poke around in it
- I can conditionally trigger the builds like a real pipeline
- I can run it locally on my dev machine
- I have complete control over the images used

The downside is, nobody in the Ruby community besides me and Dr. Nic know how to operate it or configure it.

In any case, the general pipeline we use is the same for `main` and for PRs includes:

- basic security sanity check: run rubocop
- fast feedback for obvious failures: run against system libraries on vanilla ubuntu
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
- build a "ruby" platform gem
    - install and test on vanilla ubuntu
    - install and test on musl
- build a native 64-bit linux gem
    - install and test on vanilla ubuntu with all supported versions of CRuby
    - install and test on musl
- build a native 32-bit linux gem
    - install and test on vanilla ubuntu
    - install and test on musl
- build a jruby gem, install and test it

These pipelines are configured in `/concourse/nokogiri.yml` and `nokogiri-pr.yml`. Those files file are ... nontrivial, and I'm sorry about that. See https://github.com/flavorjones/concourse-gem for help.


### Valgrind

We rely heavily on Valgrind to catch memory bugs by running in combination with every version of CRuby. We use suppressions, too -- because some Rubies seem to have memory issues? See the files in the `/suppressions` directory and `/rakelib/test.rake` for more information.


### TruffleRuby

As of 2021-02, TruffleRuby tests are in a separate pipeline because they are failing in known ways that we haven't addressed yet, mostly related to error handling in SAX callbacks due to Sulong limitations.


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
- [ ] create a release at https://github.com/sparklemotion/nokogiri/releases
- [ ] if security-related, email ruby-security-ann@googlegroups.com and ruby-talk@ruby-lang.org


## Code of Conduct

Our full Code of Conduct is in [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).

For best results, be nice. Remember that Nokogiri maintainers are volunteers, and treat them with respect.

Do not act entitled to service. Do not be rude. Do not use judgmental or foul language.

The maintainers reserve the right to delete comments that are rude, or that contain foul language. The maintainers reserve the right to delete comments that they deem harassing or offensive.
