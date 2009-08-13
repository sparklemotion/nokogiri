package nokogiri;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
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

    public static void init(Ruby ruby) {
        RubyModule nokogiri = ruby.defineModule("Nokogiri");
        RubyModule xml = nokogiri.defineModuleUnder("XML");
        RubyModule html = nokogiri.defineModuleUnder("HTML");

        RubyClass node = xml.defineClassUnder("Node", ruby.getObject(), XML_NODE_ALLOCATOR);
        
        init_xml_node(ruby, node);
        init_xml_attr(ruby, xml, node);
        init_xml_comment(ruby, xml, node);
        RubyClass document = init_xml_document(ruby, xml, node);
        init_html_document(ruby, html, document);
        init_xml_document_fragment(ruby, xml, node);
        init_xml_dtd(ruby, xml, node);
        init_xml_element(ruby, xml, node);
        init_xml_namespace(ruby, xml);
        init_xml_node_set(ruby, xml);
        init_xml_reader(ruby, xml);
        RubyClass xmlSaxParser = init_xml_sax_parser(ruby, xml);
        init_html_sax_parser(ruby, html, xmlSaxParser);
        RubyClass schema = init_xml_schema(ruby,xml);
        init_xml_syntax_error(ruby, xml, nokogiri);
        RubyClass text = init_xml_text(ruby, xml, node);
        init_xml_cdata(ruby, xml, text);
        init_xml_xpath(ruby, xml);
        init_xml_xpath_context(ruby, xml);
        init_xslt_stylesheet(ruby, nokogiri);
    }

    public static void init_html_document(Ruby ruby, RubyModule html, RubyClass document) {
        RubyModule htmlDoc = html.defineOrGetClassUnder("Document", document);

        htmlDoc.defineAnnotatedMethods(HtmlDocument.class);
    }

    public static void init_html_sax_parser(Ruby ruby, RubyModule html, RubyClass xmlSaxParser) {
        RubyModule htmlSax = html.defineModuleUnder("SAX");
        // Nokogiri::HTML::SAX::Parser is defined by nokogiri/html/sax/parser.rb
        RubyClass saxParser = htmlSax.defineClassUnder("Parser", xmlSaxParser, HTML_SAXPARSER_ALLOCATOR);
        saxParser.defineAnnotatedMethods(HtmlSaxParser.class);
    }

    public static void init_xml_attr(Ruby ruby, RubyModule xml, RubyClass node){
        RubyClass attr = xml.defineClassUnder("Attr", node, XML_ATTR_ALLOCATOR);

        attr.defineAnnotatedMethods(XmlAttr.class);
    }

    public static void init_xml_cdata(Ruby ruby, RubyModule xml, RubyClass text) {
        RubyModule cdata = xml.defineClassUnder("CDATA", text, XML_CDATA_ALLOCATOR);

        cdata.defineAnnotatedMethods(XmlCdata.class);
    }

    public static void init_xml_comment(Ruby ruby, RubyModule xml, RubyClass node) {
        RubyModule comment = xml.defineClassUnder("Comment", node, XML_COMMENT_ALLOCATOR);

        comment.defineAnnotatedMethods(XmlComment.class);
    }

    public static RubyClass init_xml_document(Ruby ruby, RubyModule xml, RubyClass node) {
        RubyClass document = xml.defineClassUnder("Document", node, XML_DOCUMENT_ALLOCATOR);

        document.defineAnnotatedMethods(XmlDocument.class);

        return document;
    }

    public static void init_xml_document_fragment(Ruby ruby, RubyModule xml, RubyClass node) {
        RubyClass documentFragment = xml.defineClassUnder("DocumentFragment", node, XML_DOCUMENT_FRAGMENT_ALLOCATOR);

        documentFragment.defineAnnotatedMethods(XmlDocumentFragment.class);
    }

    public static void init_xml_dtd(Ruby ruby, RubyModule xml, RubyClass node) {
        RubyClass dtd = xml.defineClassUnder("DTD", node, XML_DTD_ALLOCATOR);

        dtd.defineAnnotatedMethods(XmlDtd.class);
    }

    public static void init_xml_element(Ruby ruby, RubyModule xml, RubyClass node) {
        RubyClass element = xml.defineClassUnder("Element", node, XML_ELEMENT_ALLOCATOR);

        element.defineAnnotatedMethods(XmlElement.class);
    }

    public static void init_xml_namespace(Ruby ruby, RubyModule xml) {
        RubyClass namespace = xml.defineClassUnder("Namespace", ruby.getObject(), XML_NAMESPACE_ALLOCATOR);

        namespace.defineAnnotatedMethods(XmlNamespace.class);
    }

    public static void init_xml_node(Ruby ruby, RubyClass node) {
        node.defineAnnotatedMethods(XmlNode.class);
    }

    public static void init_xml_node_set(Ruby ruby, RubyModule xml) {
        RubyModule nodeSet = xml.defineClassUnder("NodeSet", ruby.getObject(), XML_NODESET_ALLOCATOR);

        nodeSet.defineAnnotatedMethods(XmlNodeSet.class);
    }

    public static void init_xml_reader(Ruby ruby, RubyModule xml) {
        RubyClass reader = xml.defineClassUnder("Reader", ruby.getObject(), XML_READER_ALLOCATOR);

        reader.defineAnnotatedMethods(XmlReader.class);
    }

    public static RubyClass init_xml_sax_parser(Ruby ruby, RubyModule xml) {
        RubyModule xmlSax = xml.defineModuleUnder("SAX");
        // Nokogiri::XML::SAX::Parser is defined by nokogiri/xml/sax/parser.rb
        RubyClass saxParser = xmlSax.defineClassUnder("Parser", ruby.getObject(), XML_SAXPARSER_ALLOCATOR);
        saxParser.defineAnnotatedMethods(XmlSaxParser.class);

        return saxParser;
    }

    public static RubyClass init_xml_schema(Ruby ruby, RubyModule xml) {
         RubyClass schema = xml.defineClassUnder("Schema", ruby.getObject(),
                 XML_SCHEMA_ALLOCATOR);

        schema.defineAnnotatedMethods(XmlSchema.class);

        return schema;
    }

    public static void init_xml_syntax_error(Ruby ruby, RubyModule xml, RubyModule nokogiri) {
        RubyClass syntaxErrorMommy = nokogiri.defineClassUnder("SyntaxError", ruby.getStandardError(), ruby.getStandardError().getAllocator());
        RubyClass syntaxError = xml.defineClassUnder("SyntaxError", syntaxErrorMommy, XML_SYNTAXERROR_ALLOCATOR);

        syntaxError.defineAnnotatedMethods(XmlSyntaxError.class);
    }

    public static RubyClass init_xml_text(Ruby ruby, RubyModule xml, RubyClass node) {
        RubyClass text = xml.defineClassUnder("Text", node, XML_TEXT_ALLOCATOR);

        text.defineAnnotatedMethods(XmlText.class);

        return text;
    }

    public static void init_xml_xpath(Ruby ruby, RubyModule xml) {
        RubyClass xpathContext = xml.defineClassUnder("XPath", ruby.getObject(), XML_XPATH_ALLOCATOR);

        xpathContext.defineAnnotatedMethods(XmlXpath.class);
    }

    public static void init_xml_xpath_context(Ruby ruby, RubyModule xml) {
        RubyClass xpathContext = xml.defineClassUnder("XPathContext", ruby.getObject(), XML_XPATHCONTEXT_ALLOCATOR);

        xpathContext.defineAnnotatedMethods(XmlXpathContext.class);
    }

    public static void init_xslt_stylesheet(Ruby ruby, RubyModule nokogiri) {
        RubyModule xslt = nokogiri.defineModuleUnder("XSLT");
        RubyClass stylesheet = xslt.defineClassUnder("Sylesheet", ruby.getObject(), XSLT_STYLESHEET_ALLOCATOR);

        stylesheet.defineAnnotatedMethods(XsltStylesheet.class);
    }

    private static ObjectAllocator HTML_DOCUMENT_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw runtime.newNotImplementedError("not implemented");
        }
    };

    private static ObjectAllocator HTML_SAXPARSER_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new HtmlSaxParser(runtime, klazz);
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

    private static ObjectAllocator XML_SAXPARSER_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new XmlSaxParser(runtime, klazz);
        }
    };

    private static ObjectAllocator XML_SCHEMA_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new XmlSchema(runtime, klazz);
        }
    };

    private static ObjectAllocator XML_SYNTAXERROR_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw runtime.newNotImplementedError("not implemented");
        }
    };

    private static ObjectAllocator XML_TEXT_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw runtime.newNotImplementedError("not implemented");
        }
    };

    private static ObjectAllocator XML_XPATH_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw new UnsupportedOperationException("Not supported yet.");
        }
    };

    private static ObjectAllocator XML_XPATHCONTEXT_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw runtime.newNotImplementedError("not implemented");
        }
    };

    private static ObjectAllocator XSLT_STYLESHEET_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw new UnsupportedOperationException("Not supported yet.");
        }
    };
}
