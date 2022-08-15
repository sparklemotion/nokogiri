# coding: utf-8
# frozen_string_literal: true

begin
  require File.expand_path(File.join(File.dirname(__FILE__), "lib/nokogiri/version/constant"))
rescue LoadError
  puts "WARNING: Could not load Nokogiri::VERSION"
end

Gem::Specification.new do |spec|
  java_p = /java/.match?(RUBY_PLATFORM)

  spec.name = "nokogiri"
  spec.version = defined?(Nokogiri::VERSION) ? Nokogiri::VERSION : "0.0.0"

  spec.summary = "Nokogiri (鋸) makes it easy and painless to work with XML and HTML from Ruby."
  spec.description = <<~EOF
    Nokogiri (鋸) makes it easy and painless to work with XML and HTML from Ruby. It provides a
    sensible, easy-to-understand API for reading, writing, modifying, and querying documents. It is
    fast and standards-compliant by relying on native parsers like libxml2 (C) and xerces (Java).
  EOF

  spec.authors = [
    "Mike Dalessio",
    "Aaron Patterson",
    "Yoko Harada",
    "Akinori MUSHA",
    "John Shahid",
    "Karol Bucek",
    "Sam Ruby",
    "Craig Barnes",
    "Stephen Checkoway",
    "Lars Kanis",
    "Sergio Arbeo",
    "Timothy Elliott",
    "Nobuyoshi Nakada",
  ]

  spec.email = "nokogiri-talk@googlegroups.com"

  spec.license = "MIT"

  spec.required_ruby_version = ">= 2.6.0"

  spec.homepage = "https://nokogiri.org"
  spec.metadata = {
    "homepage_uri" => "https://nokogiri.org",
    "bug_tracker_uri" => "https://github.com/sparklemotion/nokogiri/issues",
    "documentation_uri" => "https://nokogiri.org/rdoc/index.html",
    "changelog_uri" => "https://nokogiri.org/CHANGELOG.html",
    "source_code_uri" => "https://github.com/sparklemotion/nokogiri",
    "rubygems_mfa_required" => "true",
  }

  spec.files = [
    "Gemfile",
    "LICENSE-DEPENDENCIES.md",
    "LICENSE.md",
    "README.md",
    "bin/nokogiri",
    "dependencies.yml",
    "ext/java/nokogiri/EncodingHandler.java",
    "ext/java/nokogiri/Html4Document.java",
    "ext/java/nokogiri/Html4ElementDescription.java",
    "ext/java/nokogiri/Html4EntityLookup.java",
    "ext/java/nokogiri/Html4SaxParserContext.java",
    "ext/java/nokogiri/Html4SaxPushParser.java",
    "ext/java/nokogiri/NokogiriService.java",
    "ext/java/nokogiri/XmlAttr.java",
    "ext/java/nokogiri/XmlAttributeDecl.java",
    "ext/java/nokogiri/XmlCdata.java",
    "ext/java/nokogiri/XmlComment.java",
    "ext/java/nokogiri/XmlDocument.java",
    "ext/java/nokogiri/XmlDocumentFragment.java",
    "ext/java/nokogiri/XmlDtd.java",
    "ext/java/nokogiri/XmlElement.java",
    "ext/java/nokogiri/XmlElementContent.java",
    "ext/java/nokogiri/XmlElementDecl.java",
    "ext/java/nokogiri/XmlEntityDecl.java",
    "ext/java/nokogiri/XmlEntityReference.java",
    "ext/java/nokogiri/XmlNamespace.java",
    "ext/java/nokogiri/XmlNode.java",
    "ext/java/nokogiri/XmlNodeSet.java",
    "ext/java/nokogiri/XmlProcessingInstruction.java",
    "ext/java/nokogiri/XmlReader.java",
    "ext/java/nokogiri/XmlRelaxng.java",
    "ext/java/nokogiri/XmlSaxParserContext.java",
    "ext/java/nokogiri/XmlSaxPushParser.java",
    "ext/java/nokogiri/XmlSchema.java",
    "ext/java/nokogiri/XmlSyntaxError.java",
    "ext/java/nokogiri/XmlText.java",
    "ext/java/nokogiri/XmlXpathContext.java",
    "ext/java/nokogiri/XsltStylesheet.java",
    "ext/java/nokogiri/internals/ClosedStreamException.java",
    "ext/java/nokogiri/internals/HtmlDomParserContext.java",
    "ext/java/nokogiri/internals/IgnoreSchemaErrorsErrorHandler.java",
    "ext/java/nokogiri/internals/NokogiriBlockingQueueInputStream.java",
    "ext/java/nokogiri/internals/NokogiriDomParser.java",
    "ext/java/nokogiri/internals/NokogiriEntityResolver.java",
    "ext/java/nokogiri/internals/NokogiriErrorHandler.java",
    "ext/java/nokogiri/internals/NokogiriHandler.java",
    "ext/java/nokogiri/internals/NokogiriHelpers.java",
    "ext/java/nokogiri/internals/NokogiriNamespaceCache.java",
    "ext/java/nokogiri/internals/NokogiriNamespaceContext.java",
    "ext/java/nokogiri/internals/NokogiriNonStrictErrorHandler.java",
    "ext/java/nokogiri/internals/NokogiriNonStrictErrorHandler4NekoHtml.java",
    "ext/java/nokogiri/internals/NokogiriStrictErrorHandler.java",
    "ext/java/nokogiri/internals/NokogiriXPathFunction.java",
    "ext/java/nokogiri/internals/NokogiriXPathFunctionResolver.java",
    "ext/java/nokogiri/internals/NokogiriXPathVariableResolver.java",
    "ext/java/nokogiri/internals/NokogiriXsltErrorListener.java",
    "ext/java/nokogiri/internals/ParserContext.java",
    "ext/java/nokogiri/internals/ReaderNode.java",
    "ext/java/nokogiri/internals/SaveContextVisitor.java",
    "ext/java/nokogiri/internals/SchemaErrorHandler.java",
    "ext/java/nokogiri/internals/XalanDTMManagerPatch.java",
    "ext/java/nokogiri/internals/XmlDeclHandler.java",
    "ext/java/nokogiri/internals/XmlDomParserContext.java",
    "ext/java/nokogiri/internals/XmlSaxParser.java",
    "ext/java/nokogiri/internals/c14n/AttrCompare.java",
    "ext/java/nokogiri/internals/c14n/C14nHelper.java",
    "ext/java/nokogiri/internals/c14n/CanonicalFilter.java",
    "ext/java/nokogiri/internals/c14n/CanonicalizationException.java",
    "ext/java/nokogiri/internals/c14n/Canonicalizer.java",
    "ext/java/nokogiri/internals/c14n/Canonicalizer11.java",
    "ext/java/nokogiri/internals/c14n/Canonicalizer11_OmitComments.java",
    "ext/java/nokogiri/internals/c14n/Canonicalizer11_WithComments.java",
    "ext/java/nokogiri/internals/c14n/Canonicalizer20010315.java",
    "ext/java/nokogiri/internals/c14n/Canonicalizer20010315Excl.java",
    "ext/java/nokogiri/internals/c14n/Canonicalizer20010315ExclOmitComments.java",
    "ext/java/nokogiri/internals/c14n/Canonicalizer20010315ExclWithComments.java",
    "ext/java/nokogiri/internals/c14n/Canonicalizer20010315OmitComments.java",
    "ext/java/nokogiri/internals/c14n/Canonicalizer20010315WithComments.java",
    "ext/java/nokogiri/internals/c14n/CanonicalizerBase.java",
    "ext/java/nokogiri/internals/c14n/CanonicalizerPhysical.java",
    "ext/java/nokogiri/internals/c14n/CanonicalizerSpi.java",
    "ext/java/nokogiri/internals/c14n/Constants.java",
    "ext/java/nokogiri/internals/c14n/ElementProxy.java",
    "ext/java/nokogiri/internals/c14n/HelperNodeList.java",
    "ext/java/nokogiri/internals/c14n/IgnoreAllErrorHandler.java",
    "ext/java/nokogiri/internals/c14n/InclusiveNamespaces.java",
    "ext/java/nokogiri/internals/c14n/InvalidCanonicalizerException.java",
    "ext/java/nokogiri/internals/c14n/NameSpaceSymbTable.java",
    "ext/java/nokogiri/internals/c14n/NodeFilter.java",
    "ext/java/nokogiri/internals/c14n/UtfHelpper.java",
    "ext/java/nokogiri/internals/c14n/XMLUtils.java",
    "ext/java/nokogiri/internals/dom2dtm/DOM2DTM.java",
    "ext/java/nokogiri/internals/dom2dtm/DOM2DTMdefaultNamespaceDeclarationNode.java",
    "ext/nokogiri/depend",
    "ext/nokogiri/extconf.rb",
    "ext/nokogiri/html4_document.c",
    "ext/nokogiri/html4_element_description.c",
    "ext/nokogiri/html4_entity_lookup.c",
    "ext/nokogiri/html4_sax_parser_context.c",
    "ext/nokogiri/html4_sax_push_parser.c",
    "ext/nokogiri/libxml2_backwards_compat.c",
    "ext/nokogiri/nokogiri.c",
    "ext/nokogiri/nokogiri.h",
    "ext/nokogiri/xml_attr.c",
    "ext/nokogiri/xml_attribute_decl.c",
    "ext/nokogiri/xml_cdata.c",
    "ext/nokogiri/xml_comment.c",
    "ext/nokogiri/xml_document.c",
    "ext/nokogiri/xml_document_fragment.c",
    "ext/nokogiri/xml_dtd.c",
    "ext/nokogiri/xml_element_content.c",
    "ext/nokogiri/xml_element_decl.c",
    "ext/nokogiri/xml_encoding_handler.c",
    "ext/nokogiri/xml_entity_decl.c",
    "ext/nokogiri/xml_entity_reference.c",
    "ext/nokogiri/xml_namespace.c",
    "ext/nokogiri/xml_node.c",
    "ext/nokogiri/xml_node_set.c",
    "ext/nokogiri/xml_processing_instruction.c",
    "ext/nokogiri/xml_reader.c",
    "ext/nokogiri/xml_relax_ng.c",
    "ext/nokogiri/xml_sax_parser.c",
    "ext/nokogiri/xml_sax_parser_context.c",
    "ext/nokogiri/xml_sax_push_parser.c",
    "ext/nokogiri/xml_schema.c",
    "ext/nokogiri/xml_syntax_error.c",
    "ext/nokogiri/xml_text.c",
    "ext/nokogiri/xml_xpath_context.c",
    "ext/nokogiri/xslt_stylesheet.c",
    "gumbo-parser/CHANGES.md",
    "gumbo-parser/Makefile",
    "gumbo-parser/THANKS",
    "gumbo-parser/src/Makefile",
    "gumbo-parser/src/README.md",
    "gumbo-parser/src/ascii.c",
    "gumbo-parser/src/ascii.h",
    "gumbo-parser/src/attribute.c",
    "gumbo-parser/src/attribute.h",
    "gumbo-parser/src/char_ref.c",
    "gumbo-parser/src/char_ref.h",
    "gumbo-parser/src/char_ref.rl",
    "gumbo-parser/src/error.c",
    "gumbo-parser/src/error.h",
    "gumbo-parser/src/foreign_attrs.c",
    "gumbo-parser/src/foreign_attrs.gperf",
    "gumbo-parser/src/nokogiri_gumbo.h",
    "gumbo-parser/src/insertion_mode.h",
    "gumbo-parser/src/macros.h",
    "gumbo-parser/src/parser.c",
    "gumbo-parser/src/parser.h",
    "gumbo-parser/src/replacement.h",
    "gumbo-parser/src/string_buffer.c",
    "gumbo-parser/src/string_buffer.h",
    "gumbo-parser/src/string_piece.c",
    "gumbo-parser/src/svg_attrs.c",
    "gumbo-parser/src/svg_attrs.gperf",
    "gumbo-parser/src/svg_tags.c",
    "gumbo-parser/src/svg_tags.gperf",
    "gumbo-parser/src/tag.c",
    "gumbo-parser/src/tag_lookup.c",
    "gumbo-parser/src/tag_lookup.gperf",
    "gumbo-parser/src/tag_lookup.h",
    "gumbo-parser/src/token_buffer.c",
    "gumbo-parser/src/token_buffer.h",
    "gumbo-parser/src/token_type.h",
    "gumbo-parser/src/tokenizer.c",
    "gumbo-parser/src/tokenizer.h",
    "gumbo-parser/src/tokenizer_states.h",
    "gumbo-parser/src/utf8.c",
    "gumbo-parser/src/utf8.h",
    "gumbo-parser/src/util.c",
    "gumbo-parser/src/util.h",
    "gumbo-parser/src/vector.c",
    "gumbo-parser/src/vector.h",
    "lib/nokogiri.rb",
    "lib/nokogiri/class_resolver.rb",
    "lib/nokogiri/css.rb",
    "lib/nokogiri/css/node.rb",
    "lib/nokogiri/css/parser.rb",
    "lib/nokogiri/css/parser.y",
    "lib/nokogiri/css/parser_extras.rb",
    "lib/nokogiri/css/syntax_error.rb",
    "lib/nokogiri/css/tokenizer.rb",
    "lib/nokogiri/css/tokenizer.rex",
    "lib/nokogiri/css/xpath_visitor.rb",
    "lib/nokogiri/decorators/slop.rb",
    "lib/nokogiri/extension.rb",
    "lib/nokogiri/gumbo.rb",
    "lib/nokogiri/html.rb",
    "lib/nokogiri/html4.rb",
    "lib/nokogiri/html4/builder.rb",
    "lib/nokogiri/html4/document.rb",
    "lib/nokogiri/html4/document_fragment.rb",
    "lib/nokogiri/html4/element_description.rb",
    "lib/nokogiri/html4/element_description_defaults.rb",
    "lib/nokogiri/html4/encoding_reader.rb",
    "lib/nokogiri/html4/entity_lookup.rb",
    "lib/nokogiri/html4/sax/parser.rb",
    "lib/nokogiri/html4/sax/parser_context.rb",
    "lib/nokogiri/html4/sax/push_parser.rb",
    "lib/nokogiri/html5.rb",
    "lib/nokogiri/html5/document.rb",
    "lib/nokogiri/html5/document_fragment.rb",
    "lib/nokogiri/html5/node.rb",
    "lib/nokogiri/jruby/dependencies.rb",
    "lib/nokogiri/jruby/isorelax/isorelax/20030108/isorelax-20030108.jar",
    "lib/nokogiri/jruby/net/sf/saxon/Saxon-HE/9.6.0-4/Saxon-HE-9.6.0-4.jar",
    "lib/nokogiri/jruby/net/sourceforge/htmlunit/neko-htmlunit/2.63.0/neko-htmlunit-2.63.0.jar",
    "lib/nokogiri/jruby/nokogiri_jars.rb",
    "lib/nokogiri/jruby/nu/validator/jing/20200702VNU/jing-20200702VNU.jar",
    "lib/nokogiri/jruby/org/nokogiri/nekodtd/0.1.11.noko1/nekodtd-0.1.11.noko1.jar",
    "lib/nokogiri/jruby/xalan/serializer/2.7.2/serializer-2.7.2.jar",
    "lib/nokogiri/jruby/xalan/xalan/2.7.2/xalan-2.7.2.jar",
    "lib/nokogiri/jruby/xerces/xercesImpl/2.12.2/xercesImpl-2.12.2.jar",
    "lib/nokogiri/jruby/xml-apis/xml-apis/1.4.01/xml-apis-1.4.01.jar",
    "lib/nokogiri/syntax_error.rb",
    "lib/nokogiri/version.rb",
    "lib/nokogiri/version/constant.rb",
    "lib/nokogiri/version/info.rb",
    "lib/nokogiri/xml.rb",
    "lib/nokogiri/xml/attr.rb",
    "lib/nokogiri/xml/attribute_decl.rb",
    "lib/nokogiri/xml/builder.rb",
    "lib/nokogiri/xml/cdata.rb",
    "lib/nokogiri/xml/character_data.rb",
    "lib/nokogiri/xml/document.rb",
    "lib/nokogiri/xml/document_fragment.rb",
    "lib/nokogiri/xml/dtd.rb",
    "lib/nokogiri/xml/element_content.rb",
    "lib/nokogiri/xml/element_decl.rb",
    "lib/nokogiri/xml/entity_decl.rb",
    "lib/nokogiri/xml/entity_reference.rb",
    "lib/nokogiri/xml/namespace.rb",
    "lib/nokogiri/xml/node.rb",
    "lib/nokogiri/xml/node/save_options.rb",
    "lib/nokogiri/xml/node_set.rb",
    "lib/nokogiri/xml/notation.rb",
    "lib/nokogiri/xml/parse_options.rb",
    "lib/nokogiri/xml/pp.rb",
    "lib/nokogiri/xml/pp/character_data.rb",
    "lib/nokogiri/xml/pp/node.rb",
    "lib/nokogiri/xml/processing_instruction.rb",
    "lib/nokogiri/xml/reader.rb",
    "lib/nokogiri/xml/relax_ng.rb",
    "lib/nokogiri/xml/sax.rb",
    "lib/nokogiri/xml/sax/document.rb",
    "lib/nokogiri/xml/sax/parser.rb",
    "lib/nokogiri/xml/sax/parser_context.rb",
    "lib/nokogiri/xml/sax/push_parser.rb",
    "lib/nokogiri/xml/schema.rb",
    "lib/nokogiri/xml/searchable.rb",
    "lib/nokogiri/xml/syntax_error.rb",
    "lib/nokogiri/xml/text.rb",
    "lib/nokogiri/xml/xpath.rb",
    "lib/nokogiri/xml/xpath/syntax_error.rb",
    "lib/nokogiri/xml/xpath_context.rb",
    "lib/nokogiri/xslt.rb",
    "lib/nokogiri/xslt/stylesheet.rb",
    "lib/xsd/xmlparser/nokogiri.rb",
  ]
  spec.bindir = "bin"
  spec.executables = spec.files.grep(/^bin/) { |f| File.basename(f) }

  spec.extra_rdoc_files += Dir.glob("ext/nokogiri/*.c")
  spec.extra_rdoc_files += Dir.glob("README.md")
  spec.rdoc_options = ["--main", "README.md"]

  if java_p
    # loosen after jruby fixes https://github.com/jruby/jruby/issues/7262
    # also see https://github.com/mkristian/jar-dependencies/commit/006fb254
    spec.add_development_dependency("jar-dependencies", "= 0.4.1")

    spec.require_paths << "lib/nokogiri/jruby" # where we install the jars, see the :vendor_jars rake task
    spec.requirements << "jar isorelax, isorelax, 20030108" # https://search.maven.org/artifact/isorelax/isorelax
    spec.requirements << "jar org.nokogiri, nekodtd, 0.1.11.noko1"
    spec.requirements << "jar net.sourceforge.htmlunit, neko-htmlunit, 2.63.0"
    spec.requirements << "jar nu.validator, jing, 20200702VNU" # https://search.maven.org/artifact/nu.validator/jing
    spec.requirements << "jar xalan, serializer, 2.7.2" # https://search.maven.org/artifact/xalan/serializer
    spec.requirements << "jar xalan, xalan, 2.7.2" # https://search.maven.org/artifact/xalan/xalan
    spec.requirements << "jar xerces, xercesImpl, 2.12.2" # https://search.maven.org/artifact/xerces/xercesImpl
    spec.requirements << "jar xml-apis, xml-apis, 1.4.01" # https://search.maven.org/artifact/xml-apis/xml-apis
  else
    spec.add_runtime_dependency("mini_portile2", "~> 2.8.0") # keep version in sync with extconf.rb
  end
  spec.add_runtime_dependency("racc", "~> 1.4")

  spec.add_development_dependency("bundler", "~> 2.3")
  spec.add_development_dependency("hoe-markdown", "~> 1.4.0")
  spec.add_development_dependency("minitest", "~> 5.16.2")
  spec.add_development_dependency("minitest-reporters", "~> 1.5.0")
  spec.add_development_dependency("rake", "~> 13.0.6")
  spec.add_development_dependency("rake-compiler", "= 1.2.0")
  spec.add_development_dependency("rake-compiler-dock", "= 1.2.2")
  spec.add_development_dependency("rdoc", "~> 6.4.0")
  spec.add_development_dependency("rexical", "~> 1.0.7")
  spec.add_development_dependency("rubocop", "~> 1.35.0")
  spec.add_development_dependency("rubocop-minitest", "~> 0.21.0")
  spec.add_development_dependency("rubocop-performance", "~> 1.14.2")
  spec.add_development_dependency("rubocop-rake", "~> 0.6.0")
  spec.add_development_dependency("rubocop-shopify", "= 2.5.0") # TODO: loosen this after dropping support for Ruby 2.6
  spec.add_development_dependency("ruby_memcheck", "~> 1.0.3")
  spec.add_development_dependency("simplecov", "~> 0.21.2")

  spec.extensions << "ext/nokogiri/extconf.rb"
end
