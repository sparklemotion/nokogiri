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

module Nokogiri
  module HTML5
    class Document < Nokogiri::HTML::Document
      def self.parse(string_or_io, url = nil, encoding = nil, **options, &block)
        yield options if block_given?
	string_or_io = '' unless string_or_io

        if string_or_io.respond_to?(:encoding) && string_or_io.encoding.name != 'ASCII-8BIT'
          encoding ||= string_or_io.encoding.name
        end

        if string_or_io.respond_to?(:read) && string_or_io.respond_to?(:path)
          url ||= string_or_io.path
        end
        unless string_or_io.respond_to?(:read) || string_or_io.respond_to?(:to_str)
          raise ArgumentError.new("not a string or IO object")
        end
        do_parse(string_or_io, url, encoding, options)
      end

      def self.read_io(io, url = nil, encoding = nil, **options)
        raise ArgumentError.new("io object doesn't respond to :read") unless io.respond_to?(:read)
        do_parse(io, url, encoding, options)
      end

      def self.read_memory(string, url = nil, encoding = nil, **options)
        raise ArgumentError.new("string object doesn't respond to :to_str") unless string.respond_to?(:to_str)
        do_parse(string, url, encoding, options)
      end

      def fragment(tags = nil)
        DocumentFragment.new(self, tags, self.root)
      end

      def to_xml(options = {}, &block)
        # Bypass XML::Document#to_xml which doesn't add
        # XML::Node::SaveOptions::AS_XML like XML::Node#to_xml does.
        XML::Node.instance_method(:to_xml).bind(self).call(options, &block)
      end

      private
      def self.do_parse(string_or_io, url, encoding, options)
        string = HTML5.read_and_encode(string_or_io, encoding)
        max_attributes = options[:max_attributes] || Nokogiri::Gumbo::DEFAULT_MAX_ATTRIBUTES
        max_errors = options[:max_errors] || options[:max_parse_errors] || Nokogiri::Gumbo::DEFAULT_MAX_ERRORS
        max_depth = options[:max_tree_depth] || Nokogiri::Gumbo::DEFAULT_MAX_TREE_DEPTH
        doc = Nokogiri::Gumbo.parse(string, url, max_attributes, max_errors, max_depth)
        doc.encoding = 'UTF-8'
        doc
      end
    end
  end
end
