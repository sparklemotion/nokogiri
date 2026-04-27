# frozen_string_literal: true

require "helper"
require "timeout"

class TestBenchCSSTokenizer < Nokogiri::TestBenchmark
  # JRuby's JIT warmup makes per-call timings too noisy for an R**2 fit;
  # the ReDoS property is a regex property, not an engine one, so MRI
  # coverage is sufficient.
  before { skip("benchmarks are too noisy under JRuby JIT") if Nokogiri.jruby? }

  # GHSA-c4rq-3m3g-8wgx: ambiguous regex in the STRING rule backtracks
  # exponentially on unterminated `[foo="\a\a\a..."` input. Each sample
  # repeats the parse to average out per-call jitter.
  describe "css string tokenizer (cross-branch ambiguity)" do
    bench_range { bench_linear(10_000, 60_000, 10_000) }

    bench_performance_linear("redos in STRING rule", 0.99) do |n|
      Timeout.timeout(5) do
        payload = %([foo=") + ('\\a' * n) + "x"
        50.times do
          Nokogiri::CSS.xpath_for(payload)
        rescue Nokogiri::CSS::SyntaxError
        end
      end
    end
  end

  # The unicode escape's `[0-9A-Fa-f]{1,6}` quantifier admits 6 different
  # match lengths per escape position, which without an atomic group
  # multiplies into 6**N parses on unterminated `[foo="\aaaaaa\aaaaaa..."`.
  describe "css string tokenizer (unicode escape length ambiguity)" do
    bench_range { bench_linear(2_000, 12_000, 2_000) }

    bench_performance_linear("redos in unicode escape length", 0.99) do |n|
      Timeout.timeout(5) do
        payload = %([foo=") + ('\\aaaaaa' * n) + "x"
        150.times do
          Nokogiri::CSS.xpath_for(payload)
        rescue Nokogiri::CSS::SyntaxError
        end
      end
    end
  end

  # The function-call rule {ident}\({w} requires `(` after an identifier.
  # If the `(` is missing and the ident-shaped prefix contains many
  # `\<6-hex>` escapes, the engine backtracks through the {1,6}
  # ambiguity inside `{nmchar}*` for 6**N parses.
  describe "css ident tokenizer (function-rule failure ambiguity)" do
    bench_range { bench_linear(50_000, 300_000, 50_000) }

    bench_performance_linear("redos in function rule", 0.99) do |n|
      Timeout.timeout(5) do
        payload = ('\\aaaaaa' * n) + "X"
        1000.times do
          Nokogiri::CSS.xpath_for(payload)
        rescue Nokogiri::CSS::SyntaxError
        end
      end
    end
  end
end
