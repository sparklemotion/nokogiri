# frozen_string_literal: true

require "helper"

class Nokogiri::CSS::Selectors
  describe Nokogiri::CSS::Selectors::ANPlusBParser do
    def an_plus_b(input, debug: false)
      tokens = Tokenizer.new(input).tokenize.tap { |ast| pp(ast) if debug }
      ANPlusBParser.new(tokens).parse.tap { |ast| pp(ast) if debug }
    end

    class << self
      def it_is_An_plus_B(input, debug: false)
        it("parses #{input.inspect}") do
          ast = an_plus_b(input, debug: debug)
          assert_pattern { yield ast }
        end
      end

      def it_is_not_An_plus_B(input, debug: false)
        it("does not parse #{input.inspect}") do
          assert_raises(Nokogiri::CSS::SyntaxError) do
            an_plus_b(input, debug: debug)
          end
        end
      end
    end

    # https://www.w3.org/TR/css-syntax-3/#the-anb-type
    # <an+b> =
    #   odd | even |
    #   <integer> |
    it_is_An_plus_B("even") { |ast| ast => ANPlusB(values: [IdentToken("even")], a: 2, b: 0) }
    it_is_An_plus_B(" even ") { |ast| ast => ANPlusB(values: [IdentToken("even")], a: 2, b: 0) }
    it_is_An_plus_B("odd") { |ast| ast => ANPlusB(values: [IdentToken("odd")], a: 2, b: 1) }
    it_is_An_plus_B(" odd ") { |ast| ast => ANPlusB(values: [IdentToken("odd")], a: 2, b: 1) }
    it_is_An_plus_B("42") { |ast| ast => ANPlusB(values: [NumberToken(value: 42, type: "integer")], a: 0, b: 42) }
    it_is_An_plus_B(" 42 ") { |ast| ast => ANPlusB(values: [NumberToken(value: 42, type: "integer")], a: 0, b: 42) }

    # <n-dimension> |
    # '+'?† n |
    # -n |
    #
    # <n-dimension> is a <dimension-token> with its type flag set to "integer", and a unit that is
    # an ASCII case-insensitive match for "n"
    #
    # †: When a plus sign (+) precedes an ident starting with "n", as in the cases marked above,
    # there must be no whitespace between the two tokens, or else the tokens do not match the above
    # grammar. Whitespace is valid (and ignored) between any other two tokens.
    it_is_An_plus_B("42n") do |ast|
      ast => ANPlusB(values: [DimensionToken(value: 42, unit: "n", type: "integer")], a: 42, b: 0)
    end
    it_is_An_plus_B("42N") do |ast|
      ast => ANPlusB(values: [DimensionToken(value: 42, unit: "N", type: "integer")], a: 42, b: 0)
    end
    it_is_An_plus_B("n") { |ast| ast => ANPlusB(values: [IdentToken("n")], a: 1, b: 0) }
    it_is_An_plus_B("N") { |ast| ast => ANPlusB(values: [IdentToken("N")], a: 1, b: 0) }
    it_is_An_plus_B("+n") { |ast| ast => ANPlusB(values: [DelimToken("+"), IdentToken("n")], a: 1, b: 0) }
    it_is_An_plus_B("+N") { |ast| ast => ANPlusB(values: [DelimToken("+"), IdentToken("N")], a: 1, b: 0) }
    it_is_An_plus_B("-n") { |ast| ast => ANPlusB(values: [IdentToken("-n")], a: -1, b: 0) }
    it_is_An_plus_B("-N") { |ast| ast => ANPlusB(values: [IdentToken("-N")], a: -1, b: 0) }
    it_is_not_An_plus_B("+ n")

    # <ndashdigit-dimension> |
    # '+'?† <ndashdigit-ident> |
    # <dashndashdigit-ident> |
    #
    # <ndashdigit-dimension> is a <dimension-token> with its type flag set to "integer", and a unit
    # that is an ASCII case-insensitive match for "n-*", where "*" is a series of one or more digits
    #
    # <ndashdigit-ident> is an <ident-token> whose value is an ASCII case-insensitive match for
    # "n-*", where "*" is a series of one or more digits
    #
    # <dashndashdigit-ident> is an <ident-token> whose value is an ASCII case-insensitive match for
    # "-n-*", where "*" is a series of one or more digits
    it_is_An_plus_B("42n-33") do |ast|
      ast => ANPlusB(values: [DimensionToken(value: 42, unit: "n-33", type: "integer")], a: 42, b: -33)
    end
    it_is_An_plus_B("n-33") { |ast| ast => ANPlusB(values: [IdentToken("n-33")], a: 1, b: -33) }
    it_is_An_plus_B("N-33") { |ast| ast => ANPlusB(values: [IdentToken("N-33")], a: 1, b: -33) }
    it_is_An_plus_B("+n-33") { |ast| ast => ANPlusB(values: [DelimToken("+"), IdentToken("n-33")], a: 1, b: -33) }
    it_is_An_plus_B("+N-33") { |ast| ast => ANPlusB(values: [DelimToken("+"), IdentToken("N-33")], a: 1, b: -33) }
    it_is_An_plus_B("-n-33") { |ast| ast => ANPlusB(values: [IdentToken("-n-33")], a: -1, b: -33) }
    it_is_An_plus_B("-N-33") { |ast| ast => ANPlusB(values: [IdentToken("-N-33")], a: -1, b: -33) }
    it_is_not_An_plus_B("+ n-33")

    # <n-dimension> <signed-integer> |
    # '+'?† n <signed-integer> |
    # -n <signed-integer> |
    #
    # <signed-integer> is a <number-token> with its type flag set to "integer", and whose
    # representation starts with "+" or "-"
    it_is_An_plus_B("42n +33") do |ast|
      ast => ANPlusB(values: [
                       DimensionToken(value: 42, unit: "n", type: "integer"),
                       NumberToken(value: 33, type: "integer")
                     ],
                     a: 42, b: 33)
    end
    it_is_An_plus_B("42N +33") do |ast|
      ast => ANPlusB(values: [
                       DimensionToken(value: 42, unit: "N", type: "integer"),
                       NumberToken(value: 33, type: "integer")
                     ],
                     a: 42, b: 33)
    end
    it_is_An_plus_B("42n -33") do |ast|
      ast => ANPlusB(values: [
                       DimensionToken(value: 42, unit: "n", type: "integer"),
                       NumberToken(value: -33, type: "integer")
                     ],
                     a: 42, b: -33)
    end
    it_is_An_plus_B("42N -33") do |ast|
      ast => ANPlusB(values: [
                       DimensionToken(value: 42, unit: "N", type: "integer"),
                       NumberToken(value: -33, type: "integer")
                     ],
                     a: 42, b: -33)
    end
    it_is_An_plus_B("n +33") do |ast|
      ast => ANPlusB(
        values: [IdentToken("n"), NumberToken(value: 33, type: "integer")],
        a: 1, b: 33
      )
    end
    it_is_An_plus_B("N +33") do |ast|
      ast => ANPlusB(
        values: [IdentToken("N"), NumberToken(value: 33, type: "integer")],
        a: 1, b: 33
      )
    end
    it_is_An_plus_B("n -33") do |ast|
      ast => ANPlusB(
        values: [IdentToken("n"), NumberToken(value: -33, type: "integer")],
        a: 1, b: -33
      )
    end
    it_is_An_plus_B("N -33") do |ast|
      ast => ANPlusB(
        values: [IdentToken("N"), NumberToken(value: -33, type: "integer")],
        a: 1, b: -33
      )
    end
    it_is_An_plus_B("-n +33") do |ast|
      ast => ANPlusB(
        values: [IdentToken("-n"), NumberToken(value: 33, type: "integer")],
        a: -1, b: 33
      )
    end
    it_is_An_plus_B("-N +33") do |ast|
      ast => ANPlusB(
        values: [IdentToken("-N"), NumberToken(value: 33, type: "integer")],
        a: -1, b: 33
      )
    end
    it_is_An_plus_B("-n -33") do |ast|
      ast => ANPlusB(
        values: [IdentToken("-n"), NumberToken(value: -33, type: "integer")],
        a: -1, b: -33
      )
    end
    it_is_An_plus_B("-N -33") do |ast|
      ast => ANPlusB(
        values: [IdentToken("-N"), NumberToken(value: -33, type: "integer")],
        a: -1, b: -33
      )
    end
    it_is_not_An_plus_B("42n 33")
    it_is_not_An_plus_B("42n33")
    it_is_not_An_plus_B("n 33")
    it_is_not_An_plus_B("-n 33")

    # <ndash-dimension> <signless-integer> |
    # '+'?† n- <signless-integer> |
    # -n- <signless-integer> |
    #
    # <ndash-dimension> is a <dimension-token> with its type flag set to "integer", and a unit that
    # is an ASCII case-insensitive match for "n-"
    #
    # <signless-integer> is a <number-token> with its type flag set to "integer", and whose
    # representation starts with a digit
    it_is_An_plus_B("42n- 33") do |ast|
      ast => ANPlusB(
        values: [DimensionToken(value: 42, unit: "n-", type: "integer"), NumberToken(value: 33, type: "integer")],
        a: 42, b: -33
      )
    end
    it_is_An_plus_B("42N- 33") do |ast|
      ast => ANPlusB(
        values: [DimensionToken(value: 42, unit: "N-", type: "integer"), NumberToken(value: 33, type: "integer")],
        a: 42, b: -33
      )
    end
    it_is_An_plus_B("+n- 33") do |ast|
      ast => ANPlusB(
        values: [DelimToken("+"), IdentToken("n-"), NumberToken(value: 33, type: "integer")],
        a: 1, b: -33
      )
    end
    it_is_An_plus_B("+N- 33") do |ast|
      ast => ANPlusB(
        values: [DelimToken("+"), IdentToken("N-"), NumberToken(value: 33, type: "integer")],
        a: 1, b: -33
      )
    end
    it_is_An_plus_B("n- 33") do |ast|
      ast => ANPlusB(
        values: [IdentToken("n-"), NumberToken(value: 33, type: "integer")],
        a: 1, b: -33
      )
    end
    it_is_An_plus_B("N- 33") do |ast|
      ast => ANPlusB(
        values: [IdentToken("N-"), NumberToken(value: 33, type: "integer")],
        a: 1, b: -33
      )
    end
    it_is_An_plus_B("-n- 33") do |ast|
      ast => ANPlusB(
        values: [IdentToken("-n-"), NumberToken(value: 33, type: "integer")],
        a: -1, b: -33
      )
    end
    it_is_An_plus_B("-N- 33") do |ast|
      ast => ANPlusB(
        values: [IdentToken("-N-"), NumberToken(value: 33, type: "integer")],
        a: -1, b: -33
      )
    end
    it_is_not_An_plus_B("42n- +33")
    it_is_not_An_plus_B("42n- -33")
    it_is_not_An_plus_B("+n- +33")
    it_is_not_An_plus_B("+n- -33")
    it_is_not_An_plus_B("n- +33")
    it_is_not_An_plus_B("n- -33")
    it_is_not_An_plus_B("-n- +33")
    it_is_not_An_plus_B("-n- -33")

    # <n-dimension> ['+' | '-'] <signless-integer>
    # '+'?† n ['+' | '-'] <signless-integer> |
    # -n ['+' | '-'] <signless-integer>
    it_is_An_plus_B("42n + 33") do |ast|
      ast => ANPlusB(
        values: [
          DimensionToken(value: 42, unit: "n", type: "integer"),
          DelimToken("+"),
          NumberToken(value: 33, type: "integer")
        ],
        a: 42, b: 33
      )
    end
    it_is_An_plus_B("42n - 33") do |ast|
      ast => ANPlusB(
        values: [
          DimensionToken(value: 42, unit: "n", type: "integer"),
          DelimToken("-"),
          NumberToken(value: 33, type: "integer")
        ],
        a: 42, b: -33
      )
    end
    it_is_An_plus_B("n + 33") do |ast|
      ast => ANPlusB(
        values: [IdentToken("n"), DelimToken("+"), NumberToken(value: 33, type: "integer")],
        a: 1, b: 33
      )
    end
    it_is_An_plus_B("n - 33") do |ast|
      ast => ANPlusB(
        values: [IdentToken("n"), DelimToken("-"), NumberToken(value: 33, type: "integer")],
        a: 1, b: -33
      )
    end
    it_is_An_plus_B("+n + 33") do |ast|
      ast => ANPlusB(
        values: [DelimToken("+"), IdentToken("n"), DelimToken("+"), NumberToken(value: 33, type: "integer")],
        a: 1, b: 33
      )
    end
    it_is_An_plus_B("+n - 33") do |ast|
      ast => ANPlusB(
        values: [DelimToken("+"), IdentToken("n"), DelimToken("-"), NumberToken(value: 33, type: "integer")],
        a: 1, b: -33
      )
    end
    it_is_An_plus_B("-n + 33") do |ast|
      ast => ANPlusB(
        values: [IdentToken("-n"), DelimToken("+"), NumberToken(value: 33, type: "integer")],
        a: -1, b: 33
      )
    end
    it_is_An_plus_B("-n - 33") do |ast|
      ast => ANPlusB(
        values: [IdentToken("-n"), DelimToken("-"), NumberToken(value: 33, type: "integer")],
        a: -1, b: -33
      )
    end
    it_is_not_An_plus_B("42n + +33")
    it_is_not_An_plus_B("42n + -33")
    it_is_not_An_plus_B("42n- + 33")

    # parser behavior
    it_is_not_An_plus_B("42n+33 foo")

    # An+B examples from https://www.w3.org/TR/css-syntax-3/#the-anb-type
    it_is_An_plus_B("2n+0") { |ast| ast => ANPlusB(a: 2, b: 0) }
    it_is_An_plus_B("even") { |ast| ast => ANPlusB(a: 2, b: 0) }
    it_is_An_plus_B("4n+1") { |ast| ast => ANPlusB(a: 4, b: 1) }
    it_is_An_plus_B("-1n+6") { |ast| ast => ANPlusB(a: -1, b: 6) }
    it_is_An_plus_B("-4n+10") { |ast| ast => ANPlusB(a: -4, b: 10) }
    it_is_An_plus_B("0n+5") { |ast| ast => ANPlusB(a: 0, b: 5) }
    it_is_An_plus_B("5") { |ast| ast => ANPlusB(a: 0, b: 5) }
    it_is_An_plus_B("1n+0") { |ast| ast => ANPlusB(a: 1, b: 0) }
    it_is_An_plus_B("n+0") { |ast| ast => ANPlusB(a: 1, b: 0) }
    it_is_An_plus_B("n") { |ast| ast => ANPlusB(a: 1, b: 0) }
    it_is_An_plus_B("2n") { |ast| ast => ANPlusB(a: 2, b: 0) }
    it_is_An_plus_B("3n-6") { |ast| ast => ANPlusB(a: 3, b: -6) }
    it_is_not_An_plus_B("3n + -6")
    it_is_An_plus_B("3n + 1") { |ast| ast => ANPlusB(a: 3, b: 1) }
    it_is_An_plus_B("+3n - 2") { |ast| ast => ANPlusB(a: 3, b: -2) }
    it_is_An_plus_B("-n+ 6") { |ast| ast => ANPlusB(a: -1, b: 6) }
    it_is_An_plus_B("+6") { |ast| ast => ANPlusB(a: 0, b: 6) }
    it_is_not_An_plus_B("3 n")
    it_is_not_An_plus_B("+ 2n")
    it_is_not_An_plus_B("+ 2")
  end
end
