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
    it_is_An_plus_B("even") { |ast| ast => ANPlusB[IdentToken("even")] }
    it_is_An_plus_B(" even ") { |ast| ast => ANPlusB[IdentToken("even")] }
    it_is_An_plus_B("odd") { |ast| ast => ANPlusB[IdentToken("odd")] }
    it_is_An_plus_B(" odd ") { |ast| ast => ANPlusB[IdentToken("odd")] }
    it_is_An_plus_B("42") { |ast| ast => ANPlusB[NumberToken(value: 42, type: "integer")] }
    it_is_An_plus_B(" 42 ") { |ast| ast => ANPlusB[NumberToken(value: 42, type: "integer")] }

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
    it_is_An_plus_B("42n") { |ast| ast => ANPlusB[DimensionToken(value: 42, unit: "n", type: "integer")] }
    it_is_An_plus_B("42N") { |ast| ast => ANPlusB[DimensionToken(value: 42, unit: "N", type: "integer")] }
    it_is_An_plus_B("n") { |ast| ast => ANPlusB[IdentToken("n")] }
    it_is_An_plus_B("+n") { |ast| ast => ANPlusB[DelimToken("+"), IdentToken("n")] }
    it_is_An_plus_B("-n") { |ast| ast => ANPlusB[IdentToken("-n")] }
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
    it_is_An_plus_B("42n-33") { |ast| ast => ANPlusB[DimensionToken(value: 42, unit: "n-33", type: "integer")] }
    it_is_An_plus_B("n-33") { |ast| ast => ANPlusB[IdentToken("n-33")] }
    it_is_An_plus_B("+n-33") { |ast| ast => ANPlusB[DelimToken("+"), IdentToken("n-33")] }
    it_is_not_An_plus_B("+ n-33")
    it_is_An_plus_B("-n-33") { |ast| ast => ANPlusB[IdentToken("-n-33")] }

    # <n-dimension> <signed-integer> |
    # '+'?† n <signed-integer> |
    # -n <signed-integer> |
    #
    # <signed-integer> is a <number-token> with its type flag set to "integer", and whose
    # representation starts with "+" or "-"
    it_is_An_plus_B("42n +33") do |ast|
      ast => ANPlusB[
        DimensionToken(value: 42, unit: "n", type: "integer"),
        NumberToken(value: 33, type: "integer")
      ]
    end
    it_is_An_plus_B("42n -33") do |ast|
      ast => ANPlusB[
        DimensionToken(value: 42, unit: "n", type: "integer"),
        NumberToken(value: -33, type: "integer")
      ]
    end
    it_is_not_An_plus_B("42n 33")
    it_is_not_An_plus_B("42n33")
    it_is_An_plus_B("n +33") do |ast|
      ast => ANPlusB[IdentToken("n"), NumberToken(value: 33, type: "integer")]
    end
    it_is_An_plus_B("n -33") do |ast|
      ast => ANPlusB[IdentToken("n"), NumberToken(value: -33, type: "integer")]
    end
    it_is_not_An_plus_B("n 33")
    it_is_An_plus_B("-n +33") do |ast|
      ast => ANPlusB[IdentToken("-n"), NumberToken(value: 33, type: "integer")]
    end
    it_is_An_plus_B("-n -33") do |ast|
      ast => ANPlusB[IdentToken("-n"), NumberToken(value: -33, type: "integer")]
    end
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
      ast => ANPlusB[
        DimensionToken(value: 42, unit: "n-", type: "integer"), NumberToken(value: 33, type: "integer")
      ]
    end
    it_is_An_plus_B("+n- 33") do |ast|
      ast => ANPlusB[
        DelimToken("+"), IdentToken("n-"), NumberToken(value: 33, type: "integer")
      ]
    end
    it_is_An_plus_B("n- 33") do |ast|
      ast => ANPlusB[
        IdentToken("n-"), NumberToken(value: 33, type: "integer")
      ]
    end
    it_is_An_plus_B("-n- 33") do |ast|
      ast => ANPlusB[
        IdentToken("-n-"), NumberToken(value: 33, type: "integer")
      ]
    end
    it_is_not_An_plus_B("42n- +33")
    it_is_not_An_plus_B("42n- -33")
    it_is_not_An_plus_B("+n- +33")
    it_is_not_An_plus_B("+n- -33")
    it_is_not_An_plus_B("n- +33")
    it_is_not_An_plus_B("n- -33")
    it_is_not_An_plus_B("-n- +33")
    it_is_not_An_plus_B("-n- -33")
  end
end
