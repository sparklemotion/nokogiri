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

#
#  TODO: this whole file should go away. maybe make it a decorator?
#
require_relative "../xml/node"

module Nokogiri
  module HTML5
    # Since v1.12.0
    #
    # 💡 HTML5 functionality is not available when running JRuby.
    module Node
      def inner_html(options = {})
        return super(options) unless document.is_a?(HTML5::Document)

        result = options[:preserve_newline] && prepend_newline? ? +"\n" : +""
        result << children.map { |child| child.to_html(options) }.join
        result
      end

      def write_to(io, *options)
        return super(io, *options) unless document.is_a?(HTML5::Document)

        options = options.first.is_a?(Hash) ? options.shift : {}
        encoding = options[:encoding] || options[0]
        if Nokogiri.jruby?
          save_options = options[:save_with] || options[1]
          indent_times = options[:indent] || 0
        else
          save_options = options[:save_with] || options[1] || XML::Node::SaveOptions::FORMAT
          indent_times = options[:indent] || 2
        end
        indent_string = (options[:indent_text] || " ") * indent_times

        config = XML::Node::SaveOptions.new(save_options.to_i)
        yield config if block_given?

        encoding = encoding.is_a?(Encoding) ? encoding.name : encoding

        config_options = config.options
        if config_options & (XML::Node::SaveOptions::AS_XML | XML::Node::SaveOptions::AS_XHTML) != 0
          # Use Nokogiri's serializing code.
          native_write_to(io, encoding, indent_string, config_options)
        else
          # Serialize including the current node.
          html = html_standard_serialize(options[:preserve_newline] || false)
          encoding ||= document.encoding || Encoding::UTF_8
          io << html.encode(encoding, fallback: lambda { |c| "&#x#{c.ord.to_s(16)};" })
        end
      end

      def fragment(tags)
        return super(tags) unless document.is_a?(HTML5::Document)

        DocumentFragment.new(document, tags, self)
      end
    end

    # Monkey patch
    XML::Node.prepend(HTML5::Node)
  end
end

# vim: set shiftwidth=2 softtabstop=2 tabstop=8 expandtab:
