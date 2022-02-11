# frozen_string_literal: true

require "helper"

class TestBenchDocumentEncoding < Nokogiri::TestBenchmark
  describe "encoding detection" do
    bench_range { bench_exp(1, 40_000, 4) }

    bench_performance_constant("encoding detection", 0.99999) do |n|
      redos_string = "<?xml " + (" " * n)
      redos_string.encode!("ASCII-8BIT")
      Nokogiri::HTML4(redos_string)
    end
  end
end
