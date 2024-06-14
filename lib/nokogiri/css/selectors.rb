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

require_relative "selectors/tokenizer"
require_relative "selectors/pretty_print"

module Nokogiri
  module CSS
    # :nodoc: all
    class Selectors
      attr_reader :source

      def initialize(source)
        @source = preprocess(source)
      end

      def tokenize
        Selectors::Tokenizer.new(source).tokenize.to_a
      end

      private

      #-------------------------------------------------------------------------
      # 3. Tokenizing and Parsing CSS
      # https://www.w3.org/TR/css-syntax-3/#tokenizing-and-parsing
      #-------------------------------------------------------------------------

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
    end
  end
end
