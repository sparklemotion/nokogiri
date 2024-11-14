# coding: utf-8
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

require_relative "../html4/document_fragment"

module Nokogiri
  module HTML5
    # Since v1.12.0
    #
    # 💡 HTML5 functionality is not available when running JRuby.
    class DocumentFragment < Nokogiri::HTML4::DocumentFragment
      class << self
        # :call-seq:
        #   parse(tags, **options)
        #   parse(tags, encoding = nil, **options)
        #
        # Parse an HTML5 document fragment from +tags+, returning a Nodeset.
        #
        # [Parameters]
        # - +tags+ [String, IO] The HTML5 document fragment to parse.
        # - +encoding+ [String] The name of the encoding to use when parsing the document fragment. (default +nil+)
        #
        # Also see Nokogiri::HTML5 for a longer explanation of how encoding is handled by the parser.
        #
        # [Options]
        # - +:context+ [String, Nokogiri::XML::Node] The context in which to parse the document fragment. (default +"body"+)
        # - +:max_errors+ [Integer] The maximum number of parse errors to record. (default +Nokogiri::Gumbo::DEFAULT_MAX_ERRORS+ which is currently 0)
        # - +:max_tree_depth+ [Integer] The maximum depth of the parse tree. (default +Nokogiri::Gumbo::DEFAULT_MAX_TREE_DEPTH+)
        # - +:max_attributes+ [Integer] The maximum number of attributes allowed on an element. (default +Nokogiri::Gumbo::DEFAULT_MAX_ATTRIBUTES+)
        # - +:parse_noscript_content_as_text+ [Boolean] Whether to parse the content of +noscript+ elements as text. (default +false+)
        #
        # Also see Nokogiri::HTML5 for a longer explanation of the options.
        #
        # [Returns]
        # - [Nokogiri::XML::NodeSet] A node set containing the root nodes of the parsed fragment.
        #
        def parse(tags, encoding_ = nil, positional_options_hash = nil, encoding: encoding_, **options)
          unless positional_options_hash.nil?
            warn("Nokogiri::HTML5::DocumentFragment.parse: Passing options as an explicit hash is deprecated. Use keyword arguments instead. This will become an error in a future release.", uplevel: 1, category: :deprecated)
            options.merge!(positional_options_hash)
          end

          context = options.delete(:context)

          document = HTML5::Document.new
          document.encoding = "UTF-8"
          tags = HTML5.read_and_encode(tags, encoding)

          new(document, tags, context, **options)
        end
      end

      attr_accessor :document
      attr_accessor :errors

      # Get the parser's quirks mode value. See HTML5::QuirksMode.
      #
      # This method returns `nil` if the parser was not invoked (e.g., `Nokogiri::HTML5::DocumentFragment.new(doc)`).
      #
      # Since v1.14.0
      attr_reader :quirks_mode

      # Create a document fragment.
      def initialize(doc, tags_ = nil, context_ = nil, positional_options_hash = nil, tags: tags_, context: context_, **options) # rubocop:disable Lint/MissingSuper
        unless positional_options_hash.nil?
          warn("Nokogiri::HTML5::DocumentFragment.new: Passing options as an explicit hash is deprecated. Use keyword arguments instead. This will become an error in a future release.", uplevel: 1, category: :deprecated)
          options.merge!(positional_options_hash)
        end

        @document = doc
        @errors = []
        return self unless tags

        # TODO: Accept encoding as an argument to this method
        tags = Nokogiri::HTML5.read_and_encode(tags, nil)

        context = options.delete(:context) if options.key?(:context)

        options[:max_attributes] ||= Nokogiri::Gumbo::DEFAULT_MAX_ATTRIBUTES
        options[:max_errors] ||= options.delete(:max_parse_errors) || Nokogiri::Gumbo::DEFAULT_MAX_ERRORS
        options[:max_tree_depth] ||= Nokogiri::Gumbo::DEFAULT_MAX_TREE_DEPTH

        Nokogiri::Gumbo.fragment(self, tags, context, **options)
      end

      def serialize(options = {}, &block) # :nodoc:
        # Bypass XML::Document.serialize which doesn't support options even
        # though XML::Node.serialize does!
        XML::Node.instance_method(:serialize).bind_call(self, options, &block)
      end

      def extract_params(params) # :nodoc:
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
            ns = {}
            children.each { |child| ns.merge!(child.namespaces) }
            ns
          end

        [params, handler, ns, binds]
      end
    end
  end
end
# vim: set shiftwidth=2 softtabstop=2 tabstop=8 expandtab:
