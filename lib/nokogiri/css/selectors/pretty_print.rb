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
      class PrettyPrint
        attr_reader :q

        def initialize(q)
          @q = q
        end

        def visit(node)
          node&.accept(self)
        end

        # def visit_all(nodes)
        #   nodes.map { |node| visit(node) }
        # end

        # def visit_child_nodes(node)
        #   visit_all(node.child_nodes)
        # end

        def visit_at_keyword_token(node)
          token("at-keyword-token") do
            q.breakable
            q.pp(node.value)
          end
        end

        def visit_close_paren_token(node)
          token("close-paren-token")
        end

        def visit_close_square_token(node)
          token("close-square-token")
        end

        def visit_colon_token(node)
          token("colon-token")
        end

        def visit_comma_token(node)
          token("comma-token")
        end

        def visit_delim_token(node)
          token("delim-token") do
            q.breakable
            q.pp(node.value)
          end
        end

        def visit_dimension_token(node)
          token("dimension-token") do
            q.breakable
            q.text(node.type)

            q.breakable
            q.pp(node.value)

            q.breakable
            q.text(node.unit)
          end
        end

        def visit_eof_token(node)
          token("eof-token")
        end

        def visit_function_token(node)
          token("function-token") do
            q.breakable
            q.pp(node.value)
          end
        end

        def visit_hash_token(node)
          token("hash-token") do
            q.breakable
            q.pp(node.value)

            q.breakable
            q.text(node.type)
          end
        end

        def visit_ident_token(node)
          token("ident-token") do
            q.breakable
            q.pp(node.value)
          end
        end

        def visit_number_token(node)
          token("number-token") do
            q.breakable
            q.text(node.type)

            q.breakable
            q.pp(node.value)
          end
        end

        def visit_open_square_token(node)
          token("open-square-token")
        end

        def visit_string_token(node)
          token("string-token") do
            q.breakable
            q.pp(node.value)
          end
        end

        def visit_whitespace_token(node)
          token("whitespace-token") do
            q.breakable
            q.pp(node.value)
          end
        end

        private

        def token(name, &block)
          q.group do
            q.text("(")
            q.text(name)

            if block
              q.nest(2, &block)
              q.breakable("")
            end

            q.text(")")
          end
        end
      end
    end
  end
end
