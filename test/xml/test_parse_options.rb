# frozen_string_literal: true

require "helper"

module Nokogiri
  module XML
    class TestParseOptions < Nokogiri::TestCase
      def test_new
        options = Nokogiri::XML::ParseOptions.new
        assert_equal(0, options.options)
      end

      def test_to_i
        options = Nokogiri::XML::ParseOptions.new
        assert_equal(0, options.to_i)
      end

      ParseOptions.constants.each do |constant|
        next if constant == "STRICT"

        class_eval <<~RUBY, __FILE__, __LINE__ + 1
          def test_predicate_#{constant.downcase}
            options = ParseOptions.new(ParseOptions::#{constant})
            assert options.#{constant.downcase}?

            assert ParseOptions.new.#{constant.downcase}.#{constant.downcase}?
          end
        RUBY
      end

      def test_strict_noent
        options = ParseOptions.new.recover.noent
        refute_predicate(options, :strict?)
      end

      def test_new_with_argument
        options = Nokogiri::XML::ParseOptions.new(1 << 1)
        assert_equal(1 << 1, options.options)
      end

      def test_unsetting
        options = Nokogiri::XML::ParseOptions.new(Nokogiri::XML::ParseOptions::DEFAULT_HTML)
        assert_predicate(options, :nonet?)
        assert_predicate(options, :recover?)
        options.nononet.norecover
        refute_predicate(options, :nonet?)
        refute_predicate(options, :recover?)
        options.nonet.recover
        assert_predicate(options, :nonet?)
        assert_predicate(options, :recover?)
      end

      def test_chaining
        options = Nokogiri::XML::ParseOptions.new.recover.noent
        assert_predicate(options, :recover?)
        assert_predicate(options, :noent?)
      end

      def test_inspect
        options = Nokogiri::XML::ParseOptions.new.recover.noent
        ins = options.inspect
        assert_match(/recover/, ins)
        assert_match(/noent/, ins)
      end

      def test_equality
        options = Nokogiri::XML::ParseOptions.new.recover.noent
        other = Nokogiri::XML::ParseOptions.new.recover.noent
        assert_equal(options, other)
      end
    end
  end
end
