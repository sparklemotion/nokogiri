# frozen_string_literal: true

# This file was based heavily on work done in the SyntaxTree::CSS project at
# https://github.com/ruby-syntax-tree/syntax_tree-css
#
# The MIT License (MIT)
#
# Copyright (c) 2022-2024 Kevin Newton
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module Nokogiri
  module CSS
    # :nodoc: all
    class Selectors
      # Tokenizes CSS according to https://www.w3.org/TR/css-syntax-3/#tokenization from the version
      # dated 24 December 2021
      class Tokenizer
        # This is used to communicate between the various tokenization algorithms.
        # It transports a value along with the new index.
        class State
          attr_reader :value, :index

          def initialize(value, index)
            @value = value
            @index = index
          end
        end

        # https://www.w3.org/TR/css-syntax-3/#digit
        DIGIT = "[0-9]"

        # https://www.w3.org/TR/css-syntax-3/#uppercase-letter
        UPPERCASE_LETTER = "[A-Z]"

        # https://www.w3.org/TR/css-syntax-3/#lowercase-letter
        LOWERCASE_LETTER = "[a-z]"

        # https://www.w3.org/TR/css-syntax-3/#letter
        LETTER = "[#{UPPERCASE_LETTER}#{LOWERCASE_LETTER}]"

        # https://www.w3.org/TR/css-syntax-3/#non-ascii-code-point
        NONASCII = "[\u{80}-\u{10FFFF}]"

        # https://www.w3.org/TR/css-syntax-3/#ident-start-code-point
        IDENT_START = "[#{LETTER}#{NONASCII}_]"

        # https://www.w3.org/TR/css-syntax-3/#ident-code-point
        IDENT = "[#{IDENT_START}#{DIGIT}-]"

        # https://www.w3.org/TR/css-syntax-3/#non-printable-code-point
        NON_PRINTABLE = "[\x00-\x08\x0B\x0E-\x1F\x7F]"

        # https://www.w3.org/TR/css-syntax-3/#whitespace
        WHITESPACE = "[\n\t ]"

        attr_reader :source, :errors

        def initialize(source)
          @source = preprocess(source)
          @errors = []
        end

        # Create an enumerator of tokens from the source.
        def tokenize
          tokens = Enumerator.new do |enum|
            index = 0

            while index < source.length
              state = consume_token(index)

              enum << state.value
              index = state.index
            end

            enum << EOFToken[index]
          end

          # convert FunctionTokens and arguments into Function objects
          values = []
          values << consume_component_value(tokens) until tokens.peek.is_a?(EOFToken)
          values
        end

        private

        # 3.3. Preprocessing the input stream
        # https://www.w3.org/TR/css-syntax-3/#input-preprocessing
        def preprocess(input)
          input.gsub(/\r\n?|\f/, "\n").tr("\x00", "\u{FFFD}")

          # We should also be replacing surrogate characters in the input stream
          # with the replacement character, but it's not entirely possible to do
          # that if the string is already UTF-8 encoded. Until we dive further
          # into encoding and handle fallback encodings, we'll just skip this.
          # .gsub(/[\u{D800}-\u{DFFF}]/, "\u{FFFD}")
        end

        # 4.3.1. Consume a token
        # https://www.w3.org/TR/css-syntax-3/#consume-token
        def consume_token(index)
          case source[index..]
          when %r{\A/\*}
            consume_comment(index)
          when /\A#{WHITESPACE}+/o
            State.new(WhitespaceToken.new(value: ::Regexp.last_match(0), location: index...(index + ::Regexp.last_match(0).length)), index + ::Regexp.last_match(0).length)
          when /\A["']/
            consume_string(index, ::Regexp.last_match(0))
          when /\A#/
            if ident?(source[index + 1]) || valid_escape?(source[index + 1], source[index + 2])
              state = consume_ident_sequence(index + 1)

              State.new(
                HashToken.new(
                  value: state.value,
                  type: start_ident_sequence?(index + 1) ? "id" : "unrestricted",
                  location: index...state.index,
                ),
                state.index,
              )
            else
              State.new(DelimToken.new(value: "#", location: index...(index + 1)), index + 1)
            end
          when /\A\(/
            State.new(OpenParenToken.new(location: index...(index + 1)), index + 1)
          when /\A\)/
            State.new(CloseParenToken.new(location: index...(index + 1)), index + 1)
          when /\A\+/
            if start_number?(index + 1)
              consume_numeric(index)
            else
              State.new(DelimToken.new(value: "+", location: index...(index + 1)), index + 1)
            end
          when /\A,/
            State.new(CommaToken.new(location: index...(index + 1)), index + 1)
          when /\A-/
            if start_number?(index)
              consume_numeric(index)
            elsif source[index + 1] == "-" && source[index + 2] == ">"
              State.new(CDCToken.new(location: index...(index + 3)), index + 3)
            elsif start_ident_sequence?(index)
              consume_ident_like(index)
            else
              State.new(DelimToken.new(value: "-", location: index...(index + 1)), index + 1)
            end
          when /\A\./
            if start_number?(index)
              consume_numeric(index)
            else
              State.new(DelimToken.new(value: ".", location: index...(index + 1)), index + 1)
            end
          when /\A:/
            State.new(ColonToken.new(location: index...(index + 1)), index + 1)
          when /\A;/
            State.new(SemicolonToken.new(location: index...(index + 1)), index + 1)
          when /\A</
            if source[index...(index + 4)] == "<!--"
              State.new(CDOToken.new(location: index...(index + 4)), index + 4)
            else
              State.new(DelimToken.new(value: "<", location: index...(index + 1)), index + 1)
            end
          when /\A@/
            if start_ident_sequence?(index + 1)
              state = consume_ident_sequence(index + 1)
              State.new(AtKeywordToken.new(value: state.value, location: index...state.index), state.index)
            else
              State.new(DelimToken.new(value: "@", location: index...(index + 1)), index + 1)
            end
          when /\A\[/
            State.new(OpenSquareToken.new(location: index...(index + 1)), index + 1)
          when /\A\\/
            if valid_escape?(source[index], source[index + 1])
              consume_ident_like(index)
            else
              errors << ParseError.new("invalid escape at #{index}")
              State.new(DelimToken.new(value: "\\", location: index...(index + 1)), index + 1)
            end
          when /\A\]/
            State.new(CloseSquareToken.new(location: index...(index + 1)), index + 1)
          when /\A\{/
            State.new(OpenCurlyToken.new(location: index...(index + 1)), index + 1)
          when /\A\}/
            State.new(CloseCurlyToken.new(location: index...(index + 1)), index + 1)
          when /\A#{DIGIT}/o
            consume_numeric(index)
          when /\A#{IDENT_START}/o
            consume_ident_like(index)
          when "", nil
            State.new(EOFToken[index], index)
          else
            State.new(DelimToken.new(value: source[index], location: index...(index + 1)), index + 1)
          end
        end

        # 4.3.2. Consume comments
        # https://www.w3.org/TR/css-syntax-3/#consume-comments
        def consume_comment(index)
          ending = source.index("*/", index + 2)

          if ending.nil?
            errors << ParseError.new("unterminated comment starting at #{index}")
            location = index...source.length
            State.new(CommentToken.new(value: source[location], location: location), source.length)
          else
            location = index...(ending + 2)
            State.new(CommentToken.new(value: source[location], location: location), ending + 2)
          end
        end

        # 4.3.3. Consume a numeric token
        # https://www.w3.org/TR/css-syntax-3/#consume-numeric-token
        def consume_numeric(index)
          start = index
          state = consume_number(index)

          value, type = state.value
          index = state.index

          if start_ident_sequence?(index)
            state = consume_ident_sequence(index)
            State.new(DimensionToken.new(value: value, unit: state.value, type: type, location: start...index), state.index)
          elsif source[index] == "%"
            index += 1
            State.new(PercentageToken.new(value: value, type: type, location: start...index), index)
          else
            State.new(NumberToken.new(value: value, type: type, location: start...index, text: source[start...index]), index)
          end
        end

        # 4.3.4. Consume an ident-like token
        # https://www.w3.org/TR/css-syntax-3/#consume-ident-like-token
        def consume_ident_like(index)
          start = index
          state = consume_ident_sequence(index)

          index = state.index
          string = state.value

          if (string.casecmp("url") == 0) && (source[index] == "(")
            index += 1 # (

            # While the next two input code points are whitespace, consume the
            # next input code point.
            index += 1 while whitespace?(source[index]) && whitespace?(source[index + 1])

            if /["']/.match?(source[index]) || (whitespace?(source[index]) && /["']/.match?(source[index + 1]))
              State.new(FunctionToken.new(value: string, location: start...index), index)
            else
              consume_url(start)
            end
          elsif source[index] == "("
            index += 1
            State.new(FunctionToken.new(value: string, location: start...index), index)
          elsif (string.casecmp("u") == 0) && (state = consume_urange(index - 1))
            state
          else
            State.new(IdentToken.new(value: string, location: start...index), index)
          end
        end

        # 4.3.5. Consume a string token
        # https://www.w3.org/TR/css-syntax-3/#consume-string-token
        def consume_string(index, quote)
          start = index
          index += 1
          value = +""

          while index <= source.length
            case source[index]
            when quote
              return State.new(StringToken.new(value: value, location: start...(index + 1)), index + 1)
            when nil
              errors << ParseError.new("unterminated string at #{start}")
              return State.new(StringToken.new(value: value, location: start...index), index)
            when "\n"
              errors << ParseError.new("newline in string at #{index}")
              return State.new(BadStringToken.new(value: value, location: start...index), index)
            when "\\"
              index += 1

              if index == source.length
                next
              elsif source[index] == "\n"
                value << source[index]
                index += 1
              else
                state = consume_escaped_code_point(index)
                value << state.value
                index = state.index
              end
            else
              value << source[index]
              index += 1
            end
          end
        end

        # 4.3.6. Consume a url token
        # https://www.w3.org/TR/css-syntax-3/#consume-url-token
        def consume_url(index)
          # 1.
          value = +""

          # 2.
          start = index
          index += 4 # url(
          index += 1 while whitespace?(source[index])

          # 3.
          while index <= source.length
            case source[index..]
            when /\A\)/
              return State.new(URLToken.new(value: value, location: start...(index + 1)), index + 1)
            when "", nil
              errors << ParseError.new("unterminated url at #{start}")
              return State.new(URLToken.new(value: value, location: start...index), index)
            when /\A#{WHITESPACE}+/o
              index += ::Regexp.last_match(0).length

              case source[index]
              when ")"
                return State.new(URLToken.new(value: value, location: start...(index + 1)), index + 1)
              when nil
                errors << ParseError.new("unterminated url at #{start}")
                return State.new(URLToken.new(value: value, location: start...index), index)
              else
                errors << ParseError.new("invalid url at #{start}")
                state = consume_bad_url_remnants(index)
                return State.new(BadURLToken.new(value: value + state.value, location: start...state.index), state.index)
              end
            when /\A["'(]|#{NON_PRINTABLE}/o
              errors << ParseError.new("invalid character in url at #{index}")
              state = consume_bad_url_remnants(index)
              return State.new(BadURLToken.new(value: value + state.value, location: start...state.index), state.index)
            when /\A\\/
              if valid_escape?(source[index], source[index + 1])
                state = consume_escaped_code_point(index + 1)
                value << state.value
                index = state.index
              else
                errors << ParseError.new("invalid escape at #{index}")
                state = consume_bad_url_remnants(index)
                return State.new(BadURLToken.new(value: value + state.value, location: start...state.index), state.index)
              end
            else
              value << source[index]
              index += 1
            end
          end
        end

        # 4.3.7. Consume an escaped code point
        # https://www.w3.org/TR/css-syntax-3/#consume-escaped-code-point
        def consume_escaped_code_point(index)
          replacement = "\u{FFFD}"

          if /\A(\h{1,6})#{WHITESPACE}?/o =~ source[index..]
            ord = ::Regexp.last_match(1).to_i(16)

            if ord == 0 || (0xD800..0xDFFF).cover?(ord) || ord > 0x10FFFF
              State.new(replacement, index + ::Regexp.last_match(0).length)
            else
              State.new(ord.chr(Encoding::UTF_8), index + ::Regexp.last_match(0).length)
            end
          elsif index == source.length
            State.new(replacement, index)
          else
            State.new(source[index], index + 1)
          end
        end

        # 4.3.8. Check if two code points are a valid escape
        # https://www.w3.org/TR/css-syntax-3/#starts-with-a-valid-escape
        def valid_escape?(left, right)
          (left == "\\") && (right != "\n")
        end

        # 4.3.9. Check if three code points would start an ident sequence
        # https://www.w3.org/TR/css-syntax-3/#would-start-an-identifier
        def start_ident_sequence?(index)
          first, second, third = source[index...(index + 3)].chars

          case first
          when "-"
            (/#{IDENT_START}/o.match?(second) || (second == "-")) ||
              valid_escape?(second, third)
          when /#{IDENT_START}/o
            true
          when "\\"
            valid_escape?(first, second)
          else
            false
          end
        end

        # 4.3.10. Check if three code points would start a number
        # https://www.w3.org/TR/css-syntax-3/#starts-with-a-number
        def start_number?(index)
          first, second, third = source[index...(index + 3)].chars

          case first
          when "+", "-"
            digit?(second) || (second == "." && digit?(third))
          when "."
            digit?(second)
          when /#{DIGIT}/o
            true
          else
            false
          end
        end

        # 4.3.11. Consume an ident sequence
        # https://www.w3.org/TR/css-syntax-3/#consume-an-ident-sequence
        def consume_ident_sequence(index)
          result = +""

          while index <= source.length
            if ident?(source[index])
              result << source[index]
              index += 1
            elsif valid_escape?(source[index], source[index + 1])
              state = consume_escaped_code_point(index + 1)
              result << state.value
              index = state.index
            else
              return State.new(result, index)
            end
          end
        end

        # 4.3.12. Consume a number
        # https://www.w3.org/TR/css-syntax-3/#consume-a-number
        def consume_number(index)
          # 1.
          repr = +""
          type = "integer"

          # 2.
          if /[+-]/.match?(source[index])
            repr << source[index]
            index += 1
          end

          # 3.
          while digit?(source[index])
            repr << source[index]
            index += 1
          end

          # 4.
          if source[index] == "." && digit?(source[index + 1])
            repr += source[index..(index + 1)]
            index += 2
            type = "number"

            while digit?(source[index])
              repr << source[index]
              index += 1
            end
          end

          # 5.
          if /\A[Ee][+-]?#{DIGIT}+/o =~ source[index..]
            repr += ::Regexp.last_match(0)
            index += ::Regexp.last_match(0).length
            type = "number"
          end

          # 6., 7.
          State.new([convert_to_number(repr), type], index)
        end

        # 4.3.13. Convert a string to a number
        # https://www.w3.org/TR/css-syntax-3/#convert-a-string-to-a-number
        def convert_to_number(value)
          pattern = %r{
            \A
            (?<sign>[+-]?)
            (?<integer>#{DIGIT}*)
            (?<decimal>\.?)
            (?<fractional>#{DIGIT}*)
            (?<exponent_indicator>[Ee]?)
            (?<exponent_sign>[+-]?)
            (?<exponent>#{DIGIT}*)
            \z
          }ox

          if (match = pattern.match(value))
            s = match[:sign] == "-" ? -1 : 1
            i = match[:integer].to_i
            f = 0
            d = 0

            unless match[:fractional].empty?
              f = match[:fractional].to_i
              d = match[:fractional].length
            end

            t = match[:exponent_sign] == "-" ? -1 : 1
            e = match[:exponent].to_i

            s * (i + f * 10**-d) * 10**(t * e)
          else
            raise ParseError, "convert_to_number called with invalid value: #{value}"
          end
        end

        # 4.3.14. Consume the remnants of a bad url
        # https://www.w3.org/TR/css-syntax-3/#consume-remnants-of-bad-url
        def consume_bad_url_remnants(index)
          value = +""

          while index <= source.length
            case source[index..]
            when "", nil
              return State.new(value, index)
            when /\A\)/
              value << ")"
              return State.new(value, index + 1)
            else
              if valid_escape?(source[index], source[index + 1])
                state = consume_escaped_code_point(index)
                value << state.value
                index = state.index
              else
                value << source[index]
                index += 1
              end
            end
          end
        end

        # https://www.w3.org/TR/css-syntax-3/#digit
        def digit?(value)
          /#{DIGIT}/o.match?(value)
        end

        # https://www.w3.org/TR/css-syntax-3/#ident-code-point
        def ident?(value)
          /#{IDENT}/o.match?(value)
        end

        # https://www.w3.org/TR/css-syntax-3/#whitespace
        def whitespace?(value)
          /#{WHITESPACE}/o.match?(value)
        end

        # 5.4.7. Consume a component value
        # https://www.w3.org/TR/css-syntax-3/#consume-component-value
        def consume_component_value(tokens)
          case tokens.peek
          # # we don't need to support simple blocks for Selectors
          # # TODO: test this and see what happens
          # in OpenCurlyToken | OpenSquareToken | OpenParenToken
          #   consume_simple_block(tokens)
          in FunctionToken
            consume_function(tokens)
          else
            tokens.next
          end
        end

        # 5.4.9. Consume a function
        # https://www.w3.org/TR/css-syntax-3/#consume-function
        def consume_function(tokens)
          name_token = tokens.next
          value = []

          loop do
            case tokens.peek
            in CloseParenToken[location:]
              tokens.next
              return Function.new(name: name_token.value, value: value, location: name_token.location.to(location))
            in EOFToken[location:]
              errors << ParseError.new("Unexpected EOF while parsing function at #{name_token.location.start_char}")
              return Function.new(name: name_token.value, value: value, location: name_token.location.to(location))
            else
              value << consume_component_value(tokens)
            end
          end
        end
      end

      # This represents a location in the source file. It maps constructs like
      # tokens and parse nodes to their original location.
      class Location
        attr_reader :start_char, :end_char

        def initialize(start_char:, end_char:)
          @start_char = start_char
          @end_char = end_char
        end

        def to(other)
          Location.new(start_char: start_char, end_char: other.end_char)
        end

        def to_range
          start_char...end_char
        end

        class << self
          def from(range)
            Location.new(start_char: range.begin, end_char: range.end)
          end
        end
      end

      # A parent class for all of the various nodes in the tree. Provides common functionality
      # between them.
      class Node
        def pretty_print(q)
          PrettyPrint.new(q).visit(self)
        end
      end

      # A parsed token that is an identifier that starts with an @ sign.
      # https://www.w3.org/TR/css-syntax-3/#typedef-at-keyword-token
      class AtKeywordToken < Node
        attr_reader :value, :location

        def initialize(value:, location:) # rubocop:disable Lint/MissingSuper
          @value = value
          @location = Location.from(location)
        end

        def accept(visitor)
          visitor.visit_at_keyword_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { value: value, location: location }
        end
      end

      # A rule that starts with an at-keyword and then accepts arbitrary tokens.
      # A common example is an @media rule.
      # https://www.w3.org/TR/css-syntax-3/#at-rule
      class AtRule < Node
        attr_reader :name, :prelude, :block, :location

        def initialize(name:, prelude:, block:, location:) # rubocop:disable Lint/MissingSuper
          @name = name
          @prelude = prelude
          @block = block
          @location = location
        end

        def accept(visitor)
          visitor.visit_at_rule(self)
        end

        def child_nodes
          [*prelude, block].compact
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { name: name, prelude: prelude, block: block, location: location }
        end
      end

      # A parsed token that was a quotes string that had a syntax error. It is
      # mostly here for error recovery.
      # https://www.w3.org/TR/css-syntax-3/#typedef-bad-string-token
      class BadStringToken < Node
        attr_reader :value, :location

        def initialize(value:, location:) # rubocop:disable Lint/MissingSuper
          @value = value
          @location = Location.from(location)
        end

        def accept(visitor)
          visitor.visit_bad_string_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { value: value, location: location }
        end
      end

      # A parsed token that was a call to "url" that had a syntax error. It is
      # mostly here for error recovery.
      # https://www.w3.org/TR/css-syntax-3/#typedef-bad-url-token
      class BadURLToken < Node
        attr_reader :value, :location

        def initialize(value:, location:) # rubocop:disable Lint/MissingSuper
          @value = value
          @location = Location.from(location)
        end

        def accept(visitor)
          visitor.visit_bad_url_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { value: value, location: location }
        end
      end

      # A parsed token containing a CDC (-->).
      # https://www.w3.org/TR/css-syntax-3/#typedef-cdc-token
      class CDCToken < Node
        attr_reader :location

        def initialize(location:) # rubocop:disable Lint/MissingSuper
          @location = Location.from(location)
        end

        def accept(visitor)
          visitor.visit_cdc_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { location: location }
        end
      end

      # A parsed token containing a CDO (<!--).
      # https://www.w3.org/TR/css-syntax-3/#typedef-cdo-token
      class CDOToken < Node
        attr_reader :location

        def initialize(location:) # rubocop:disable Lint/MissingSuper
          @location = Location.from(location)
        end

        def accept(visitor)
          visitor.visit_cdo_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { location: location }
        end
      end

      # A parsed token that represents the use of a }.
      # https://www.w3.org/TR/css-syntax-3/#tokendef-close-curly
      class CloseCurlyToken < Node
        attr_reader :location

        def initialize(location:) # rubocop:disable Lint/MissingSuper
          @location = Location.from(location)
        end

        def accept(visitor)
          visitor.visit_close_curly_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { location: location }
        end

        # Here for convenience for comparing between block types.
        def value
          "}"
        end
      end

      # A parsed token that represents the use of a ).
      # https://www.w3.org/TR/css-syntax-3/#tokendef-close-paren
      class CloseParenToken < Node
        attr_reader :location

        def initialize(location:) # rubocop:disable Lint/MissingSuper
          @location = Location.from(location)
        end

        def accept(visitor)
          visitor.visit_close_paren_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { location: location }
        end

        # Here for convenience for comparing between block types.
        def value
          ")"
        end
      end

      # A parsed token that represents the use of a ].
      # https://www.w3.org/TR/css-syntax-3/#tokendef-close-square
      class CloseSquareToken < Node
        attr_reader :location

        def initialize(location:) # rubocop:disable Lint/MissingSuper
          @location = Location.from(location)
        end

        def accept(visitor)
          visitor.visit_close_square_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { location: location }
        end

        # Here for convenience for comparing between block types.
        def value
          "]"
        end
      end

      # A parsed token containing a colon.
      # https://www.w3.org/TR/css-syntax-3/#typedef-colon-token
      class ColonToken < Node
        attr_reader :location

        def initialize(location:) # rubocop:disable Lint/MissingSuper
          @location = Location.from(location)
        end

        def accept(visitor)
          visitor.visit_colon_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { location: location }
        end
      end

      # A parsed token that contains a comma.
      # https://www.w3.org/TR/css-syntax-3/#typedef-comma-token
      class CommaToken < Node
        attr_reader :location

        def initialize(location:) # rubocop:disable Lint/MissingSuper
          @location = Location.from(location)
        end

        def accept(visitor)
          visitor.visit_comma_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { location: location }
        end
      end

      # A parsed token that contains a comment. These aren't actually declared in
      # the spec because it assumes you can just drop them. We parse them into
      # tokens, however, so that we can keep track of their location.
      class CommentToken < Node
        attr_reader :value, :location

        def initialize(value:, location:) # rubocop:disable Lint/MissingSuper
          @value = value
          @location = Location.from(location)
        end

        def accept(visitor)
          visitor.visit_comment_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { value: value, location: location }
        end
      end

      # This is the top node in the tree if it has been converted into a CSS
      # stylesheet.
      class CSSStyleSheet < Node
        attr_reader :rules, :location

        def initialize(rules:, location:) # rubocop:disable Lint/MissingSuper
          @rules = rules
          @location = location
        end

        def accept(visitor)
          visitor.visit_css_stylesheet(self)
        end

        def child_nodes
          rules
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { rules: rules, location: location }
        end
      end

      # Declarations are a particular instance of associating a property or
      # descriptor name with a value.
      # https://www.w3.org/TR/css-syntax-3/#declaration
      class Declaration < Node
        attr_reader :name, :value, :location

        def initialize(name:, value:, important:, location:) # rubocop:disable Lint/MissingSuper
          @name = name
          @value = value
          @important = important
          @location = location
        end

        def accept(visitor)
          visitor.visit_declaration(self)
        end

        def child_nodes
          value
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { name: name, value: value, important: important?, location: location }
        end

        def important?
          @important
        end
      end

      # A parsed token that has a value composed of a single code point.
      # https://www.w3.org/TR/css-syntax-3/#typedef-delim-token
      class DelimToken < Node
        attr_reader :value, :location

        def initialize(value:, location:) # rubocop:disable Lint/MissingSuper
          @value = value
          @location = Location.from(location)
        end

        def accept(visitor)
          visitor.visit_delim_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { value: value, location: location }
        end
      end

      # A parsed token that contains a numeric value with a dimension.
      # https://www.w3.org/TR/css-syntax-3/#typedef-dimension-token
      class DimensionToken < Node
        attr_reader :value, :unit, :type, :location

        def initialize(value:, unit:, type:, location:) # rubocop:disable Lint/MissingSuper
          @value = value
          @unit = unit
          @type = type
          @location = Location.from(location)
        end

        def accept(visitor)
          visitor.visit_dimension_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { value: value, type: type, location: location }
        end
      end

      # A conceptual token representing the end of the list of tokens. Whenever
      # the list of tokens is empty, the next input token is always an EOFToken.
      # https://www.w3.org/TR/css-syntax-3/#typedef-eof-token
      class EOFToken < Node
        attr_reader :location

        def initialize(location:) # rubocop:disable Lint/MissingSuper
          @location = Location.from(location)
        end

        def accept(visitor)
          visitor.visit_eof_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { location: location }
        end

        class << self
          # Since we create EOFToken objects a lot with ranges that are empty, it's
          # nice to have this convenience method.
          def [](index)
            new(location: index...index)
          end
        end
      end

      # A function has a name and a value consisting of a list of component
      # values.
      # https://www.w3.org/TR/css-syntax-3/#function
      class Function < Node
        attr_reader :name, :value, :location

        def initialize(name:, value:, location:) # rubocop:disable Lint/MissingSuper
          @name = name
          @value = value
          @location = location
        end

        def accept(visitor)
          visitor.visit_function(self)
        end

        def child_nodes
          value
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { name: name, value: value, location: location }
        end
      end

      # A parsed token that contains the beginning of a call to a function, e.g.,
      # "url(".
      # https://www.w3.org/TR/css-syntax-3/#typedef-function-token
      class FunctionToken < Node
        attr_reader :value, :location

        def initialize(value:, location:) # rubocop:disable Lint/MissingSuper
          @value = value
          @location = Location.from(location)
        end

        def accept(visitor)
          visitor.visit_function_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { value: value, location: location }
        end
      end

      # A parsed token that contains an identifier that starts with a # sign.
      # https://www.w3.org/TR/css-syntax-3/#typedef-hash-token
      class HashToken < Node
        attr_reader :value, :type, :location

        def initialize(value:, type:, location:) # rubocop:disable Lint/MissingSuper
          @value = value
          @type = type
          @location = Location.from(location)
        end

        def accept(visitor)
          visitor.visit_hash_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { value: value, type: type, location: location }
        end
      end

      # A parsed token that contains an plaintext identifier.
      # https://www.w3.org/TR/css-syntax-3/#typedef-ident-token
      class IdentToken < Node
        attr_reader :value, :location

        def initialize(value:, location:) # rubocop:disable Lint/MissingSuper
          @value = value
          @location = Location.from(location)
        end

        def accept(visitor)
          visitor.visit_ident_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { value: value, location: location }
        end
      end

      # A parsed token that contains a numeric value.
      # https://www.w3.org/TR/css-syntax-3/#typedef-number-token
      class NumberToken < Node
        attr_reader :value, :type, :location, :text

        def initialize(value:, type:, location:, text:) # rubocop:disable Lint/MissingSuper
          @value = value
          @type = type
          @location = Location.from(location)
          @text = text
        end

        def accept(visitor)
          visitor.visit_number_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { value: value, type: type, location: location, text: text }
        end
      end

      # A parsed token that represents the use of a {.
      # https://www.w3.org/TR/css-syntax-3/#tokendef-open-curly
      class OpenCurlyToken < Node
        attr_reader :location

        def initialize(location:) # rubocop:disable Lint/MissingSuper
          @location = Location.from(location)
        end

        def accept(visitor)
          visitor.visit_open_curly_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { location: location }
        end

        # Here for convenience for comparing between block types.
        def value
          "{"
        end
      end

      # A parsed token that represents the use of a (.
      # https://www.w3.org/TR/css-syntax-3/#tokendef-open-paren
      class OpenParenToken < Node
        attr_reader :location

        def initialize(location:) # rubocop:disable Lint/MissingSuper
          @location = Location.from(location)
        end

        def accept(visitor)
          visitor.visit_open_paren_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { location: location }
        end

        # Here for convenience for comparing between block types.
        def value
          "("
        end
      end

      # A parsed token that represents the use of a [.
      # https://www.w3.org/TR/css-syntax-3/#tokendef-open-square
      class OpenSquareToken < Node
        attr_reader :location

        def initialize(location:) # rubocop:disable Lint/MissingSuper
          @location = Location.from(location)
        end

        def accept(visitor)
          visitor.visit_open_square_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { location: location }
        end

        # Here for convenience for comparing between block types.
        def value
          "["
        end
      end

      # A parsed token that contains a numeric value with a percentage sign.
      # https://www.w3.org/TR/css-syntax-3/#typedef-percentage-token
      class PercentageToken < Node
        attr_reader :value, :type, :location

        def initialize(value:, type:, location:) # rubocop:disable Lint/MissingSuper
          @value = value
          @type = type
          @location = Location.from(location)
        end

        def accept(visitor)
          visitor.visit_percentage_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { value: value, type: type, location: location }
        end
      end

      # Associates a prelude consisting of a list of component values with a block
      # consisting of a simple {} block.
      # https://www.w3.org/TR/css-syntax-3/#qualified-rule
      class QualifiedRule < Node
        attr_reader :prelude, :block, :location

        def initialize(prelude:, block:, location:) # rubocop:disable Lint/MissingSuper
          @prelude = prelude
          @block = block
          @location = location
        end

        def accept(visitor)
          visitor.visit_qualified_rule(self)
        end

        def child_nodes
          [*prelude, block].compact
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { prelude: prelude, block: block, location: location }
        end
      end

      # A parsed token that contains a comma.
      # https://www.w3.org/TR/css-syntax-3/#typedef-semicolon-token
      class SemicolonToken < Node
        attr_reader :location

        def initialize(location:) # rubocop:disable Lint/MissingSuper
          @location = Location.from(location)
        end

        def accept(visitor)
          visitor.visit_semicolon_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { location: location }
        end
      end

      # A simple block has an associated token (either a <[-token>, <(-token>, or
      # <{-token>) and a value consisting of a list of component values.
      # https://www.w3.org/TR/css-syntax-3/#simple-block
      class SimpleBlock < Node
        attr_reader :token, :value, :location

        def initialize(token:, value:, location:) # rubocop:disable Lint/MissingSuper
          @token = token
          @value = value
          @location = location
        end

        def accept(visitor)
          visitor.visit_simple_block(self)
        end

        def child_nodes
          value
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { token: token, value: value, location: location }
        end
      end

      # A parsed token that contains a quoted string.
      # https://www.w3.org/TR/css-syntax-3/#typedef-string-token
      class StringToken < Node
        attr_reader :value, :location

        def initialize(value:, location:) # rubocop:disable Lint/MissingSuper
          @value = value
          @location = Location.from(location)
        end

        def accept(visitor)
          visitor.visit_string_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { value: value, location: location }
        end
      end

      # A style rule is a qualified rule that associates a selector list with a
      # list of property declarations and possibly a list of nested rules.
      # https://www.w3.org/TR/css-syntax-3/#style-rule
      class StyleRule < Node
        attr_reader :selectors, :declarations, :location

        def initialize(selectors:, declarations:, location:) # rubocop:disable Lint/MissingSuper
          @selectors = selectors
          @declarations = declarations
          @location = location
        end

        def accept(visitor)
          visitor.visit_style_rule(self)
        end

        def child_nodes
          [*selectors, *declarations]
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { selectors: selectors, declarations: declarations, location: location }
        end
      end

      # This is the top node in the tree if it hasn't been converted into a CSS
      # stylesheet.
      class StyleSheet < Node
        attr_reader :rules, :location

        def initialize(rules:, location:) # rubocop:disable Lint/MissingSuper
          @rules = rules
          @location = location
        end

        def accept(visitor)
          visitor.visit_stylesheet(self)
        end

        def child_nodes
          rules
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { rules: rules, location: location }
        end
      end

      # This node represents the use of the urange micro syntax, e.g. U+1F601.
      # https://www.w3.org/TR/css-syntax-3/#typedef-urange
      class URange < Node
        attr_reader :start_value, :end_value, :location

        def initialize(start_value:, end_value:, location:) # rubocop:disable Lint/MissingSuper
          @start_value = start_value
          @end_value = end_value
          @location = location
        end

        def accept(visitor)
          visitor.visit_urange(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { start_value: start_value, end_value: end_value, location: location }
        end
      end

      # A parsed token that contains a URL. Note that this is different from a
      # function call to the "url" function only if quotes aren't used.
      # https://www.w3.org/TR/css-syntax-3/#typedef-url-token
      class URLToken < Node
        attr_reader :value, :location

        def initialize(value:, location:) # rubocop:disable Lint/MissingSuper
          @value = value
          @location = Location.from(location)
        end

        def accept(visitor)
          visitor.visit_url_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { value: value, location: location }
        end
      end

      # A parsed token that contains only whitespace.
      # https://www.w3.org/TR/css-syntax-3/#typedef-whitespace-token
      class WhitespaceToken < Node
        attr_reader :value, :location

        def initialize(value:, location:) # rubocop:disable Lint/MissingSuper
          @value = value
          @location = Location.from(location)
        end

        def accept(visitor)
          visitor.visit_whitespace_token(self)
        end

        def child_nodes
          []
        end

        alias_method :deconstruct, :child_nodes

        def deconstruct_keys(keys)
          { value: value, location: location }
        end
      end
    end
  end
end
