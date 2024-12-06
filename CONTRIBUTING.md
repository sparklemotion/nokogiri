# Contributing to Nokogiri

This doc is intended to be a short introduction on how to modify and maintain Nokogiri.

If you're looking for guidance on filing a bug report or getting support, please visit the ["Getting Help" tutorial](http://www.nokogiri.org/tutorials/getting_help.html) at the [nokogiri.org](http://nokogiri.org) site.


## Contents

<!-- regenerate TOC with `rake format:toc` -->

<!-- toc -->

- [Introduction](#introduction)
- [Code of Conduct](#code-of-conduct)
- [Some guiding principles of the project](#some-guiding-principles-of-the-project)
- [Where to start getting involved](#where-to-start-getting-involved)
- [Submitting Pull Requests](#submitting-pull-requests)
- [Branch Management and Release Management](#branch-management-and-release-management)
- [How to set up your local development environment](#how-to-set-up-your-local-development-environment)
- [How to run the tests](#how-to-run-the-tests)
- [Style Guide](#style-guide)
- [How Continuous Integration ("CI") is configured](#how-continuous-integration-ci-is-configured)
- [How OSS-Fuzz is configured](#how-oss-fuzz-is-configured)
- [Packaging releases](#packaging-releases)
- [Other utilities](#other-utilities)
- [Bumping Java dependencies](#bumping-java-dependencies)
- [Rake tasks](#rake-tasks)
- [Making a release](#making-a-release)

<!-- tocstop -->

## Introduction

Hello there! I'm super excited that you're interested in contributing to Nokogiri. Welcome!

This document is intended only to provide a brief introduction on how to contribute to Nokogiri. It's not a complete specification of everything you need to know, so if you want to know more, I encourage you to reach out to the maintainers via email, twitter, or a new Github issue. We'd love to get to know you a bit better!


## Code of Conduct

Our full Code of Conduct is in [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).

For best results, be kind. Remember that Nokogiri maintainers are volunteers, and treat them with respect. Do not act entitled to service. Do not be rude. Do not use judgmental or foul language.


## Some guiding principles of the project

The top guiding principles, as noted in the README are:

- be secure-by-default by treating all documents as **untrusted** by default
- be a **thin-as-reasonable layer** on top of the underlying parsers, and don't attempt to fix behavioral differences between the parsers


Nokogiri supports both CRuby and JRuby, and has native code specific to each (though much Ruby code is shared between them). Some related secondary principles are:

- Whenever possible, implement the same functionality for both CRuby and JRuby.
- Whenever possible, implement shared behavior as shared Ruby code (i.e., write as little native code as reasonable).
- Whenever possible, avoid writing tests that are platform-specific (but if you do, use `skip` to provide an explanation).

Notably, despite all parsers being standards-compliant, there are behavioral inconsistencies between the parsers used in the CRuby and JRuby implementations, and Nokogiri does not and should not attempt to remove these inconsistencies. Instead, we surface these differences in the test suite when they are important/semantic; or we intentionally write tests to depend only on the important/semantic bits (omitting whitespace from regex matchers on results, for example).

Nokogiri is widely used in the Ruby ecosystem, and so extra care should be taken to avoid introducing breaking changes. Please read our [Semantic Versioning Policy](https://nokogiri.org/index.html#semantic-versioning-policy) to understand what we consider to be a breaking change.


## Where to start getting involved

Please take a look at our [Issues marked "Help Wanted"](https://github.com/sparklemotion/nokogiri/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22).

Also, [pull requests for documentation improvements are always welcome](#documentation)!


## Submitting Pull Requests

Pull requests should be made with `main` as the merge base. See the next section for details.

**Pull requests that introduce behavior change must always contain a test** demonstrating the behavior being introduced, fixed, or changed. These tests should ideally communicate to the maintainers the problem being solved. We will ask you for clarification if we don't understand the problem you're trying to solve.

If the pull request contains a feature or a bugfix, please make sure to create a CHANGELOG entry in the "unreleased" section.

Please do not submit pull requests that make purely cosmetic changes to the code (style, naming, etc.). While we recognize that the code can always be improved, we prefer that you focus on more impactful contributions.

Feel free to push a "work in progress" to take advantage of the feedback loops from CI. But then please indicate that it's still in progress by marking it as a [Draft Pull Request](https://docs.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-requests#draft-pull-requests).


## Branch Management and Release Management

Nokogiri follows SemVer, and some nuances of that policy are spelled out in [Semantic Versioning Policy](https://nokogiri.org/index.html#semantic-versioning-policy).

Development should be happening on `main`, which sets `Nokogiri::VERSION` to a development version of the next minor release (e.g., `"1.14.0.dev"`). All pull requests should have `main` as the merge base.

Patch releases should be made by cherry-picking commits from `main` onto the release branch (e.g., `v1.13.x`) in a pull request labeled `backport`.


## How to set up your local development environment

### Basic

``` sh
git clone --recurse-submodules https://github.com/sparklemotion/nokogiri
cd nokogiri
bundle install
```


### Advanced

Please install the latest or previous version of CRuby (e.g., 3.2 or 3.1 as of 2023-01), and a recent version of JRuby. We recommend using `rbenv`, which is used in test scripts when necessary to test gems against multiple rubies.

Please install a system version of libxml2/libxslt (see [Installing Nokogiri](https://nokogiri.org/tutorials/installing_nokogiri.html#installing-using-standard-system-libraries) for details) so that you can test against both the packaged libraries and your system libraries.

We recommend that you install `valgrind` if you can, but it's only necessary for debugging problems so feel free to wait until you need it. (I'm not sure valgrind is easily available on MacOS.)

If you plan to package precompiled native gems, make sure `docker` is installed and is working properly.


## How to run the tests

Note that `rake test` does not compile the native extension, and this is intentional (so we can run the test suite against an installed gem). If you're modifying the extension code, please make sure you re-compile each time you run the tests to ensure you're testing your changes.


### The short version

``` sh
bundle exec rake compile test
```

To run a focused test, use Minitest's `TESTOPTS`:

``` sh
bundle exec rake compile test TESTOPTS="-n/test_last_element_child/"
```

Or to run tests on specific files, use `TESTGLOB`:

``` sh
bundle exec rake compile test TESTGLOB="test/**/test_*node*rb"
```


To run the test suite in parallel, set the `NCPU` environment variable; and to compile in parallel, set the `MAKEFLAGS` environment variable (you may want to set these in something like your .bashrc):

``` sh
export NCPU=8
export MAKEFLAGS=-j8
bundle exec rake compile test
```


### CRuby advanced usage

Test using your system's libraries:

``` sh
bundle exec rake clean  #  blow away pre-existing libraries using packaged libs
bundle exec rake compile test -- --enable-system-libraries
```

Run performance tests:

``` sh
bundle exec rake compile test:bench
```


Run tests using valgrind:

``` sh
bundle exec rake compile test:valgrind
```


Run tests in the debugger:

``` sh
bundle exec rake compile test:gdb
# or
bundle exec rake compile test:lldb
```


Run tests and look for memory leaks with valgrind and ruby_memcheck:

``` sh
bundle exec rake compile test:memcheck
```


Run test/test_memory_usage.rb and look for memory leaks using RSS size and linear interpolation:

``` sh
bundle exec rake compile test:memory_suite
```


Note that by you can run the test suite with a variety of GC behaviors. For example, running a major after each test completes has, on occasion, been useful for localizing some classes of memory bugs, but does slow the suite down. Some variations of the test suite behavior are available (see `test/helper.rb` for more info):

``` sh
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

If you want to build Nokogiri against a modified version of libxml2 or libxslt, clone them both into sibling directories (`../libxml2` and `../libxslt`) then run `scripts/compile-against-libxml2-source`.

That script also takes an optional command to run with the proper environment variables set to use the local libxml2 library, which can be useful when trying to `git bisect` against libxml2 or libxslt. So, for example:

``` sh
scripts/compile-against-libxml2-source bundle exec rake test
```

An alternative, if you're not bisecting or hacking on libxml2 or libxslt, is:

``` sh
bundle exec rake compile -- \
  --with-xslt-source-dir=$(pwd)/../libxslt \
  --with-xml2-source-dir=$(pwd)/../libxml2
```


### gumbo HTML5 parser

To run the test suite for the gumbo parser:

``` sh
bundle exec rake gumbo
```

Please note that additional html5lib tests for Nokogiri's HTML5 parser exist in a submodule. If you haven't checked that submodule out, here's how to do so:

``` sh
git submodule update --init  #  test/html5lib-tests
bundle exec rake compile test
```

If you're actively working on the libgumbo source, you will probably want a faster feedback loop than `rake clean compile test` will give you. Here's how to get more immediate builds of libgumbo whenever you change a file:

``` sh
bundle exec rake clean compile -- --gumbo-dev
# change a gumbo file
bundle exec rake compile # immediate compilation of changed file and relinking of nokogiri.so
```


### Fuzzing your gumbo HTML5 parser changes

When making changes or adding new features to `gumbo-parser`, it's recommended to run [libfuzzer](https://llvm.org/docs/LibFuzzer.html) against `gumbo-parser` using various [sanitizers](https://github.com/google/sanitizers/wiki).

Build the fuzzers by navigating to the `gumbo-parser` directory and running `make fuzzers`. Once built, navigate to the `gumbo-parser/fuzzer/build` directory and execute one of the following binaries in this directory:

- parse_fuzzer (standard fuzzer with no sanitizer)
- parse_fuzzer-asan (fuzzer built using [ASAN](https://clang.llvm.org/docs/AddressSanitizer.html))
- parse_fuzzer-msan (fuzzer built using [MSAN](https://clang.llvm.org/docs/MemorySanitizer.html))
- parse_fuzzer-ubsan (fuzzer built using [UBSAN](https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html))

To fuzz more efficiently, use the dictionary (gumbo.dict) and corpus (gumbo_corpus) found in `gumbo-parser/fuzzer` using the following arguments (assuming parse_fuzzer is in use):

```
./parse_fuzzer -dict=../gumbo.dict ../gumbo_corpus
```

If the binary executed successfully you should now be seeing the following output filling up your terminal (see https://llvm.org/docs/LibFuzzer.html#output for more information):

```
INFO: Seed: 4156947595
INFO: Loaded 1 modules   (7149 inline 8-bit counters): 7149 0x58a462, 0x58c04f, 
INFO: Loaded 1 PC tables (7149 PCs): 7149 0x53beb0,0x557d80, 
INFO: -max_len is not provided; libFuzzer will not generate inputs larger than 4096 bytes
INFO: A corpus is not provided, starting from an empty corpus
#2	INITED cov: 2 ft: 2 corp: 1/1b exec/s: 0 rss: 24Mb
	NEW_FUNC[1/44]: 0x429840 in gumbo_parse_with_options (/home/user/nokogiri/gumbo-parser/fuzzer/build/parse_fuzzer+0x429840)
	NEW_FUNC[2/44]: 0x42c0d0 in destroy_node (/home/user/nokogiri/gumbo-parser/fuzzer/build/parse_fuzzer+0x42c0d0)
#721	NEW    cov: 180 ft: 181 corp: 2/12b lim: 11 exec/s: 0 rss: 27Mb L: 11/11 MS: 4 ChangeByte-ChangeByte-ChangeBit-InsertRepeatedBytes-
#722	NEW    cov: 186 ft: 196 corp: 3/23b lim: 11 exec/s: 0 rss: 27Mb L: 11/11 MS: 1 ChangeBit-
#723	NEW    cov: 186 ft: 228 corp: 4/34b lim: 11 exec/s: 0 rss: 27Mb L: 11/11 MS: 1 ChangeBinInt-
#724	NEW    cov: 188 ft: 241 corp: 5/45b lim: 11 exec/s: 0 rss: 27Mb L: 11/11 MS: 1 ChangeBit-
#725	NEW    cov: 188 ft: 254 corp: 6/56b lim: 11 exec/s: 0 rss: 27Mb L: 11/11 MS: 1 ChangeByte-
#726	NEW    cov: 188 ft: 270 corp: 7/67b lim: 11 exec/s: 0 rss: 27Mb L: 11/11 MS: 1 CopyPart-
#732	NEW    cov: 188 ft: 279 corp: 8/78b lim: 11 exec/s: 0 rss: 27Mb L: 11/11 MS: 1 ChangeBit-
	NEW_FUNC[1/1]: 0x441de0 in gumbo_token_destroy (/home/user/nokogiri/gumbo-parser/fuzzer/build/parse_fuzzer+0x441de0)
```

However, if the fuzzer finds a "crash" (indicating that a bug has been found) it will stop fuzzing and the following output would be expected:

```
INFO: Seed: 1523017872
INFO: Loaded 1 modules (16 guards): 0x744e60, 0x744ea0,
INFO: -max_len is not provided, using 64
INFO: A corpus is not provided, starting from an empty corpus
#0    READ units: 1
#1    INITED cov: 3 ft: 2 corp: 1/1b exec/s: 0 rss: 24Mb
#3811 NEW    cov: 4 ft: 3 corp: 2/2b exec/s: 0 rss: 25Mb L: 1 MS: 5 ChangeBit-ChangeByte-ChangeBit-ShuffleBytes-ChangeByte-
#3827 NEW    cov: 5 ft: 4 corp: 3/4b exec/s: 0 rss: 25Mb L: 2 MS: 1 CopyPart-
#3963 NEW    cov: 6 ft: 5 corp: 4/6b exec/s: 0 rss: 25Mb L: 2 MS: 2 ShuffleBytes-ChangeBit-
#4167 NEW    cov: 7 ft: 6 corp: 5/9b exec/s: 0 rss: 25Mb L: 3 MS: 1 InsertByte-
==31511== ERROR: libFuzzer: deadly signal
...
artifact_prefix='./'; Test unit written to ./crash-b13e8756b13a00cf168300179061fb4b91fefbed
```

The above indicates that a crash has been identified and it can be reproduced by feeding the `crash-b13e8756b13a00cf168300179061fb4b91fefbed` file back into the binary used for fuzzing (e.g. parse-fuzzer) using the following command:

```
parse_fuzzer crash-b13e8756b13a00cf168300179061fb4b91fefbed
```

If you'd like to learn more about libfuzzer please give https://github.com/google/fuzzing/blob/master/tutorial/libFuzzerTutorial.md a try.


## Style Guide

### Documentation

We use `rdoc` to build Nokogiri's documentation. Run `rake rdoc` to build into the `./html` directory, and see the rdoc tasks in [rakelib/rdoc.rake](rakelib/rdoc.rake).

Previously we made some effort to move towards `yard` but that work was stopped (and the decision record can be found at [RFC: convert to use `yard` for documentation](https://github.com/sparklemotion/nokogiri/issues/1996)).

Docstrings should be in `RDoc::Markup` format, though simple docstrings may be in Markdown (using `:markup: markdown`).

If you submit pull requests that improve documentation, **I will happily merge them** and credit you in the CHANGELOG.

Some guidelines (see [lib/nokogiri/xml/node.rb](lib/nokogiri/xml/node.rb) and [ext/nokogiri/xml/node.c](ext/nokogiri/xml/node.c) for examples):

- Use `:call-seq:` to ...
  - note the return type of the method whenever possible, e.g. `:call-seq: upcase(name) → String`
  - name all the aliases of a method
  - indicate block/yield usage of a method
- Briefly explain the purpose of the method, what it returns, and what side effects it has
- Method signatures
  - Use a `[Parameters]` definition to note the expected types of all the parameters as a bulleted list
  - Use a `[Returns]` definition to note the return type
  - Use a `[Yields]` definition to note the block parameters
  - use RBS syntax whenever possible to declare variable types
- Callouts
  - Use a `🛡` character for security-related notes
  - Use a `⚠` character to warn the user about tricky usage
  - Use a `💡` character to call attention to other important notes
- Examples
  - Prefer to **show** nuanced behavior in code examples, rather than try to explain it in prose.
  - Use the line `*Example:* <Brief explanation>` to name examples and visually separate them
  - Indent two extra columns to get code-block formatting
- Metadata
  - `See also:` should be used to call out related methods
  - `Since` should be used to indicate the version in which the code was introduced


### Code

I don't feel very strongly about code style, but this project uses [Standard](https://github.com/standardrb/standard) for Ruby, and uses the `astyle` configuration laid out in `./rakelib/format.rake` for C and Java.

You can auto-format everything with `rake format`.

There are some pending Rubocop rules in `.rubocop_todo.yml`. If you'd like to fix them up, I will happily merge your pull request.

For C code, naming is currently inconsistent, but I am generally moving towards some guidelines that will make stack traces more readable and usable:

- Public functions and functions bound to Ruby methods should start with `noko_` followed by the snake case class name.
  - e.g., `noko_xml_sax_parser_context_...`
- Static functions (file scope) do not need the "noko" prefix, but should be named with the snake case class name.
  - e.g., `xml_sax_parser_context_...`
- Ruby singleton methods should have `_s_` before the method name
  - e.g., `noko_xml_sax_parser_context_s_io` for `Nokogiri::XML::SAX::ParserContext.io`
- Ruby instance methods should have `__` before the method name
  - e.g., `noko_xml_sax_parser_context__line` for `Nokogiri::XML::SAX::ParserContext#line`
- Ruby attribute getters and setters should have `_get` or `_set` as a suffix
  - e.g., `noko_xml_sax_parser_context__recovery_set` for `Nokogiri::XML::SAX::ParserContext#recovery=`


## How Continuous Integration ("CI") is configured

The bulk of CI is running in Github Actions since May 2021: https://github.com/sparklemotion/nokogiri/actions

However, we also run tests against 32-bit windows (which aren't supported by GA as of this writing) in Appveyor: https://ci.appveyor.com/project/flavorjones/nokogiri

A known hole in CI coverage is the lack native gem tests for arm64-darwin.


### Coverage

The `ci.yml` pipeline includes jobs to:

- basic security sanity check and formatting check, using Rubocop
- fast feedback for obvious failures: run against system libraries on vanilla ubuntu
- run the Gumbo parser tests on ubuntu, macos, and windows
- run on all supported versions of CRuby:
    - once with packaged libraries
    - once with system libraries
    - once on valgrind (to look for memory bugs)
- run the test suite looking for new memory leaks (using ruby_memcheck)
- run on JRuby
- run on TruffleRuby
- run on a Musl (Alpine) system:
    - against system libraries
    - with valgrind using packaged libraries
- run with libxml-ruby loaded (because this can interact with libxml2 in conflicting ways)
    - against system libraries
    - with valgrind using packaged libraries
- build a "ruby" platform gem
    - install and test on linux, macos, and windows
- build native gems
    - install and test against all supported versions of CRuby
    - install and test on a variety of linux, macos, and windows systems
- build a jruby gem, install and test it

The `upstream.yml` pipeline includes jobs to:

- run against libxml2 and libxslt head (linux), including a valgrind check
- run against CRuby head (linux, windows, macos) including a valgrind check
- run against JRuby head
- run html5lib-tests from that project's `origin/master`

The `downstream.yml` pipeline includes jobs to run notable downstream dependents against Nokogiri `main`.

The `generate-ci-images.yml` pipeline builds some containers used by the other pipelines once a week. This is primarily an optimization to make sure system packages (like `libxml2-dev` and `valgrind`) are already installed. See `oci-images/nokogiri-test/` for details on what's in these containers.


### Valgrind and `ruby_memcheck`

We rely heavily on Valgrind and [`ruby_memcheck`](https://github.com/Shopify/ruby_memcheck) to catch memory bugs by running in combination with every version of CRuby.

We use suppressions primarily to quiet known small memory leaks or quirks of certain Ruby versions. See the files in the `/suppressions` directory and `/rakelib/test.rake` for more information.


### Benchmark / Performance tests

A separate suite, `test:bench`, can be run to ensure a few performance expectations. As of 2022-02 this suite is small, but we can grow it over time. These tests are run in CI on CRuby and JRuby.

These tests should use `Nokogiri::TestBenchmark` as the base class, and be in a file matching the glob `test/**/bench_*.rb`.


### Helpful hints when writing new CI jobs

- Always checkout the source code **including submodules** (for the html5lib tests)
- When testing packaged libraries (not system libraries), cache either `ports/` (for compiled libraries) or `ports/archives/` (for just tarballs)
  - note that `libgumbo` is built outside of `ports/` to allow us to do this caching safely


## How OSS-Fuzz is configured

[OSS-Fuzz](https://oss-fuzz.com/) is a service that runs fuzzing against open-source libraries.

OSS-Fuzz was configured to fuzz Nokogiri's libgumbo in https://github.com/google/oss-fuzz/pull/11004. Updating the configuration should be done in that project.

Notifications go to `nokogiri-oss-fuzz@googlegroups.com`.

Some historical context can be found in [discussion #2992](https://github.com/sparklemotion/nokogiri/discussions/2992) and [pull request #3007](https://github.com/sparklemotion/nokogiri/pull/3007) by @fuzzy-boiii23a.


## Packaging releases

As a prerequisite please make sure you have `docker` correctly installed, to build native (precompiled) gems.

Run `scripts/build-gems` which will package gems for all supported platforms, and run some basic sanity tests on those packages using `scripts/test-gem-set`, `scripts/test-gem-file-contents`, and `scripts/test-gem-installation`.

See [Making a release](#making-a-release) below for the checklist.


## Other utilities

`scripts/test-exported-symbols` checks the compiled `nokogiri.so` library for surprising exported symbols. This script likely only works on Linux, sorry.

`scripts/files-modified-by-open-prs` is a hack to see what files are being proposed to change in the set of open pull requests. This might be useful if you're thinking about radically changing a file, to be aware of what merge conflicts might result. This could probably be a rake task.

There's a `Vagrantfile` in the project root which I've used once or twice to try to reproduce problems non-Linux systems (like OpenBSD). It's not well-maintained so YMMV.


## Bumping Java dependencies

Java dependencies, in the form of `.jar` files, are all vendored as part of the `java` platform gem.

We use [`jar-dependencies`](https://github.com/mkristian/jar-dependencies) as a development dependency to manage the project's Java dependencies. Note, however, that we use our own fork of NekoDTD that lives at https://github.com/sparklemotion/nekodtd

To modify or add a dependency, a few things needs to be in sync:

- `nokogiri.gemspec`: `spec.requirements` need to specify the maven group Id, artifact ID, and version
- `nokogiri.gemspec`: `spec.files` need to include the jar files
- git: the jar files under `lib/nokogiri/jruby/` need to be committed to git
- `lib/nokogiri/jruby/nokogiri_jars.rb`: needs to include all the jars

A quick summary of what this looks like for you, the developer:

1. edit the `requirements` in the gemspec
2. run `bundle exec rake vendor_jars` which updates everything under `lib/nokogiri/jruby`
3. run `bundle exec rake check_manifest` and if necessary update the gemspec `files`
4. make sure to check everything under `lib/nokogiri/jruby` into git, including the jar files


## Rake tasks

The `Rakefile` used to be a big fat mess. It's now decomposed into a small set of files in `/rakelib`. If you've got a new rake task you'd like to introduce, please consider whether it belongs in one of the existing concerns, or needs a new file. Please don't add it to `Rakefile` without compelling reasons.


## Making a release

A quick checklist for releasing Nokogiri:

- Prechecks
  - [ ] make sure CI is green!
  - [ ] update `CHANGELOG.md` and `lib/nokogiri/version/constant.rb`
  - [ ] commit and create a git tag
  - [ ] run `scripts/build-gems` and make sure it completes and all the tests pass
- Release
  - [ ] `git push && git push --tags`
  - [ ] `for g in gems/*.gem ; do gem push $g ; done`
  - [ ] create a release at https://github.com/sparklemotion/nokogiri/releases and provide sha2 checksums
- If the release has security fixes ...
  - [ ] publish a GHSA
  - [ ] email ruby-security-ann@googlegroups.com and ruby-talk@ruby-lang.org
- Post-release
  - [ ] update nokogiri.org
  - [ ] bump `lib/nokogiri/version/constant.rb` to a prerelease version like `v1.14.0.dev`
