package nokogiri;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyModule;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.BasicLibraryService;

/**
 *
 * @author headius
 */
public class NokogiriService implements BasicLibraryService{

    public boolean basicLoad(Ruby ruby) {
        init(ruby);
        return true;
    }

    private void init(Ruby ruby) {
        RubyModule nokogiri = ruby.defineModule("Nokogiri");
        RubyModule xmlModule = nokogiri.defineModuleUnder("XML");
        RubyModule xmlSaxModule = xmlModule.defineModuleUnder("SAX");
        RubyModule htmlModule = nokogiri.defineModuleUnder("HTML");
        RubyModule htmlSaxModule = htmlModule.defineModuleUnder("SAX");
        RubyModule xsltModule = nokogiri.defineModuleUnder("XSLT");

        createNokogiriModule(ruby, nokogiri);
        createSyntaxErrors(ruby, nokogiri, xmlModule);
        RubyClass xmlNode = createXmlModule(ruby, xmlModule);
        createHtmlModule(ruby, htmlModule);
        createDocuments(ruby, xmlModule, htmlModule, xmlNode);
        createSaxModule(ruby, xmlSaxModule, htmlSaxModule);
        createXsltModule(ruby, xsltModule);
    }
    
    private void createNokogiriModule(Ruby ruby, RubyModule nokogiri) {;
        RubyClass encHandler = nokogiri.defineClassUnder("EncodingHandler", ruby.getObject(), ENCODING_HANDLER_ALLOCATOR);
        encHandler.defineAnnotatedMethods(EncodingHandler.class);
    }
    
    private void createSyntaxErrors(Ruby ruby, RubyModule nokogiri, RubyModule xmlModule) {
        RubyClass syntaxError = nokogiri.defineClassUnder("SyntaxError", ruby.getStandardError(), ruby.getStandardError().getAllocator());
        RubyClass xmlSyntaxError = xmlModule.defineClassUnder("SyntaxError", syntaxError, XML_SYNTAXERROR_ALLOCATOR);
        xmlSyntaxError.defineAnnotatedMethods(XmlSyntaxError.class);
    }
    
    private RubyClass createXmlModule(Ruby ruby, RubyModule xmlModule) {
        RubyClass node = xmlModule.defineClassUnder("Node", ruby.getObject(), XML_NODE_ALLOCATOR);
        node.defineAnnotatedMethods(XmlNode.class);
        
        RubyClass attr = xmlModule.defineClassUnder("Attr", node, XML_ATTR_ALLOCATOR);
        attr.defineAnnotatedMethods(XmlAttr.class);
        
        RubyClass attrDecl = xmlModule.defineClassUnder("AttributeDecl", node, XML_ATTRIBUTE_DECL_ALLOCATOR);
        attrDecl.defineAnnotatedMethods(XmlAttributeDecl.class);
        
        RubyClass characterData = xmlModule.defineClassUnder("CharacterData", node, null);
        
        RubyClass comment = xmlModule.defineClassUnder("Comment", characterData, XML_COMMENT_ALLOCATOR);
        comment.defineAnnotatedMethods(XmlComment.class);
        
        RubyClass text = xmlModule.defineClassUnder("Text", characterData, XML_TEXT_ALLOCATOR);
        text.defineAnnotatedMethods(XmlText.class);
        
        RubyModule cdata = xmlModule.defineClassUnder("CDATA", text, XML_CDATA_ALLOCATOR);
        cdata.defineAnnotatedMethods(XmlCdata.class);
        
        RubyClass dtd = xmlModule.defineClassUnder("DTD", node, XML_DTD_ALLOCATOR);
        dtd.defineAnnotatedMethods(XmlDtd.class);

        RubyClass documentFragment = xmlModule.defineClassUnder("DocumentFragment", node, XML_DOCUMENT_FRAGMENT_ALLOCATOR);
        documentFragment.defineAnnotatedMethods(XmlDocumentFragment.class);
        
        RubyClass element = xmlModule.defineClassUnder("Element", node, XML_ELEMENT_ALLOCATOR);
        element.defineAnnotatedMethods(XmlElement.class);
        
        RubyClass elementContent = xmlModule.defineClassUnder("ElementContent", ruby.getObject(), XML_ELEMENT_CONTENT_ALLOCATOR);
        elementContent.defineAnnotatedMethods(XmlElementContent.class);
        
        RubyClass elementDecl = xmlModule.defineClassUnder("ElementDecl", node, XML_ELEMENT_DECL_ALLOCATOR);
        elementDecl.defineAnnotatedMethods(XmlElementDecl.class);
        
        RubyClass entityDecl = xmlModule.defineClassUnder("EntityDecl", node, XML_ENTITY_DECL_ALLOCATOR);
        entityDecl.defineAnnotatedMethods(XmlEntityDecl.class);
        entityDecl.defineConstant("INTERNAL_GENERAL", RubyFixnum.newFixnum(ruby, XmlEntityDecl.INTERNAL_GENERAL));
        entityDecl.defineConstant("EXTERNAL_GENERAL_PARSED", RubyFixnum.newFixnum(ruby, XmlEntityDecl.EXTERNAL_GENERAL_PARSED));
        entityDecl.defineConstant("EXTERNAL_GENERAL_UNPARSED", RubyFixnum.newFixnum(ruby, XmlEntityDecl.EXTERNAL_GENERAL_UNPARSED));
        entityDecl.defineConstant("INTERNAL_PARAMETER", RubyFixnum.newFixnum(ruby, XmlEntityDecl.INTERNAL_PARAMETER));
        entityDecl.defineConstant("EXTERNAL_PARAMETER", RubyFixnum.newFixnum(ruby, XmlEntityDecl.EXTERNAL_PARAMETER));
        entityDecl.defineConstant("INTERNAL_PREDEFINED", RubyFixnum.newFixnum(ruby, XmlEntityDecl.INTERNAL_PREDEFINED));
        
        RubyClass entref = xmlModule.defineClassUnder("EntityReference", node, XML_ENTITY_REFERENCE_ALLOCATOR);
        entref.defineAnnotatedMethods(XmlEntityReference.class);
        
        RubyClass namespace = xmlModule.defineClassUnder("Namespace", ruby.getObject(), XML_NAMESPACE_ALLOCATOR);
        namespace.defineAnnotatedMethods(XmlNamespace.class);
        
        RubyClass nodeSet = xmlModule.defineClassUnder("NodeSet", ruby.getObject(), XML_NODESET_ALLOCATOR);
        nodeSet.defineAnnotatedMethods(XmlNodeSet.class);
        
        RubyClass pi = xmlModule.defineClassUnder("ProcessingInstruction", node, XML_PROCESSING_INSTRUCTION_ALLOCATOR);
        pi.defineAnnotatedMethods(XmlProcessingInstruction.class);
        
        RubyClass reader = xmlModule.defineClassUnder("Reader", ruby.getObject(), XML_READER_ALLOCATOR);
        reader.defineAnnotatedMethods(XmlReader.class);
        
        RubyClass schema = xmlModule.defineClassUnder("Schema", ruby.getObject(), XML_SCHEMA_ALLOCATOR);
        schema.defineAnnotatedMethods(XmlSchema.class);

        RubyClass relaxng = xmlModule.defineClassUnder("RelaxNG", schema, XML_RELAXNG_ALLOCATOR);
        relaxng.defineAnnotatedMethods(XmlRelaxng.class);
        
        RubyClass xpathContext = xmlModule.defineClassUnder("XPathContext", ruby.getObject(), XML_XPATHCONTEXT_ALLOCATOR);
        xpathContext.defineAnnotatedMethods(XmlXpathContext.class);
        
        return node;
    }

    private void createHtmlModule(Ruby ruby, RubyModule htmlModule) {
        RubyClass htmlElemDesc = htmlModule.defineClassUnder("ElementDescription", ruby.getObject(), HTML_ELEMENT_DESCRIPTION_ALLOCATOR);
        htmlElemDesc.defineAnnotatedMethods(HtmlElementDescription.class);
        
        RubyClass htmlEntityLookup = htmlModule.defineClassUnder("EntityLookup", ruby.getObject(), HTML_ENTITY_LOOKUP_ALLOCATOR);
        htmlEntityLookup.defineAnnotatedMethods(HtmlEntityLookup.class);
    }
    
    private void createDocuments(Ruby ruby, RubyModule xmlModule, RubyModule htmlModule, RubyClass node) {
        RubyClass xmlDocument = xmlModule.defineClassUnder("Document", node, XML_DOCUMENT_ALLOCATOR);
        xmlDocument.defineAnnotatedMethods(XmlDocument.class);
        
        //RubyModule htmlDoc = html.defineOrGetClassUnder("Document", document);
        RubyModule htmlDocument = htmlModule.defineClassUnder("Document", xmlDocument, HTML_DOCUMENT_ALLOCATOR);
        htmlDocument.defineAnnotatedMethods(HtmlDocument.class);
    }
    
    private void createSaxModule(Ruby ruby, RubyModule xmlSaxModule, RubyModule htmlSaxModule) {
        RubyClass xmlSaxParserContext = xmlSaxModule.defineClassUnder("ParserContext", ruby.getObject(), XML_SAXPARSER_ALLOCATOR);
        xmlSaxParserContext.defineAnnotatedMethods(XmlSaxParserContext.class);
        
        RubyClass xmlSaxPushParser = xmlSaxModule.defineClassUnder("PushParser", ruby.getObject(), XML_SAXPUSHPARSER_ALLOCATOR);
        xmlSaxPushParser.defineAnnotatedMethods(XmlSaxPushParser.class);
        
        RubyClass htmlSaxParserContext = htmlSaxModule.defineClassUnder("ParserContext", xmlSaxParserContext, HTML_SAXPARSER_ALLOCATOR);
        htmlSaxParserContext.defineAnnotatedMethods(HtmlSaxParserContext.class);
    }
    
    private void createXsltModule(Ruby ruby, RubyModule xsltModule) {
        RubyClass stylesheet = xsltModule.defineClassUnder("Stylesheet", ruby.getObject(), XSLT_STYLESHEET_ALLOCATOR);
        stylesheet.defineAnnotatedMethods(XsltStylesheet.class);
    }

    private static ObjectAllocator ENCODING_HANDLER_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new EncodingHandler(runtime, klazz, "");
        }
    };

    private static ObjectAllocator HTML_DOCUMENT_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new HtmlDocument(runtime, klazz);
        }
    };

    private static ObjectAllocator HTML_SAXPARSER_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new HtmlSaxParserContext(runtime, klazz);
        }
    };

    private static ObjectAllocator HTML_ELEMENT_DESCRIPTION_ALLOCATOR =
        new ObjectAllocator() {
            public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
                return new HtmlElementDescription(runtime, klazz);
            }
        };

    private static ObjectAllocator HTML_ENTITY_LOOKUP_ALLOCATOR =
        new ObjectAllocator() {
            public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
                return new HtmlEntityLookup(runtime, klazz);
            }
        };

    private static ObjectAllocator XML_ATTR_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz){
            return new XmlAttr(runtime, klazz);
        }
    };

    private static ObjectAllocator XML_CDATA_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw runtime.newNotImplementedError("not implemented");
        }
    };

    private static ObjectAllocator XML_COMMENT_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new XmlComment(runtime, klazz);
        }
    };

    private static ObjectAllocator XML_PROCESSING_INSTRUCTION_ALLOCATOR =
        new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw runtime.newNotImplementedError("not implemented");
        }
    };

    private static ObjectAllocator XML_DOCUMENT_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw runtime.newNotImplementedError("not implemented");
        }
    };

    private static ObjectAllocator XML_DOCUMENT_FRAGMENT_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new XmlDocumentFragment(runtime, klazz);
        }
    };

    private static ObjectAllocator XML_DTD_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new XmlDtd(runtime, klazz);
        }
    };

    private static ObjectAllocator XML_ELEMENT_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new XmlElement(runtime, klazz);
        }
    };

    private static ObjectAllocator XML_ENTITY_REFERENCE_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new XmlEntityReference(runtime, klazz);
        }
    };

    private static ObjectAllocator XML_NAMESPACE_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new XmlNamespace(runtime, klazz);
        }
    };

    private static ObjectAllocator XML_NODE_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new XmlNode(runtime, klazz);
        }
    };

    private static ObjectAllocator XML_NODESET_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new XmlNodeSet(runtime, klazz, RubyArray.newEmptyArray(runtime));
        }
    };

    private static ObjectAllocator XML_READER_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new XmlReader(runtime, klazz);
        }
    };

    private static ObjectAllocator XML_ATTRIBUTE_DECL_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new XmlAttributeDecl(runtime, klazz);
        }
    };

    private static ObjectAllocator XML_ELEMENT_DECL_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new XmlElementDecl(runtime, klazz);
        }
    };

    private static ObjectAllocator XML_ENTITY_DECL_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new XmlEntityDecl(runtime, klazz);
        }
    };

    private static ObjectAllocator XML_ELEMENT_CONTENT_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw runtime.newNotImplementedError("not implemented");
        }
    };

    private static ObjectAllocator XML_RELAXNG_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new XmlRelaxng(runtime, klazz);
        }
    };

    private static ObjectAllocator XML_SAXPARSER_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new XmlSaxParserContext(runtime, klazz);
        }
    };

    private static ObjectAllocator XML_SAXPUSHPARSER_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new XmlSaxPushParser(runtime, klazz);
        }
    };

    private static ObjectAllocator XML_SCHEMA_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new XmlSchema(runtime, klazz);
        }
    };

    private static ObjectAllocator XML_SYNTAXERROR_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new XmlSyntaxError(runtime, klazz);
        }
    };

    private static ObjectAllocator XML_TEXT_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new XmlText(runtime, klazz);
        }
    };

    private static ObjectAllocator XML_XPATHCONTEXT_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw runtime.newNotImplementedError("not implemented");
        }
    };

    private static ObjectAllocator XSLT_STYLESHEET_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new XsltStylesheet(runtime, klazz);
        }
    };
}
