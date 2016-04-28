# -*- encoding: utf-8 -*-
# stub: nokogiri 1.6.8.rc3.20160428093317 java lib

Gem::Specification.new do |s|
  s.name = "nokogiri"
  s.version = "1.6.8.rc3"
  s.platform = "java"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Aaron Patterson", "Mike Dalessio", "Yoko Harada", "Tim Elliott", "Akinori MUSHA"]
  s.date = "2016-04-28"
  s.description = "Nokogiri (\u{92f8}) is an HTML, XML, SAX, and Reader parser.  Among\nNokogiri's many features is the ability to search documents via XPath\nor CSS3 selectors.\n\nXML is like violence - if it doesn\u{2019}t solve your problems, you are not\nusing enough of it."
  s.email = ["aaronp@rubyforge.org", "mike.dalessio@gmail.com", "yokolet@gmail.com", "tle@holymonkey.com", "knu@idaemons.org"]
  s.executables = ["nokogiri"]
  s.extra_rdoc_files = ["CHANGELOG.rdoc", "CONTRIBUTING.md", "C_CODING_STYLE.rdoc", "LICENSE.txt", "Manifest.txt", "README.md", "ROADMAP.md", "STANDARD_RESPONSES.md", "Y_U_NO_GEMSPEC.md", "suppressions/README.txt", "CHANGELOG.rdoc", "C_CODING_STYLE.rdoc", "ext/nokogiri/html_document.c", "ext/nokogiri/html_element_description.c", "ext/nokogiri/html_entity_lookup.c", "ext/nokogiri/html_sax_parser_context.c", "ext/nokogiri/html_sax_push_parser.c", "ext/nokogiri/nokogiri.c", "ext/nokogiri/xml_attr.c", "ext/nokogiri/xml_attribute_decl.c", "ext/nokogiri/xml_cdata.c", "ext/nokogiri/xml_comment.c", "ext/nokogiri/xml_document.c", "ext/nokogiri/xml_document_fragment.c", "ext/nokogiri/xml_dtd.c", "ext/nokogiri/xml_element_content.c", "ext/nokogiri/xml_element_decl.c", "ext/nokogiri/xml_encoding_handler.c", "ext/nokogiri/xml_entity_decl.c", "ext/nokogiri/xml_entity_reference.c", "ext/nokogiri/xml_io.c", "ext/nokogiri/xml_libxml2_hacks.c", "ext/nokogiri/xml_namespace.c", "ext/nokogiri/xml_node.c", "ext/nokogiri/xml_node_set.c", "ext/nokogiri/xml_processing_instruction.c", "ext/nokogiri/xml_reader.c", "ext/nokogiri/xml_relax_ng.c", "ext/nokogiri/xml_sax_parser.c", "ext/nokogiri/xml_sax_parser_context.c", "ext/nokogiri/xml_sax_push_parser.c", "ext/nokogiri/xml_schema.c", "ext/nokogiri/xml_syntax_error.c", "ext/nokogiri/xml_text.c", "ext/nokogiri/xml_xpath_context.c", "ext/nokogiri/xslt_stylesheet.c"]
  s.files = [".autotest", ".cross_rubies", ".editorconfig", ".gemtest", ".travis.yml", "CHANGELOG.rdoc", "CONTRIBUTING.md", "C_CODING_STYLE.rdoc", "Gemfile", "LICENSE.txt", "Manifest.txt", "README.md", "ROADMAP.md", "Rakefile", "STANDARD_RESPONSES.md", "Y_U_NO_GEMSPEC.md", "appveyor.yml", "bin/nokogiri", "build_all", "dependencies.yml", "ext/java/nokogiri/EncodingHandler.java", "ext/java/nokogiri/HtmlDocument.java", "ext/java/nokogiri/HtmlElementDescription.java", "ext/java/nokogiri/HtmlEntityLookup.java", "ext/java/nokogiri/HtmlSaxParserContext.java", "ext/java/nokogiri/HtmlSaxPushParser.java", "ext/java/nokogiri/NokogiriService.java", "ext/java/nokogiri/XmlAttr.java", "ext/java/nokogiri/XmlAttributeDecl.java", "ext/java/nokogiri/XmlCdata.java", "ext/java/nokogiri/XmlComment.java", "ext/java/nokogiri/XmlDocument.java", "ext/java/nokogiri/XmlDocumentFragment.java", "ext/java/nokogiri/XmlDtd.java", "ext/java/nokogiri/XmlElement.java", "ext/java/nokogiri/XmlElementContent.java", "ext/java/nokogiri/XmlElementDecl.java", "ext/java/nokogiri/XmlEntityDecl.java", "ext/java/nokogiri/XmlEntityReference.java", "ext/java/nokogiri/XmlNamespace.java", "ext/java/nokogiri/XmlNode.java", "ext/java/nokogiri/XmlNodeSet.java", "ext/java/nokogiri/XmlProcessingInstruction.java", "ext/java/nokogiri/XmlReader.java", "ext/java/nokogiri/XmlRelaxng.java", "ext/java/nokogiri/XmlSaxParserContext.java", "ext/java/nokogiri/XmlSaxPushParser.java", "ext/java/nokogiri/XmlSchema.java", "ext/java/nokogiri/XmlSyntaxError.java", "ext/java/nokogiri/XmlText.java", "ext/java/nokogiri/XmlXpathContext.java", "ext/java/nokogiri/XsltStylesheet.java", "ext/java/nokogiri/internals/ClosedStreamException.java", "ext/java/nokogiri/internals/HtmlDomParserContext.java", "ext/java/nokogiri/internals/IgnoreSchemaErrorsErrorHandler.java", "ext/java/nokogiri/internals/NokogiriBlockingQueueInputStream.java", "ext/java/nokogiri/internals/NokogiriDocumentCache.java", "ext/java/nokogiri/internals/NokogiriDomParser.java", "ext/java/nokogiri/internals/NokogiriEncodingReaderWrapper.java", "ext/java/nokogiri/internals/NokogiriEntityResolver.java", "ext/java/nokogiri/internals/NokogiriErrorHandler.java", "ext/java/nokogiri/internals/NokogiriHandler.java", "ext/java/nokogiri/internals/NokogiriHelpers.java", "ext/java/nokogiri/internals/NokogiriNamespaceCache.java", "ext/java/nokogiri/internals/NokogiriNamespaceContext.java", "ext/java/nokogiri/internals/NokogiriNonStrictErrorHandler.java", "ext/java/nokogiri/internals/NokogiriNonStrictErrorHandler4NekoHtml.java", "ext/java/nokogiri/internals/NokogiriStrictErrorHandler.java", "ext/java/nokogiri/internals/NokogiriXPathFunction.java", "ext/java/nokogiri/internals/NokogiriXPathFunctionResolver.java", "ext/java/nokogiri/internals/NokogiriXPathVariableResolver.java", "ext/java/nokogiri/internals/NokogiriXsltErrorListener.java", "ext/java/nokogiri/internals/ParserContext.java", "ext/java/nokogiri/internals/ReaderNode.java", "ext/java/nokogiri/internals/SaveContextVisitor.java", "ext/java/nokogiri/internals/SchemaErrorHandler.java", "ext/java/nokogiri/internals/UncloseableInputStream.java", "ext/java/nokogiri/internals/XmlDeclHandler.java", "ext/java/nokogiri/internals/XmlDomParserContext.java", "ext/java/nokogiri/internals/XmlSaxParser.java", "ext/java/nokogiri/internals/XsltExtensionFunction.java", "ext/java/nokogiri/internals/c14n/AttrCompare.java", "ext/java/nokogiri/internals/c14n/C14nHelper.java", "ext/java/nokogiri/internals/c14n/CanonicalFilter.java", "ext/java/nokogiri/internals/c14n/CanonicalizationException.java", "ext/java/nokogiri/internals/c14n/Canonicalizer.java", "ext/java/nokogiri/internals/c14n/Canonicalizer11.java", "ext/java/nokogiri/internals/c14n/Canonicalizer11_OmitComments.java", "ext/java/nokogiri/internals/c14n/Canonicalizer11_WithComments.java", "ext/java/nokogiri/internals/c14n/Canonicalizer20010315.java", "ext/java/nokogiri/internals/c14n/Canonicalizer20010315Excl.java", "ext/java/nokogiri/internals/c14n/Canonicalizer20010315ExclOmitComments.java", "ext/java/nokogiri/internals/c14n/Canonicalizer20010315ExclWithComments.java", "ext/java/nokogiri/internals/c14n/Canonicalizer20010315OmitComments.java", "ext/java/nokogiri/internals/c14n/Canonicalizer20010315WithComments.java", "ext/java/nokogiri/internals/c14n/CanonicalizerBase.java", "ext/java/nokogiri/internals/c14n/CanonicalizerPhysical.java", "ext/java/nokogiri/internals/c14n/CanonicalizerSpi.java", "ext/java/nokogiri/internals/c14n/Constants.java", "ext/java/nokogiri/internals/c14n/ElementProxy.java", "ext/java/nokogiri/internals/c14n/HelperNodeList.java", "ext/java/nokogiri/internals/c14n/IgnoreAllErrorHandler.java", "ext/java/nokogiri/internals/c14n/InclusiveNamespaces.java", "ext/java/nokogiri/internals/c14n/InvalidCanonicalizerException.java", "ext/java/nokogiri/internals/c14n/NameSpaceSymbTable.java", "ext/java/nokogiri/internals/c14n/NodeFilter.java", "ext/java/nokogiri/internals/c14n/UtfHelpper.java", "ext/java/nokogiri/internals/c14n/XMLUtils.java", "ext/nokogiri/depend", "ext/nokogiri/extconf.rb", "ext/nokogiri/html_document.c", "ext/nokogiri/html_document.h", "ext/nokogiri/html_element_description.c", "ext/nokogiri/html_element_description.h", "ext/nokogiri/html_entity_lookup.c", "ext/nokogiri/html_entity_lookup.h", "ext/nokogiri/html_sax_parser_context.c", "ext/nokogiri/html_sax_parser_context.h", "ext/nokogiri/html_sax_push_parser.c", "ext/nokogiri/html_sax_push_parser.h", "ext/nokogiri/nokogiri.c", "ext/nokogiri/nokogiri.h", "ext/nokogiri/xml_attr.c", "ext/nokogiri/xml_attr.h", "ext/nokogiri/xml_attribute_decl.c", "ext/nokogiri/xml_attribute_decl.h", "ext/nokogiri/xml_cdata.c", "ext/nokogiri/xml_cdata.h", "ext/nokogiri/xml_comment.c", "ext/nokogiri/xml_comment.h", "ext/nokogiri/xml_document.c", "ext/nokogiri/xml_document.h", "ext/nokogiri/xml_document_fragment.c", "ext/nokogiri/xml_document_fragment.h", "ext/nokogiri/xml_dtd.c", "ext/nokogiri/xml_dtd.h", "ext/nokogiri/xml_element_content.c", "ext/nokogiri/xml_element_content.h", "ext/nokogiri/xml_element_decl.c", "ext/nokogiri/xml_element_decl.h", "ext/nokogiri/xml_encoding_handler.c", "ext/nokogiri/xml_encoding_handler.h", "ext/nokogiri/xml_entity_decl.c", "ext/nokogiri/xml_entity_decl.h", "ext/nokogiri/xml_entity_reference.c", "ext/nokogiri/xml_entity_reference.h", "ext/nokogiri/xml_io.c", "ext/nokogiri/xml_io.h", "ext/nokogiri/xml_libxml2_hacks.c", "ext/nokogiri/xml_libxml2_hacks.h", "ext/nokogiri/xml_namespace.c", "ext/nokogiri/xml_namespace.h", "ext/nokogiri/xml_node.c", "ext/nokogiri/xml_node.h", "ext/nokogiri/xml_node_set.c", "ext/nokogiri/xml_node_set.h", "ext/nokogiri/xml_processing_instruction.c", "ext/nokogiri/xml_processing_instruction.h", "ext/nokogiri/xml_reader.c", "ext/nokogiri/xml_reader.h", "ext/nokogiri/xml_relax_ng.c", "ext/nokogiri/xml_relax_ng.h", "ext/nokogiri/xml_sax_parser.c", "ext/nokogiri/xml_sax_parser.h", "ext/nokogiri/xml_sax_parser_context.c", "ext/nokogiri/xml_sax_parser_context.h", "ext/nokogiri/xml_sax_push_parser.c", "ext/nokogiri/xml_sax_push_parser.h", "ext/nokogiri/xml_schema.c", "ext/nokogiri/xml_schema.h", "ext/nokogiri/xml_syntax_error.c", "ext/nokogiri/xml_syntax_error.h", "ext/nokogiri/xml_text.c", "ext/nokogiri/xml_text.h", "ext/nokogiri/xml_xpath_context.c", "ext/nokogiri/xml_xpath_context.h", "ext/nokogiri/xslt_stylesheet.c", "ext/nokogiri/xslt_stylesheet.h", "lib/isorelax.jar", "lib/jing.jar", "lib/nekodtd.jar", "lib/nekohtml.jar", "lib/nokogiri.rb", "lib/nokogiri/css.rb", "lib/nokogiri/css/node.rb", "lib/nokogiri/css/parser.rb", "lib/nokogiri/css/parser.y", "lib/nokogiri/css/parser_extras.rb", "lib/nokogiri/css/syntax_error.rb", "lib/nokogiri/css/tokenizer.rb", "lib/nokogiri/css/tokenizer.rex", "lib/nokogiri/css/xpath_visitor.rb", "lib/nokogiri/decorators/slop.rb", "lib/nokogiri/html.rb", "lib/nokogiri/html/builder.rb", "lib/nokogiri/html/document.rb", "lib/nokogiri/html/document_fragment.rb", "lib/nokogiri/html/element_description.rb", "lib/nokogiri/html/element_description_defaults.rb", "lib/nokogiri/html/entity_lookup.rb", "lib/nokogiri/html/sax/parser.rb", "lib/nokogiri/html/sax/parser_context.rb", "lib/nokogiri/html/sax/push_parser.rb", "lib/nokogiri/syntax_error.rb", "lib/nokogiri/version.rb", "lib/nokogiri/xml.rb", "lib/nokogiri/xml/attr.rb", "lib/nokogiri/xml/attribute_decl.rb", "lib/nokogiri/xml/builder.rb", "lib/nokogiri/xml/cdata.rb", "lib/nokogiri/xml/character_data.rb", "lib/nokogiri/xml/document.rb", "lib/nokogiri/xml/document_fragment.rb", "lib/nokogiri/xml/dtd.rb", "lib/nokogiri/xml/element_content.rb", "lib/nokogiri/xml/element_decl.rb", "lib/nokogiri/xml/entity_decl.rb", "lib/nokogiri/xml/namespace.rb", "lib/nokogiri/xml/node.rb", "lib/nokogiri/xml/node/save_options.rb", "lib/nokogiri/xml/node_set.rb", "lib/nokogiri/xml/notation.rb", "lib/nokogiri/xml/parse_options.rb", "lib/nokogiri/xml/pp.rb", "lib/nokogiri/xml/pp/character_data.rb", "lib/nokogiri/xml/pp/node.rb", "lib/nokogiri/xml/processing_instruction.rb", "lib/nokogiri/xml/reader.rb", "lib/nokogiri/xml/relax_ng.rb", "lib/nokogiri/xml/sax.rb", "lib/nokogiri/xml/sax/document.rb", "lib/nokogiri/xml/sax/parser.rb", "lib/nokogiri/xml/sax/parser_context.rb", "lib/nokogiri/xml/sax/push_parser.rb", "lib/nokogiri/xml/schema.rb", "lib/nokogiri/xml/searchable.rb", "lib/nokogiri/xml/syntax_error.rb", "lib/nokogiri/xml/text.rb", "lib/nokogiri/xml/xpath.rb", "lib/nokogiri/xml/xpath/syntax_error.rb", "lib/nokogiri/xml/xpath_context.rb", "lib/nokogiri/xslt.rb", "lib/nokogiri/xslt/stylesheet.rb", "lib/serializer.jar", "lib/xalan.jar", "lib/xercesImpl.jar", "lib/xml-apis.jar", "lib/xsd/xmlparser/nokogiri.rb", "patches/sort-patches-by-date", "suppressions/README.txt", "suppressions/nokogiri_ree-1.8.7.358.supp", "suppressions/nokogiri_ruby-1.8.7.370.supp", "suppressions/nokogiri_ruby-1.9.2.320.supp", "suppressions/nokogiri_ruby-1.9.3.327.supp", "tasks/test.rb", "test/css/test_nthiness.rb", "test/css/test_parser.rb", "test/css/test_tokenizer.rb", "test/css/test_xpath_visitor.rb", "test/decorators/test_slop.rb", "test/files/2ch.html", "test/files/GH_1042.html", "test/files/address_book.rlx", "test/files/address_book.xml", "test/files/atom.xml", "test/files/bar/bar.xsd", "test/files/bogus.xml", "test/files/dont_hurt_em_why.xml", "test/files/encoding.html", "test/files/encoding.xhtml", "test/files/exslt.xml", "test/files/exslt.xslt", "test/files/foo/foo.xsd", "test/files/metacharset.html", "test/files/namespace_pressure_test.xml", "test/files/noencoding.html", "test/files/po.xml", "test/files/po.xsd", "test/files/saml/saml20assertion_schema.xsd", "test/files/saml/saml20protocol_schema.xsd", "test/files/saml/xenc_schema.xsd", "test/files/saml/xmldsig_schema.xsd", "test/files/shift_jis.html", "test/files/shift_jis.xml", "test/files/shift_jis_no_charset.html", "test/files/slow-xpath.xml", "test/files/snuggles.xml", "test/files/staff.dtd", "test/files/staff.xml", "test/files/staff.xslt", "test/files/test_document_url/bar.xml", "test/files/test_document_url/document.dtd", "test/files/test_document_url/document.xml", "test/files/tlm.html", "test/files/to_be_xincluded.xml", "test/files/valid_bar.xml", "test/files/xinclude.xml", "test/helper.rb", "test/html/sax/test_parser.rb", "test/html/sax/test_parser_context.rb", "test/html/sax/test_push_parser.rb", "test/html/test_builder.rb", "test/html/test_document.rb", "test/html/test_document_encoding.rb", "test/html/test_document_fragment.rb", "test/html/test_element_description.rb", "test/html/test_named_characters.rb", "test/html/test_node.rb", "test/html/test_node_encoding.rb", "test/namespaces/test_additional_namespaces_in_builder_doc.rb", "test/namespaces/test_namespaces_aliased_default.rb", "test/namespaces/test_namespaces_in_builder_doc.rb", "test/namespaces/test_namespaces_in_cloned_doc.rb", "test/namespaces/test_namespaces_in_created_doc.rb", "test/namespaces/test_namespaces_in_parsed_doc.rb", "test/namespaces/test_namespaces_preservation.rb", "test/test_convert_xpath.rb", "test/test_css_cache.rb", "test/test_encoding_handler.rb", "test/test_memory_leak.rb", "test/test_nokogiri.rb", "test/test_reader.rb", "test/test_soap4r_sax.rb", "test/test_xslt_transforms.rb", "test/xml/node/test_save_options.rb", "test/xml/node/test_subclass.rb", "test/xml/sax/test_parser.rb", "test/xml/sax/test_parser_context.rb", "test/xml/sax/test_push_parser.rb", "test/xml/test_attr.rb", "test/xml/test_attribute_decl.rb", "test/xml/test_builder.rb", "test/xml/test_c14n.rb", "test/xml/test_cdata.rb", "test/xml/test_comment.rb", "test/xml/test_document.rb", "test/xml/test_document_encoding.rb", "test/xml/test_document_fragment.rb", "test/xml/test_dtd.rb", "test/xml/test_dtd_encoding.rb", "test/xml/test_element_content.rb", "test/xml/test_element_decl.rb", "test/xml/test_entity_decl.rb", "test/xml/test_entity_reference.rb", "test/xml/test_namespace.rb", "test/xml/test_node.rb", "test/xml/test_node_attributes.rb", "test/xml/test_node_encoding.rb", "test/xml/test_node_inheritance.rb", "test/xml/test_node_reparenting.rb", "test/xml/test_node_set.rb", "test/xml/test_parse_options.rb", "test/xml/test_processing_instruction.rb", "test/xml/test_reader_encoding.rb", "test/xml/test_relax_ng.rb", "test/xml/test_schema.rb", "test/xml/test_syntax_error.rb", "test/xml/test_text.rb", "test/xml/test_unparented_node.rb", "test/xml/test_xinclude.rb", "test/xml/test_xpath.rb", "test/xslt/test_custom_functions.rb", "test/xslt/test_exception_handling.rb", "test_all"]
  s.homepage = "http://nokogiri.org"
  s.licenses = ["MIT"]
  s.rdoc_options = ["--main", "README.md"]
  s.rubygems_version = "2.4.8"
  s.summary = "Nokogiri (\u{92f8}) is an HTML, XML, SAX, and Reader parser"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_development_dependency(%q<hoe-bundler>, ["~> 1.2.0"])
      s.add_development_dependency(%q<hoe-debugging>, ["~> 1.2.1"])
      s.add_development_dependency(%q<hoe-gemspec>, ["~> 1.0.0"])
      s.add_development_dependency(%q<hoe-git>, ["~> 1.6.0"])
      s.add_development_dependency(%q<minitest>, ["~> 5.8.4"])
      s.add_development_dependency(%q<rake>, ["~> 10.5.0"])
      s.add_development_dependency(%q<rake-compiler>, ["~> 0.9.2"])
      s.add_development_dependency(%q<rake-compiler-dock>, ["~> 0.5.1"])
      s.add_development_dependency(%q<racc>, ["~> 1.4.14"])
      s.add_development_dependency(%q<rexical>, ["~> 1.0.5"])
      s.add_development_dependency(%q<hoe>, ["~> 3.14"])
    else
      s.add_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_dependency(%q<hoe-bundler>, ["~> 1.2.0"])
      s.add_dependency(%q<hoe-debugging>, ["~> 1.2.1"])
      s.add_dependency(%q<hoe-gemspec>, ["~> 1.0.0"])
      s.add_dependency(%q<hoe-git>, ["~> 1.6.0"])
      s.add_dependency(%q<minitest>, ["~> 5.8.4"])
      s.add_dependency(%q<rake>, ["~> 10.5.0"])
      s.add_dependency(%q<rake-compiler>, ["~> 0.9.2"])
      s.add_dependency(%q<rake-compiler-dock>, ["~> 0.5.1"])
      s.add_dependency(%q<racc>, ["~> 1.4.14"])
      s.add_dependency(%q<rexical>, ["~> 1.0.5"])
      s.add_dependency(%q<hoe>, ["~> 3.14"])
    end
  else
    s.add_dependency(%q<rdoc>, ["~> 4.0"])
    s.add_dependency(%q<hoe-bundler>, ["~> 1.2.0"])
    s.add_dependency(%q<hoe-debugging>, ["~> 1.2.1"])
    s.add_dependency(%q<hoe-gemspec>, ["~> 1.0.0"])
    s.add_dependency(%q<hoe-git>, ["~> 1.6.0"])
    s.add_dependency(%q<minitest>, ["~> 5.8.4"])
    s.add_dependency(%q<rake>, ["~> 10.5.0"])
    s.add_dependency(%q<rake-compiler>, ["~> 0.9.2"])
    s.add_dependency(%q<rake-compiler-dock>, ["~> 0.5.1"])
    s.add_dependency(%q<racc>, ["~> 1.4.14"])
    s.add_dependency(%q<rexical>, ["~> 1.0.5"])
    s.add_dependency(%q<hoe>, ["~> 3.14"])
  end
end
