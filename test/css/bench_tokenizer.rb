# frozen_string_literal: true

require "helper"
require "timeout"

class TestBenchCSSTokenizer < Nokogiri::TestBenchmark
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
end
