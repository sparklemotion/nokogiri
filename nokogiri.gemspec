# coding: utf-8
# frozen_string_literal: true

begin
  require File.expand_path(File.join(File.dirname(__FILE__), "lib/nokogiri/version/constant"))
rescue LoadError
  puts "WARNING: Could not load Nokogiri::VERSION"
end

Gem::Specification.new do |spec|
  java_p = /java/ === RUBY_PLATFORM

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

  spec.required_ruby_version = ">= 2.5.0"

  spec.homepage = "https://nokogiri.org"
  spec.metadata = {
    "homepage_uri" => "https://nokogiri.org",
    "bug_tracker_uri" => "https://github.com/sparklemotion/nokogiri/issues",
    "documentation_uri" => "https://nokogiri.org/rdoc/index.html",
    "changelog_uri" => "https://nokogiri.org/CHANGELOG.html",
    "source_code_uri" => "https://github.com/sparklemotion/nokogiri",
  }

  spec.files = [
    "Gemfile",
    "LICENSE-DEPENDENCIES.md",
    "LICENSE.md",
    "README.md",
    "bin/nokogiri",
    "dependencies.yml",
    "ext/java/nokogiri/EncodingHandler.java",
    "ext/java/nokogiri/HtmlDocument.java",
    "ext/java/nokogiri/HtmlElementDescription.java",
    "ext/java/nokogiri/HtmlEntityLookup.java",
    "ext/java/nokogiri/HtmlSaxParserContext.java",
    "ext/java/nokogiri/HtmlSaxPushParser.java",
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
    "ext/nokogiri/html_document.c",
    "ext/nokogiri/html_element_description.c",
    "ext/nokogiri/html_entity_lookup.c",
    "ext/nokogiri/html_sax_parser_context.c",
    "ext/nokogiri/html_sax_push_parser.c",
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
    "lib/isorelax.jar",
    "lib/jing.jar",
    "lib/nekodtd.jar",
    "lib/nekohtml.jar",
    "lib/nokogiri.rb",
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
    "lib/nokogiri/html/builder.rb",
    "lib/nokogiri/html/document.rb",
    "lib/nokogiri/html/document_fragment.rb",
    "lib/nokogiri/html/element_description.rb",
    "lib/nokogiri/html/element_description_defaults.rb",
    "lib/nokogiri/html/entity_lookup.rb",
    "lib/nokogiri/html/sax/parser.rb",
    "lib/nokogiri/html/sax/parser_context.rb",
    "lib/nokogiri/html/sax/push_parser.rb",
    "lib/nokogiri/html5.rb",
    "lib/nokogiri/html5/document.rb",
    "lib/nokogiri/html5/document_fragment.rb",
    "lib/nokogiri/html5/node.rb",
    "lib/nokogiri/jruby/dependencies.rb",
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
    "lib/serializer.jar",
    "lib/xalan.jar",
    "lib/xercesImpl.jar",
    "lib/xml-apis.jar",
    "lib/xsd/xmlparser/nokogiri.rb",
  ]

  spec.bindir = "bin"
  spec.executables = spec.files.grep(/^bin/) { |f| File.basename(f) }

  spec.extra_rdoc_files += Dir.glob("ext/nokogiri/*.c")
  spec.extra_rdoc_files += Dir.glob("README.md")
  spec.rdoc_options = ["--main", "README.md"]

  spec.add_runtime_dependency("racc", "~> 1.4")
  spec.add_runtime_dependency("mini_portile2", "~> 2.5.0") unless java_p # keep version in sync with extconf.rb

  spec.add_development_dependency("bundler", "~> 2.2")
  spec.add_development_dependency("concourse", "~> 0.41")
  spec.add_development_dependency("hoe-markdown", "~> 1.4")
  spec.add_development_dependency("minitest", "~> 5.8")
  spec.add_development_dependency("minitest-reporters", "~> 1.4")
  spec.add_development_dependency("rake", "~> 13.0")
  spec.add_development_dependency("rake-compiler", "~> 1.1")
  spec.add_development_dependency("rake-compiler-dock", "~> 1.1")
  spec.add_development_dependency("rexical", "~> 1.0.5")
  spec.add_development_dependency("rubocop", "~> 1.7")
  spec.add_development_dependency("simplecov", "~> 0.20")
  spec.add_development_dependency("yard", "~> 0.9")

  spec.extensions << "ext/nokogiri/extconf.rb"
end
