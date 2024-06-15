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

        # ----------
        # Tokens
        # ----------
        def visit_at_keyword_token(node)
          value("at-keyword-token", node)
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
          value("delim-token", node)
        end

        def visit_dimension_token(node)
          token("dimension-token") do
            q.breakable
            q.pp(node.type)

            q.breakable
            q.pp(node.value)

            q.breakable
            q.pp(node.unit)
          end
        end

        def visit_eof_token(node)
          token("eof-token")
        end

        def visit_function_token(node)
          value("function-token", node)
        end

        def visit_hash_token(node)
          token("hash-token") do
            q.breakable
            q.pp(node.value)

            q.breakable
            q.pp(node.type)
          end
        end

        def visit_ident_token(node)
          value("ident-token", node)
        end

        def visit_number_token(node)
          token("number-token") do
            q.breakable
            q.pp(node.type)

            q.breakable
            q.pp(node.value)

            q.breakable
            q.pp(node.text)
          end
        end

        def visit_open_square_token(node)
          token("open-square-token")
        end

        def visit_string_token(node)
          value("string-token", node)
        end

        def visit_whitespace_token(node)
          value("whitespace-token", node)
        end

        # ----------
        # Selectors
        # ----------

        def visit_attr_matcher(node)
          value(node.class::PP_NAME, node)
        end

        def visit_attr_matcher_equal(node)
          visit_attr_matcher(node)
        end

        def visit_attr_matcher_include_word(node)
          visit_attr_matcher(node)
        end

        def visit_attr_matcher_dash_match(node)
          visit_attr_matcher(node)
        end

        def visit_attr_matcher_start_with(node)
          visit_attr_matcher(node)
        end

        def visit_attr_matcher_end_with(node)
          visit_attr_matcher(node)
        end

        def visit_attr_matcher_include(node)
          visit_attr_matcher(node)
        end

        def visit_attribute_selector(node)
          all_keys("attribute-selector", node)
        end

        def visit_attribute_selector_matcher(node)
          all_keys("attribute-selector-matcher", node)
        end

        def visit_class_selector(node)
          value("class-selector", node)
        end

        def visit_combinator(node)
          value(node.class::PP_NAME, node)
        end

        def visit_combinator_child(node)
          visit_combinator(node)
        end

        def visit_combinator_descendant(node)
          visit_combinator(node)
        end

        def visit_combinator_next_sibling(node)
          visit_combinator(node)
        end

        def visit_combinator_subsequent_sibling(node)
          visit_combinator(node)
        end

        def visit_combinator_column_sibling(node)
          visit_combinator(node)
        end

        def visit_complex_selector(node)
          token("complex-selector") do
            q.breakable
            q.pp(node.left)

            q.breakable
            q.pp(node.combinator)

            q.breakable
            q.pp(node.right)
          end
        end

        def visit_compound_selector(node)
          all_keys("compound-selector", node)
        end

        def visit_function(node)
          token("function") do
            q.breakable
            token("name") do
              q.breakable
              q.pp(node.name)
            end

            if node.value && !node.value.empty?
              q.breakable
              token("value") do
                q.breakable
                q.seplist(node.value) { |v| q.pp(v) }
              end
            end
          end
        end

        def visit_id_selector(node)
          value("id-selector", node)
        end

        def visit_ns_prefix(node)
          value("ns-prefix", node)
        end

        def visit_pseudo_class_selector(node)
          value("pseudo-class-selector", node)
        end

        def visit_pseudo_class_function(node)
          all_keys("pseudo-class-function", node)
        end

        def visit_type_selector(node)
          all_keys("type-selector", node)
        end

        def visit_wq_name(node)
          all_keys("wq-name", node)
        end

        private

        def value(name, node)
          token(name) do
            q.breakable
            q.pp(node.value)
          end
        end

        def all_keys(name, node)
          token(name) do
            node.deconstruct_keys(nil).each do |key, value|
              next if value.nil?
              next if Array === value && value.empty?

              q.breakable
              token(key.to_s) do
                q.breakable
                if Array === value
                  q.seplist(value) { |v| q.pp(v) }
                else
                  q.pp(value)
                end
              end
            end
          end
        end

        def token(name, &block)
          q.group do
            q.text("(")
            q.text(name)

            if block
              q.nest(2, &block)
            end

            q.text(")")
          end
        end
      end
    end
  end
end
