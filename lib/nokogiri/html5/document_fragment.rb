# frozen_string_literal: true
#
#  Copyright 2013-2021 Sam Ruby, Stephen Checkoway
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

require 'nokogiri'

module Nokogiri
  module HTML5
    class DocumentFragment < Nokogiri::HTML::DocumentFragment
      attr_accessor :document
      attr_accessor :errors

      # Create a document fragment.
      def initialize(doc, tags = nil, ctx = nil, options = {})
        self.document = doc
        self.errors = []
        return self unless tags

        max_attributes = options[:max_attributes] || Nokogumbo::DEFAULT_MAX_ATTRIBUTES
        max_errors = options[:max_errors] || Nokogumbo::DEFAULT_MAX_ERRORS
        max_depth = options[:max_tree_depth] || Nokogumbo::DEFAULT_MAX_TREE_DEPTH
        tags = Nokogiri::HTML5.read_and_encode(tags, nil)
        Nokogumbo.fragment(self, tags, ctx, max_attributes, max_errors, max_depth)
      end

      def serialize(options = {}, &block)
        # Bypass XML::Document.serialize which doesn't support options even
        # though XML::Node.serialize does!
        XML::Node.instance_method(:serialize).bind(self).call(options, &block)
      end

      # Parse a document fragment from +tags+, returning a Nodeset.
      def self.parse(tags, encoding = nil, options = {})
        doc = HTML5::Document.new
        tags = HTML5.read_and_encode(tags, encoding)
        doc.encoding = 'UTF-8'
        new(doc, tags, nil, options)
      end

      def extract_params params # :nodoc:
        handler = params.find do |param|
          ![Hash, String, Symbol].include?(param.class)
        end
        params -= [handler] if handler

        hashes = []
        while Hash === params.last || params.last.nil?
          hashes << params.pop
          break if params.empty?
        end
        ns, binds = hashes.reverse

        ns ||=
          begin
            ns = Hash.new
            children.each { |child| ns.merge!(child.namespaces) }
            ns
          end

        [params, handler, ns, binds]
      end

    end
  end
end
# vim: set shiftwidth=2 softtabstop=2 tabstop=8 expandtab:
