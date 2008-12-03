/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package nokogiri;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.Visibility;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.BasicLibraryService;

/**
 *
 * @author headius
 */
public class NokogiriJavaService implements BasicLibraryService{
    public boolean basicLoad(Ruby ruby) {
        init(ruby);
        return true;
    }

    public static void init(Ruby ruby) {
        RubyModule nokogiri = ruby.defineModule("Nokogiri");
        RubyModule xml = nokogiri.defineModuleUnder("XML");
        RubyModule html = nokogiri.defineModuleUnder("HTML");

        RubyClass node = xml.defineClassUnder("Node", ruby.getObject(), XML_NODE_ALLOCATOR);
        
        init_xml_document(ruby, xml, node);
        init_html_document(ruby, html, node);
        init_xml_node(ruby, node);
        RubyClass text = init_xml_text(ruby, xml, node);
        init_xml_cdata(ruby, xml, text);
        init_xml_comment(ruby, xml, node);
        init_xml_node_set(ruby, xml);
        init_xml_xpath_context(ruby, xml);
        init_xml_xpath(ruby, xml);
        init_xml_sax_parser(ruby, xml);
        init_xml_reader(ruby, xml);
        init_xml_dtd(ruby, xml, node);
        init_html_sax_parser(ruby, html);
        init_xslt_stylesheet(ruby, nokogiri);
        init_xml_syntax_error(ruby, xml);
    }

    public static void init_xml_document(Ruby ruby, RubyModule xml, RubyClass node) {
        RubyClass document = xml.defineClassUnder("Document", node, XML_DOCUMENT_ALLOCATOR);

        document.defineAnnotatedMethods(XmlDocument.class);
        document.undefineMethod("parent");
    }

    public static void init_html_document(Ruby ruby, RubyModule html, RubyClass node) {
        RubyModule htmlDoc = html.defineOrGetClassUnder("Document", node);

        htmlDoc.defineAnnotatedMethods(HtmlDocument.class);
    }

    public static void init_xml_node(Ruby ruby, RubyClass node) {
        node.defineAnnotatedMethods(XmlNode.class);
    }

    public static RubyClass init_xml_text(Ruby ruby, RubyModule xml, RubyClass node) {
        RubyClass text = xml.defineClassUnder("Text", node, XML_TEXT_ALLOCATOR);

        text.defineAnnotatedMethods(XmlText.class);

        return text;
    }

    public static void init_xml_cdata(Ruby ruby, RubyModule xml, RubyClass text) {
        RubyModule cdata = xml.defineClassUnder("CDATA", text, XML_CDATA_ALLOCATOR);

        cdata.defineAnnotatedMethods(XmlCdata.class);
    }

    public static void init_xml_comment(Ruby ruby, RubyModule xml, RubyClass node) {
        RubyModule comment = xml.defineClassUnder("Comment", node, XML_COMMENT_ALLOCATOR);

        comment.defineAnnotatedMethods(XmlComment.class);
    }

    public static void init_xml_node_set(Ruby ruby, RubyModule xml) {
        RubyModule nodeSet = xml.defineClassUnder("NodeSet", ruby.getObject(), XML_NODESET_ALLOCATOR);

        nodeSet.defineAnnotatedMethods(XmlNodeSet.class);
    }

    public static void init_xml_xpath_context(Ruby ruby, RubyModule xml) {
        RubyClass xpathContext = xml.defineClassUnder("XPathContext", ruby.getObject(), XML_XPATHCONTEXT_ALLOCATOR);

        xpathContext.defineAnnotatedMethods(XpathContext.class);
    }

    public static void init_xml_xpath(Ruby ruby, RubyModule xml) {
        RubyClass xpathContext = xml.defineClassUnder("XPath", ruby.getObject(), XML_XPATH_ALLOCATOR);

        xpathContext.defineAnnotatedMethods(Xpath.class);
    }

    public static void init_xml_sax_parser(Ruby ruby, RubyModule xml) {
        RubyModule xmlSax = xml.defineModuleUnder("SAX");
        RubyClass saxParser = xmlSax.defineClassUnder("Parser", ruby.getObject(), XML_SAXPARSER_ALLOCATOR);

        saxParser.defineAnnotatedMethods(SaxParser.class);
    }

    public static void init_xml_reader(Ruby ruby, RubyModule xml) {
        RubyClass reader = xml.defineClassUnder("Reader", ruby.getObject(), XML_READER_ALLOCATOR);

        reader.defineAnnotatedMethods(Reader.class);
    }

    public static void init_xml_dtd(Ruby ruby, RubyModule xml, RubyClass node) {
        RubyClass xpathContext = xml.defineClassUnder("DTD", node, XML_DTD_ALLOCATOR);

        xpathContext.defineAnnotatedMethods(DTD.class);
    }

    public static void init_html_sax_parser(Ruby ruby, RubyModule html) {
        RubyModule htmlSax = html.defineModuleUnder("SAX");
        RubyClass saxParser = htmlSax.defineClassUnder("Parser", ruby.getObject(), HTML_SAXPARSER_ALLOCATOR);

        saxParser.setAllocator(HTML_SAXPARSER_ALLOCATOR);
        saxParser.defineAnnotatedMethods(HtmlSaxParser.class);
    }

    public static void init_xslt_stylesheet(Ruby ruby, RubyModule nokogiri) {
        RubyModule xslt = nokogiri.defineModuleUnder("XSLT");
        RubyClass stylesheet = xslt.defineClassUnder("Sylesheet", ruby.getObject(), XSLT_STYLESHEET_ALLOCATOR);

        stylesheet.defineAnnotatedMethods(XsltStylesheet.class);
    }

    public static void init_xml_syntax_error(Ruby ruby, RubyModule xml) {
        RubyClass syntaxError = xml.defineClassUnder("SyntaxError", ruby.getSyntaxError(), XML_SYNTAXERROR_ALLOCATOR);

        syntaxError.defineAnnotatedMethods(SyntaxError.class);
    }

    private static ObjectAllocator XML_NODE_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw new UnsupportedOperationException("Not supported yet.");
        }
    };

    private static ObjectAllocator XML_TEXT_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw new UnsupportedOperationException("Not supported yet.");
        }
    };

    private static ObjectAllocator XML_CDATA_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw new UnsupportedOperationException("Not supported yet.");
        }
    };

    private static ObjectAllocator XML_COMMENT_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw new UnsupportedOperationException("Not supported yet.");
        }
    };

    private static ObjectAllocator XML_NODESET_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw new UnsupportedOperationException("Not supported yet.");
        }
    };

    private static ObjectAllocator XML_XPATHCONTEXT_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw new UnsupportedOperationException("Not supported yet.");
        }
    };

    private static ObjectAllocator XML_XPATH_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw new UnsupportedOperationException("Not supported yet.");
        }
    };

    private static ObjectAllocator XML_READER_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw new UnsupportedOperationException("Not supported yet.");
        }
    };

    private static ObjectAllocator XML_DTD_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw new UnsupportedOperationException("Not supported yet.");
        }
    };

    private static ObjectAllocator XML_SAXPARSER_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw new UnsupportedOperationException("Not supported yet.");
        }
    };

    private static ObjectAllocator HTML_SAXPARSER_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw new UnsupportedOperationException("Not supported yet.");
        }
    };

    private static ObjectAllocator XSLT_STYLESHEET_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw new UnsupportedOperationException("Not supported yet.");
        }
    };

    private static ObjectAllocator XML_SYNTAXERROR_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw new UnsupportedOperationException("Not supported yet.");
        }
    };

    private static ObjectAllocator XML_DOCUMENT_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw new UnsupportedOperationException("Not supported yet.");
        }
    };

    public static class XmlDocument extends RubyObject {
        public XmlDocument(Ruby ruby, RubyClass klass) {
            super(ruby, klass);
        }

        @JRubyMethod(meta = true, rest = true)
        public static IRubyObject read_memory(IRubyObject cls, IRubyObject[] args) {
            return cls.getRuntime().getNil();
        }

        @JRubyMethod(meta = true, rest = true)
        public static IRubyObject read_io(IRubyObject cls, IRubyObject[] args) {
            return cls.getRuntime().getNil();
        }

        @JRubyMethod(meta = true, rest = true)
        public static IRubyObject rbNew(IRubyObject cls, IRubyObject[] args) {
            return cls.getRuntime().getNil();
        }

        @JRubyMethod(meta = true)
        public static IRubyObject substitute_entities_set(IRubyObject cls, IRubyObject arg) {
            return cls.getRuntime().getNil();
        }

        @JRubyMethod(meta = true)
        public static IRubyObject load_external_subsets_set(IRubyObject cls, IRubyObject arg) {
            return cls.getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject root() {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject root_set(IRubyObject arg) {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject serialize() {
            return getRuntime().getNil();
        }
    }

    public static class HtmlDocument {
        @JRubyMethod(meta = true, rest = true)
        public static IRubyObject read_memory(IRubyObject cls, IRubyObject[] args) {
            return cls.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject type(IRubyObject htmlDoc) {
            return htmlDoc.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject serialize(IRubyObject htmlDoc) {
            return htmlDoc.getRuntime().getNil();
        }
    }

    public static class XmlNode {
        @JRubyMethod(meta = true, rest = true)
        public static IRubyObject rbNew(IRubyObject cls, IRubyObject[] args) {
            return cls.getRuntime().getNil();
        }

        @JRubyMethod(meta = true, rest = true)
        public static IRubyObject new_from_str(IRubyObject cls, IRubyObject[] args) {
            return cls.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject name(IRubyObject xmlNode) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject name_set(IRubyObject xmlNode, IRubyObject arg) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject parent(IRubyObject xmlNode) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject parent_set(IRubyObject xmlNode, IRubyObject arg) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject child(IRubyObject xmlNode) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject next_sibling(IRubyObject xmlNode) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject previous_sibling(IRubyObject xmlNode) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject replace(IRubyObject xmlNode, IRubyObject arg) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject type(IRubyObject xmlNode) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject content(IRubyObject xmlNode) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject path(IRubyObject xmlNode) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject key_p(IRubyObject xmlNode, IRubyObject arg) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject blank_p(IRubyObject xmlNode) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod(name = "[]=")
        public static IRubyObject op_aset(IRubyObject xmlNode, IRubyObject arg1, IRubyObject arg2) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject remove_attribute(IRubyObject xmlNode, IRubyObject arg1) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject attributes(IRubyObject xmlNode) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject namespaces(IRubyObject xmlNode) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject add_previous_sibling(IRubyObject xmlNode, IRubyObject arg) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject add_next_sibling(IRubyObject xmlNode, IRubyObject arg) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject encode_special_chars(IRubyObject xmlNode, IRubyObject arg) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject to_xml(IRubyObject xmlNode) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject dup(IRubyObject xmlNode) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject unlink(IRubyObject xmlNode) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject internal_subset(IRubyObject xmlNode) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod
        public static IRubyObject pointer_id(IRubyObject xmlNode) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod(visibility = Visibility.PRIVATE)
        public static IRubyObject native_content_set(IRubyObject xmlNode, IRubyObject arg) {
            return xmlNode.getRuntime().getNil();
        }

        @JRubyMethod(visibility = Visibility.PRIVATE)
        public static IRubyObject get(IRubyObject xmlNode) {
            return xmlNode.getRuntime().getNil();
        }
    }

    public static class XmlText extends RubyObject {
        public XmlText(Ruby ruby, RubyClass rubyClass) {
            super(ruby, rubyClass);
        }

        @JRubyMethod(name = "new", meta = true)
        public static IRubyObject rbNew(IRubyObject cls, IRubyObject arg1, IRubyObject arg2) {
            return cls.getRuntime().getNil();
        }
    }

    public static class XmlCdata extends RubyObject {
        public XmlCdata(Ruby ruby, RubyClass rubyClass) {
            super(ruby, rubyClass);
        }

        @JRubyMethod(name = "new", meta = true)
        public static IRubyObject rbNew(IRubyObject cls, IRubyObject arg1, IRubyObject arg2) {
            return cls.getRuntime().getNil();
        }
    }

    public static class XmlComment extends RubyObject {
        public XmlComment(Ruby ruby, RubyClass rubyClass) {
            super(ruby, rubyClass);
        }

        @JRubyMethod(name = "new", meta = true)
        public static IRubyObject rbNew(IRubyObject cls, IRubyObject arg1, IRubyObject arg2) {
            return cls.getRuntime().getNil();
        }
    }

    public static class XmlNodeSet extends RubyObject {
        public XmlNodeSet(Ruby ruby, RubyClass rubyClass) {
            super(ruby, rubyClass);
        }

        @JRubyMethod
        public IRubyObject length() {
            return getRuntime().getNil();
        }

        @JRubyMethod(name = "[]")
        public IRubyObject op_aref(IRubyObject arg1) {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject push(IRubyObject arg1) {
            return getRuntime().getNil();
        }
    }

    public static class XpathContext extends RubyObject {
        public XpathContext(Ruby ruby, RubyClass rubyClass) {
            super(ruby, rubyClass);
        }

        @JRubyMethod(name = "new", meta = true)
        public static IRubyObject rbNew(IRubyObject cls, IRubyObject arg1) {
            return cls.getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject evaluate(IRubyObject arg1) {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject register_ns(IRubyObject arg1, IRubyObject arg2) {
            return getRuntime().getNil();
        }
    }

    public static class Xpath extends RubyObject {
        public Xpath(Ruby ruby, RubyClass rubyClass) {
            super(ruby, rubyClass);
        }

        @JRubyMethod(name = "node=")
        public IRubyObject node_set() {
            return getRuntime().getNil();
        }
    }

    public static class SaxParser extends RubyObject {
        public SaxParser(Ruby ruby, RubyClass rubyClass) {
            super(ruby, rubyClass);
        }

        @JRubyMethod
        public IRubyObject parse_memory(IRubyObject arg1) {
            return getRuntime().getNil();
        }

        @JRubyMethod(visibility = Visibility.PRIVATE)
        public IRubyObject native_parse_file(IRubyObject arg1) {
            return getRuntime().getNil();
        }

        @JRubyMethod(visibility = Visibility.PRIVATE)
        public IRubyObject native_parse_io(IRubyObject arg1, IRubyObject arg2) {
            return getRuntime().getNil();
        }
    }

    public static class HtmlSaxParser extends RubyObject {
        public HtmlSaxParser(Ruby ruby, RubyClass rubyClass) {
            super(ruby, rubyClass);
        }

        @JRubyMethod(visibility = Visibility.PRIVATE)
        public IRubyObject native_parse_memory(IRubyObject arg1, IRubyObject arg2) {
            return getRuntime().getNil();
        }

        @JRubyMethod(visibility = Visibility.PRIVATE)
        public IRubyObject native_parse_file(IRubyObject arg1, IRubyObject arg2) {
            return getRuntime().getNil();
        }
    }

    public static class Reader extends RubyObject {
        public Reader(Ruby ruby, RubyClass rubyClass) {
            super(ruby, rubyClass);
        }

        @JRubyMethod(meta = true, rest = true)
        public static IRubyObject from_memory(IRubyObject cls, IRubyObject args[]) {
            return cls.getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject read() {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject state() {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject name() {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject local_name() {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject namespace_uri() {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject prefix() {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject value() {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject lang() {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject xml_version() {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject encoding() {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject depth() {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject attribute_count() {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject attribute(IRubyObject arg) {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject attribute_at(IRubyObject arg) {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject attributes() {
            return getRuntime().getNil();
        }

        @JRubyMethod(name = "attributes?")
        public IRubyObject attributes_p() {
            return getRuntime().getNil();
        }

        @JRubyMethod(name = "value?")
        public IRubyObject value_p() {
            return getRuntime().getNil();
        }
    }

    public static class DTD extends RubyObject {
        public DTD(Ruby ruby, RubyClass rubyClass) {
            super(ruby, rubyClass);
        }

        @JRubyMethod
        public IRubyObject notations() {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject elements() {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject attributes() {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject entities() {
            return getRuntime().getNil();
        }
    }

    public static class XsltStylesheet extends RubyObject {
        public XsltStylesheet(Ruby ruby, RubyClass rubyClass) {
            super(ruby, rubyClass);
        }

        @JRubyMethod(meta = true)
        public static IRubyObject parse_stylesheet_doc(IRubyObject cls, IRubyObject arg1) {
            return cls.getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject serialize(IRubyObject arg1) {
            return getRuntime().getNil();
        }

        @JRubyMethod(rest = true)
        public IRubyObject apply_to(IRubyObject[] args) {
            return getRuntime().getNil();
        }
    }

    public static class SyntaxError extends RubyObject {
        public SyntaxError(Ruby ruby, RubyClass rubyClass) {
            super(ruby, rubyClass);
        }

        @JRubyMethod
        public IRubyObject message(IRubyObject arg1) {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject domain(IRubyObject arg) {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject code(IRubyObject arg) {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject level(IRubyObject arg) {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject file(IRubyObject arg) {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject line(IRubyObject arg) {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject str1(IRubyObject arg) {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject str2(IRubyObject arg) {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject str3(IRubyObject arg) {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject int1(IRubyObject arg) {
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject column(IRubyObject arg) {
            return getRuntime().getNil();
        }
    }
}
