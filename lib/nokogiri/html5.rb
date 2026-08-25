# coding: utf-8
# frozen_string_literal: true

# This file includes code from the Nokogumbo project, whose license follows.
#
#   Copyright 2013-2021 Sam Ruby, Stephen Checkoway
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

require_relative "html5/document"
require_relative "html5/document_fragment"
require_relative "html5/node"
require_relative "html5/builder"

module Nokogiri
  # Convenience method for Nokogiri::HTML5::Document.parse
  def self.HTML5(...)
    Nokogiri::HTML5::Document.parse(...)
  end

  # == Usage
  #
  # Parse an HTML5 document:
  #
  #   doc = Nokogiri.HTML5(input)
  #
  # Parse an HTML5 fragment:
  #
  #   fragment = Nokogiri::HTML5.fragment(input)
  #
  # ⚠️️️ HTML5 functionality is not available when running JRuby.
  #
  # == Parsing options
  #
  # The document and fragment parsing methods support options that are different from
  # Nokogiri::HTML4::Document or Nokogiri::XML::Document.
  #
  # - <tt>Nokogiri.HTML5(input, url:, encoding:, **parse_options)</tt>
  # - <tt>Nokogiri::HTML5.parse(input, url:, encoding:, **parse_options)</tt>
  # - <tt>Nokogiri::HTML5::Document.parse(input, url:, encoding:, **parse_options)</tt>
  # - <tt>Nokogiri::HTML5.fragment(input, encoding:, **parse_options)</tt>
  # - <tt>Nokogiri::HTML5::DocumentFragment.parse(input, encoding:, **parse_options)</tt>
  #
  # The four currently supported parse options are
  #
  # - +max_errors:+ (Integer, default 0) Maximum number of parse errors to report in HTML5::Document#errors.
  # - +max_tree_depth:+ (Integer, default +Nokogiri::Gumbo::DEFAULT_MAX_TREE_DEPTH+) Maximum tree depth to parse.
  # - +max_attributes:+ (Integer, default +Nokogiri::Gumbo::DEFAULT_MAX_ATTRIBUTES+) Maximum number of attributes to parse per element.
  # - +parse_noscript_content_as_text:+ (Boolean, default false) When enabled, parse +noscript+ tag content as text, mimicking the behavior of web browsers.
  #
  # These options are explained in the following sections.
  #
  # === Error reporting: +max_errors:+
  #
  # Nokogiri contains an experimental HTML5 parse error reporting facility. By default, no parse
  # errors are reported but this can be configured by passing the +:max_errors+ option to
  # HTML5.parse or HTML5.fragment.
  #
  # For example, this script:
  #
  #   doc = Nokogiri::HTML5.parse('<span/>Hi there!</span foo=bar />', max_errors: 10)
  #   doc.errors.each do |err|
  #     puts(err)
  #   end
  #
  # Emits:
  #
  #   1:1: ERROR: Expected a doctype token
  #   <span/>Hi there!</span foo=bar />
  #   ^
  #   1:1: ERROR: Start tag of nonvoid HTML element ends with '/>', use '>'.
  #   <span/>Hi there!</span foo=bar />
  #   ^
  #   1:17: ERROR: End tag ends with '/>', use '>'.
  #   <span/>Hi there!</span foo=bar />
  #                   ^
  #   1:17: ERROR: End tag contains attributes.
  #   <span/>Hi there!</span foo=bar />
  #                   ^
  #
  # Using <tt>max_errors: -1</tt> results in an unlimited number of errors being returned.
  #
  # The errors returned by HTML5::Document#errors are instances of Nokogiri::XML::SyntaxError.
  #
  # The {HTML standard}[https://html.spec.whatwg.org/multipage/parsing.html#parse-errors] defines a
  # number of standard parse error codes. These error codes only cover the "tokenization" stage of
  # parsing HTML. The parse errors in the "tree construction" stage do not have standardized error
  # codes (yet).
  #
  # As a convenience to Nokogiri users, the defined error codes are available
  # via Nokogiri::XML::SyntaxError#str1 method.
  #
  #   doc = Nokogiri::HTML5.parse('<span/>Hi there!</span foo=bar />', max_errors: 10)
  #   doc.errors.each do |err|
  #     puts("#{err.line}:#{err.column}: #{err.str1}")
  #   end
  #   doc = Nokogiri::HTML5.parse('<span/>Hi there!</span foo=bar />',
  #   # => 1:1: generic-parser
  #   #    1:1: non-void-html-element-start-tag-with-trailing-solidus
  #   #    1:17: end-tag-with-trailing-solidus
  #   #    1:17: end-tag-with-attributes
  #
  # Note that the first error is +generic-parser+ because it's an error from the tree construction
  # stage and doesn't have a standardized error code.
  #
  # For the purposes of semantic versioning, the error messages, error locations, and error codes
  # are not part of Nokogiri's public API. That is, these are subject to change without Nokogiri's
  # major version number changing. These may be stabilized in the future.
  #
  # === Maximum tree depth: +max_tree_depth:+
  #
  # The maximum depth of the DOM tree parsed by the various parsing methods is configurable by the
  # +:max_tree_depth+ option. If the depth of the tree would exceed this limit, then an
  # +ArgumentError+ is thrown.
  #
  # This limit (which defaults to +Nokogiri::Gumbo::DEFAULT_MAX_TREE_DEPTH+) can be removed by
  # giving the option <tt>max_tree_depth: -1</tt>.
  #
  #   html = '<!DOCTYPE html>' + '<div>' * 1000
  #   doc = Nokogiri.HTML5(html)
  #   # raises ArgumentError: Document tree depth limit exceeded
  #   doc = Nokogiri.HTML5(html, max_tree_depth: -1)
  #
  # === Attribute limit per element: +max_attributes:+
  #
  # The maximum number of attributes per DOM element is configurable by the +:max_attributes+
  # option. If a given element would exceed this limit, then an +ArgumentError+ is thrown.
  #
  # This limit (which defaults to +Nokogiri::Gumbo::DEFAULT_MAX_ATTRIBUTES+) can be removed by
  # giving the option <tt>max_attributes: -1</tt>.
  #
  #   html = '<!DOCTYPE html><div ' + (1..1000).map { |x| "attr-#{x}" }.join(' # ') + '>'
  #   # "<!DOCTYPE html><div attr-1 attr-2 attr-3 ... attr-1000>"
  #   doc = Nokogiri.HTML5(html)
  #   # raises ArgumentError: Attributes per element limit exceeded
  #
  #   doc = Nokogiri.HTML5(html, max_attributes: -1)
  #   # parses successfully
  #
  # === Parse +noscript+ elements' content as text: +parse_noscript_content_as_text:+
  #
  # By default, the content of +noscript+ elements is parsed as HTML elements. Browsers that
  # support scripting parse the content of +noscript+ elements as raw text.
  #
  # The +:parse_noscript_content_as_text+ option causes Nokogiri to parse the content of +noscript+
  # elements as a single text node.
  #
  #   html = "<!DOCTYPE html><noscript><meta charset='UTF-8'><link rel=stylesheet href=!></noscript>"
  #   doc = Nokogiri::HTML5.parse(html, parse_noscript_content_as_text: true)
  #   pp doc.at_xpath("/html/head/noscript")
  #   # => #(Element:0x878c {
  #   #        name = "noscript",
  #   #        children = [ #(Text "<meta charset='UTF-8'><link rel=stylesheet href=!>")]
  #   #      })
  #
  # In contrast, <tt>parse_noscript_content_as_text: false</tt> (the default) causes the +noscript+
  # element in the previous example to have two children, a +meta+ element and a +link+ element.
  #
  #   doc = Nokogiri::HTML5.parse(html)
  #   puts doc.at_xpath("/html/head/noscript")
  #   # => #(Element:0x96b4 {
  #   #      name = "noscript",
  #   #      children = [
  #   #        #(Element:0x97e0 { name = "meta", attribute_nodes = [ #(Attr:0x990c { name = "charset", value = "UTF-8" })] }),
  #   #        #(Element:0x9b00 {
  #   #          name = "link",
  #   #          attribute_nodes = [
  #   #            #(Attr:0x9c2c { name = "rel", value = "stylesheet" }),
  #   #            #(Attr:0x9dd0 { name = "href", value = "!" })]
  #   #          })]
  #   #      })
  #
  # == HTML Serialization
  #
  # After parsing HTML, it may be serialized using any of the Nokogiri::XML::Node serialization
  # methods. In particular, XML::Node#serialize, XML::Node#to_html, and XML::Node#to_s will
  # serialize a given node and its children. (This is the equivalent of JavaScript's
  # +Element.outerHTML+.) Similarly, XML::Node#inner_html will serialize the children of a given
  # node. (This is the equivalent of JavaScript's +Element.innerHTML+.)
  #
  #   doc = Nokogiri::HTML5("<!DOCTYPE html><span>Hello world!</span>")
  #   puts doc.serialize
  #   # => <!DOCTYPE html><html><head></head><body><span>Hello world!</span></body></html>
  #
  # Due to quirks in how HTML is parsed and serialized, it's possible for a DOM tree to be
  # serialized and then re-parsed, resulting in a different DOM. Mostly, this happens with DOMs
  # produced from invalid HTML. Unfortunately, even valid HTML may not survive serialization and
  # re-parsing.
  #
  # In particular, a newline at the start of +pre+, +listing+, and +textarea+
  # elements is ignored by the parser.
  #
  #   doc = Nokogiri::HTML5(<<-EOF)
  #   <!DOCTYPE html>
  #   <pre>
  #   Content</pre>
  #   EOF
  #   puts doc.at('/html/body/pre').serialize
  #   # => <pre>Content</pre>
  #
  # In this case, the original HTML is semantically equivalent to the serialized version. If the
  # +pre+, +listing+, or +textarea+ content starts with two newlines, the first newline will be
  # stripped on the first parse and the second newline will be stripped on the second, leading to
  # semantically different DOMs. Passing the parameter <tt>preserve_newline: true</tt> will cause
  # two or more newlines to be preserved. (A single leading newline will still be removed.)
  #
  #   doc = Nokogiri::HTML5(<<-EOF)
  #   <!DOCTYPE html>
  #   <listing>
  #
  #   Content</listing>
  #   EOF
  #   puts doc.at('/html/body/listing').serialize(preserve_newline: true)
  #   # => <listing>
  #   #
  #   #    Content</listing>
  #
  # == Encodings
  #
  # Nokogiri always parses HTML5 using {UTF-8}[https://en.wikipedia.org/wiki/UTF-8]; however, the
  # encoding of the input can be explicitly selected via the optional +encoding+ parameter. This is
  # most useful when the input comes not from a string but from an IO object.
  #
  # When serializing a document or node, the encoding of the output string can be specified via the
  # +:encoding+ options. Characters that cannot be encoded in the selected encoding will be encoded
  # as {HTML numeric
  # entities}[https://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references].
  #
  #   frag = Nokogiri::HTML5.fragment('<span>아는 길도 물어가라</span>')
  #   html = frag.serialize(encoding: 'US-ASCII')
  #   puts html
  #   # => <span>&#xc544;&#xb294; &#xae38;&#xb3c4; &#xbb3c;&#xc5b4;&#xac00;&#xb77c;</span>
  #
  #   frag = Nokogiri::HTML5.fragment(html)
  #   puts frag.serialize
  #   # => <span>아는 길도 물어가라</span>
  #
  # (There's a {bug}[https://bugs.ruby-lang.org/issues/15033] in all current versions of Ruby that
  # can cause the entity encoding to fail. Of the mandated supported encodings for HTML, the only
  # encoding I'm aware of that has this bug is <tt>'ISO-2022-JP'</tt>. We recommend avoiding this
  # encoding.)
  #
  # == Notes
  #
  # * The Nokogiri::HTML5.fragment function takes a String or IO and parses it as a HTML5 document
  #   in a +body+ context. As a result, the +html+, +head+, and +body+ elements are removed from
  #   this document, and any children of these elements that remain are returned as a
  #   Nokogiri::HTML5::DocumentFragment; but you can pass in a different context (e.g., "html" to
  #   get +head+ and +body+ tags in the result).
  #
  # * The Nokogiri::HTML5.parse function takes a String or IO and passes it to the
  #   <code>gumbo_parse_with_options</code> method, using the default options.  The resulting Gumbo
  #   parse tree is then walked.
  #
  # * Instead of uppercase element names, lowercase element names are produced.
  #
  # * Instead of returning +unknown+ as the element name for unknown tags, the original tag name is
  #   returned verbatim.
  #
  # Since v1.12.0
  module HTML5
    class << self
      # Convenience method for Nokogiri::HTML5::Document.parse
      def parse(...)
        Document.parse(...)
      end

      # Convenience method for Nokogiri::HTML5::DocumentFragment.parse
      def fragment(...)
        DocumentFragment.parse(...)
      end

      # :nodoc:
      def read_and_encode(string, encoding)
        # Read the string with the given encoding.
        if string.respond_to?(:read)
          internal = string.internal_encoding if string.respond_to?(:internal_encoding)
          # A StringIO holds an already-decoded String and reports that String's encoding rather
          # than a locale default, so wrapping a String in one must not change how it decodes.
          wraps_a_string = StringIO === string
          string = string.read

          if encoding
            string.force_encoding(encoding)
          elsif internal.nil? && !wraps_a_string
            # Ruby records nothing about whether an IO's external encoding was chosen by the
            # caller or inherited from the locale, so it cannot stand in for what the document
            # says about itself. Prefer the document's own declaration, and let a caller who
            # needs to override it say so with the `encoding:` argument.
            #
            # When the document declares nothing, keep the IO's encoding. The standard's answer
            # there is windows-1252 and #reencode falls back to ISO_8859_1, so this is a third
            # answer and a deliberate one: it is the conservative choice and it leaves documents
            # that parse correctly today parsing the same way.
            declared = detect_encoding(string)
            if declared
              begin
                string.force_encoding(declared)
              rescue ArgumentError
                # The document named an encoding Ruby does not know. #reencode makes the same
                # choice for the binary path, so make it here too rather than keeping an IO
                # encoding this branch has already decided says nothing about the document.
                string.force_encoding(Encoding::ISO_8859_1)
              end
            end
          end
        else
          # Otherwise the string has the given encoding.
          string = string.to_s
          if encoding
            string = string.dup
            string.force_encoding(encoding)
          end
        end

        # convert to UTF-8
        if string.encoding != Encoding::UTF_8
          string = reencode(string)
        end
        string
      end

      private

      # Charset sniffing is a complex and controversial topic that understandably isn't done _by
      # default_ by the Ruby Net::HTTP library. This being said, it is a very real problem for
      # consumers of HTML as the default for HTML is iso-8859-1, most "good" producers use utf-8, and
      # the Gumbo parser *only* supports utf-8.
      #
      # Accordingly, Nokogiri::HTML4::Document.parse provides limited encoding detection. Following
      # this lead, Nokogiri::HTML5 attempts to do likewise, while attempting to more closely follow
      # the HTML5 standard.
      #
      # http://bugs.ruby-lang.org/issues/2567
      # http://www.w3.org/TR/html5/syntax.html#determining-the-character-encoding
      #
      def reencode(body, content_type = nil)
        if body.encoding == Encoding::ASCII_8BIT
          # if all else fails, default to the official default encoding for HTML
          encoding = detect_encoding(body, content_type) || Encoding::ISO_8859_1

          # change the encoding to match the detected or inferred encoding
          body = body.dup
          begin
            body.force_encoding(encoding)
          rescue ArgumentError
            body.force_encoding(Encoding::ISO_8859_1)
          end
        end

        body.encode(Encoding::UTF_8)
      end

      # The standard's charset labels are not Ruby encoding names. "Get an encoding" maps
      # roughly 220 labels onto encodings, while String#force_encoding accepts only Ruby's own
      # names and aliases. Normalize the labels Ruby rejects but that appear in real documents,
      # so that the IO path and the binary path agree on the same declaration. The standard
      # folds latin1 and iso-8859-1 into windows-1252; Ruby keeps them as ISO-8859-1, and so
      # does #reencode's fallback, so latin1 follows its synonym here rather than the table.
      LABEL_ALIASES = {
        "utf8" => "UTF-8",
        "unicode-1-1-utf-8" => "UTF-8",
        "latin1" => "ISO-8859-1",
        "shift-jis" => "Shift_JIS",
        "x-sjis" => "Shift_JIS",
        "ms932" => "Shift_JIS",
        "csshiftjis" => "Shift_JIS",
        "x-user-defined" => "Windows-1252",
      }.freeze
      private_constant :LABEL_ALIASES

      # Returns nil for an empty label, so that `charset=""` counts as no declaration rather
      # than as a declaration of an encoding named "".
      def normalize_encoding_label(label)
        # "Get an encoding" strips leading and trailing ASCII whitespace and matches
        # case-insensitively, so normalize first and keep the normalized form even when the
        # label is not in the table above -- Encoding.find is case-insensitive too.
        label = label.strip.downcase
        return if label.empty?

        label = LABEL_ALIASES.fetch(label, label)
        # The standard's prescan replaces two of the encodings it gets: "If charset is
        # UTF-16BE/LE, then set charset to UTF-8" (a document that really were UTF-16 could not
        # have carried an ASCII-readable meta), and "If charset is x-user-defined, then set
        # charset to windows-1252". The latter is in LABEL_ALIASES above.
        /\Autf-16/i.match?(label) ? "UTF-8" : label
      end

      # Return the encoding the document declares for itself, or nil when it declares none. Only
      # the first 1024 bytes are examined, per the HTML5 standard's prescan.
      def detect_encoding(body, content_type = nil)
        head = body.byteslice(0, 1024).b

        # look for a Byte Order Mark (BOM)
        initial_bytes = head[0..2].bytes
        if initial_bytes[0..2] == [0xEF, 0xBB, 0xBF]
          return Encoding::UTF_8
        elsif initial_bytes[0..1] == [0xFE, 0xFF]
          return Encoding::UTF_16BE
        elsif initial_bytes[0..1] == [0xFF, 0xFE]
          return Encoding::UTF_16LE
        end

        # look for a charset in a content-encoding header
        if content_type
          encoding = content_type[/charset=["']?(.*?)($|["';\s])/i, 1]
          encoding = normalize_encoding_label(encoding) if encoding
          return encoding if encoding
        end

        # look for a charset in a meta tag in the first 1024 bytes
        data = head.gsub(/<!--.*?(-->|\Z)/m, "")
        data.scan(/<meta.*?>/im).each do |meta|
          encoding = meta[/charset=["']?([^>]*?)($|["'\s>])/im, 1]
          encoding = normalize_encoding_label(encoding) if encoding
          return encoding if encoding
        end

        nil
      end
    end
  end
end

require_relative "gumbo"
