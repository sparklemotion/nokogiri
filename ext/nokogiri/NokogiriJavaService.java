/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package nokogiri;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.Arrays;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.TransformerFactoryConfigurationError;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpression;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;
import org.jruby.Ruby;
import org.jruby.RubyBoolean;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyHash;
import org.jruby.RubyIO;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.Arity;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.Visibility;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.BasicLibraryService;
import org.jruby.util.ByteList;
import org.w3c.dom.CDATASection;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.w3c.dom.Text;
import org.xml.sax.EntityResolver;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

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
        
        RubyClass document = init_xml_document(ruby, xml, node);
        init_html_document(ruby, html, document);
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

    public static RubyClass init_xml_document(Ruby ruby, RubyModule xml, RubyClass node) {
        RubyClass document = xml.defineClassUnder("Document", node, XML_DOCUMENT_ALLOCATOR);

        document.defineAnnotatedMethods(XmlDocument.class);
        document.undefineMethod("parent");

        return document;
    }

    public static void init_html_document(Ruby ruby, RubyModule html, RubyClass document) {
        RubyModule htmlDoc = html.defineOrGetClassUnder("Document", document);

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
        // Nokogiri::XML::SAX::Parser is defined by nokogiri/xml/sax/parser.rb
        RubyClass saxParser = xmlSax.getClass("Parser");

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
        // Nokogiri::XML::SAX::Parser is defined by nokogiri/html/sax/parser.rb
        RubyClass saxParser = htmlSax.getClass("Parser");

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
            throw runtime.newNotImplementedError("not implemented");
        }
    };

    private static ObjectAllocator XML_TEXT_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw runtime.newNotImplementedError("not implemented");
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

    private static ObjectAllocator XML_NODESET_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw runtime.newNotImplementedError("not implemented");
        }
    };

    private static ObjectAllocator XML_XPATHCONTEXT_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw runtime.newNotImplementedError("not implemented");
        }
    };

    private static ObjectAllocator XML_XPATH_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw new UnsupportedOperationException("Not supported yet.");
        }
    };

    private static ObjectAllocator XML_READER_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw runtime.newNotImplementedError("not implemented");
        }
    };

    private static ObjectAllocator XML_DTD_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw runtime.newNotImplementedError("not implemented");
        }
    };

    private static ObjectAllocator XML_SAXPARSER_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw runtime.newNotImplementedError("not implemented");
        }
    };

    private static ObjectAllocator HTML_SAXPARSER_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw runtime.newNotImplementedError("not implemented");
        }
    };

    private static ObjectAllocator XSLT_STYLESHEET_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw new UnsupportedOperationException("Not supported yet.");
        }
    };

    private static ObjectAllocator XML_SYNTAXERROR_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw runtime.newNotImplementedError("not implemented");
        }
    };

    private static ObjectAllocator XML_DOCUMENT_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            throw runtime.newNotImplementedError("not implemented");
        }
    };

    public static class XmlDocument extends XmlNode {
        private Document document;
        
        public XmlDocument(Ruby ruby, RubyClass klass, Document document) {
            super(ruby, klass, document);
            this.document = document;
        }

        public Document getDocument() {
            return document;
        }

        @JRubyMethod(meta = true, rest = true)
        public static IRubyObject read_memory(IRubyObject cls, IRubyObject[] args) {
            Ruby ruby = cls.getRuntime();
            Arity.checkArgumentCount(ruby, args, 4, 4);
            try {
                Document document;
                RubyString content = args[0].convertToString();
                ByteList byteList = content.getByteList();
                ByteArrayInputStream bais = new ByteArrayInputStream(byteList.unsafeBytes(), byteList.begin(), byteList.length());
                DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
                DocumentBuilder db = dbf.newDocumentBuilder();
                db.setEntityResolver(new EntityResolver() {
                    public InputSource resolveEntity(String arg0, String arg1) throws SAXException, IOException {
                        return new InputSource(new ByteArrayInputStream(new byte[0]));
                    }
                });
                document = db.parse(bais);
                return new XmlDocument(ruby, (RubyClass)cls, document);
            } catch (ParserConfigurationException pce) {
                throw RaiseException.createNativeRaiseException(ruby, pce);
            } catch (SAXException saxe) {
                throw RaiseException.createNativeRaiseException(ruby, saxe);
            } catch (IOException ioe) {
                throw RaiseException.createNativeRaiseException(ruby, ioe);
            }
        }

        @JRubyMethod(meta = true, rest = true)
        public static IRubyObject read_io(IRubyObject cls, IRubyObject[] args) {
            Ruby ruby = cls.getRuntime();
            Arity.checkArgumentCount(ruby, args, 4, 4);
            try {
                Document document;
                if (args[0] instanceof RubyIO) {
                    RubyIO io = (RubyIO)args[0];
                    DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
                    DocumentBuilder db = dbf.newDocumentBuilder();
                    db.setEntityResolver(new EntityResolver() {
                        public InputSource resolveEntity(String arg0, String arg1) throws SAXException, IOException {
                            return new InputSource(new ByteArrayInputStream(new byte[0]));
                        }
                    });
                    document = db.parse(io.getInStream());
                    return new XmlDocument(ruby, (RubyClass)cls, document);
                } else {
                    throw ruby.newTypeError("Only IO supported for Document.read_io currently");
                }
            } catch (ParserConfigurationException pce) {
                throw RaiseException.createNativeRaiseException(ruby, pce);
            } catch (SAXException saxe) {
                throw RaiseException.createNativeRaiseException(ruby, saxe);
            } catch (IOException ioe) {
                throw RaiseException.createNativeRaiseException(ruby, ioe);
            }
        }

        @JRubyMethod(meta = true, rest = true)
        public static IRubyObject rbNew(IRubyObject cls, IRubyObject[] args) {
            throw cls.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod(meta = true)
        public static IRubyObject substitute_entities_set(IRubyObject cls, IRubyObject arg) {
            throw cls.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod(meta = true)
        public static IRubyObject load_external_subsets_set(IRubyObject cls, IRubyObject arg) {
            throw cls.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject root() {
            return XmlNode.constructNode(getRuntime(), document.getDocumentElement());
        }

        @JRubyMethod
        public IRubyObject root_set(IRubyObject arg) {
            Node node = XmlNode.getNodeFromXmlNode(arg);
            document.replaceChild(node, document.getDocumentElement());
            return arg;
        }

        @JRubyMethod
        public IRubyObject serialize() {
            throw getRuntime().newNotImplementedError("not implemented");
        }
    }

    public static class HtmlDocument {
        @JRubyMethod(meta = true, rest = true)
        public static IRubyObject read_memory(IRubyObject cls, IRubyObject[] args) {
            throw cls.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public static IRubyObject type(IRubyObject htmlDoc) {
            throw htmlDoc.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public static IRubyObject serialize(IRubyObject htmlDoc) {
            throw htmlDoc.getRuntime().newNotImplementedError("not implemented");
        }
    }

    public static class XmlNode extends RubyObject {
        private Node node;

        public XmlNode(Ruby ruby, RubyClass cls, Node node) {
            super(ruby, cls);
            this.node = node;
        }
        
        @JRubyMethod(name = "new", meta = true)
        public static IRubyObject rbNew(IRubyObject cls, IRubyObject name, IRubyObject doc) {
            XmlDocument xmlDoc = (XmlDocument)doc;
            Document document = xmlDoc.getDocument();
            Element element = document.createElement(name.convertToString().asJavaString());
            return new XmlNode(cls.getRuntime(), (RubyClass)cls, element);
        }

        @JRubyMethod(meta = true, rest = true)
        public static IRubyObject new_from_str(IRubyObject cls, IRubyObject[] args) {
            // TODO: duplicating code from Document.read_memory
            Ruby ruby = cls.getRuntime();
            Arity.checkArgumentCount(ruby, args, 4, 4);
            try {
                Document document;
                RubyString content = args[0].convertToString();
                ByteList byteList = content.getByteList();
                ByteArrayInputStream bais = new ByteArrayInputStream(byteList.unsafeBytes(), byteList.begin(), byteList.length());
                DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
                DocumentBuilder db = dbf.newDocumentBuilder();
                db.setEntityResolver(new EntityResolver() {
                    public InputSource resolveEntity(String arg0, String arg1) throws SAXException, IOException {
                        return new InputSource(new ByteArrayInputStream(new byte[0]));
                    }
                });
                document = db.parse(bais);
                return constructNode(ruby, document.getFirstChild());
            } catch (ParserConfigurationException pce) {
                throw RaiseException.createNativeRaiseException(ruby, pce);
            } catch (SAXException saxe) {
                throw RaiseException.createNativeRaiseException(ruby, saxe);
            } catch (IOException ioe) {
                throw RaiseException.createNativeRaiseException(ruby, ioe);
            }
        }

        @JRubyMethod
        public IRubyObject name() {
            return RubyString.newString(getRuntime(), node.getNodeName());
        }

        @JRubyMethod(name = "name=")
        public IRubyObject name_set(IRubyObject arg) {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject parent() {
            return constructNode(getRuntime(), node.getParentNode());
        }

        public Node getNode() {
            return node;
        }

        private static Node getNodeFromXmlNode(IRubyObject arg) {
            Ruby ruby = arg.getRuntime();
            if (!(arg instanceof XmlNode)) throw ruby.newTypeError(arg, (RubyClass)ruby.getClassFromPath("Nokogiri::XML::Node"));
            return ((XmlNode)arg).node;
        }

        @JRubyMethod(name = "parent=")
        public IRubyObject parent_set(IRubyObject arg) {
            Node otherNode = getNodeFromXmlNode(arg);
            otherNode.appendChild(node);
            return arg;
        }

        @JRubyMethod
        public IRubyObject child() {
            return constructNode(getRuntime(), node.getFirstChild());
        }

        protected static IRubyObject constructNode(Ruby ruby, Node node) {
            if (node == null) return ruby.getNil();
            // this is slow; need a way to cache nokogiri classes/modules somewhere
            switch (node.getNodeType()) {
                case Node.TEXT_NODE:
                    return new XmlText(ruby, (RubyClass)ruby.getClassFromPath("Nokogiri::XML::Text"), node);
                case Node.COMMENT_NODE:
                    return new XmlNode(ruby, (RubyClass)ruby.getClassFromPath("Nokogiri::XML::Comment"), node);
                case Node.ELEMENT_NODE:
                    return new XmlNode(ruby, (RubyClass)ruby.getClassFromPath("Nokogiri::XML::Element"), node);
                case Node.ENTITY_NODE:
                    return new XmlNode(ruby, (RubyClass)ruby.getClassFromPath("Nokogiri::XML::EntityDeclaration"), node);
                case Node.CDATA_SECTION_NODE:
                    return new XmlCdata(ruby, (RubyClass)ruby.getClassFromPath("Nokogiri::XML::CDATA"), node);
                case Node.DOCUMENT_TYPE_NODE:
                    return new XmlNode(ruby, (RubyClass)ruby.getClassFromPath("Nokogiri::XML::DTD"), node);
                default:
                    return new XmlNode(ruby, (RubyClass)ruby.getClassFromPath("Nokogiri::XML::Node"), node);
            }
        }

        @JRubyMethod
        public IRubyObject next_sibling() {
            return constructNode(getRuntime(), node.getNextSibling());
        }

        @JRubyMethod
        public IRubyObject previous_sibling() {
            return constructNode(getRuntime(), node.getPreviousSibling());
        }

        @JRubyMethod
        public IRubyObject replace(IRubyObject arg) {
            Node otherNode = getNodeFromXmlNode(arg);
            node.getParentNode().replaceChild(otherNode, node);

            return this;
        }

        @JRubyMethod(name = "type")
        public IRubyObject xmlType() {
            return RubyFixnum.newFixnum(getRuntime(), node.getNodeType());
        }

        @JRubyMethod
        public IRubyObject content() {
            return RubyString.newString(getRuntime(), node.getTextContent());
        }

        @JRubyMethod
        public IRubyObject path() {
            return RubyString.newString(getRuntime(), node.getNodeName());
        }

        @JRubyMethod(name = "key?")
        public IRubyObject key_p(IRubyObject arg) {
            Ruby ruby = getRuntime();
            String key = arg.convertToString().asJavaString();
            if (node instanceof Element) {
                Element element = (Element)node;
                if (element.hasAttribute(key)) {
                    return ruby.getTrue();
                }
            }
            return ruby.getFalse();
        }

        @JRubyMethod(name = "blank?")
        public IRubyObject blank_p() {
            return RubyBoolean.newBoolean(getRuntime(), node instanceof Text && ((Text)node).isElementContentWhitespace());
        }

        @JRubyMethod(name = "[]=")
        public IRubyObject op_aset(IRubyObject arg1, IRubyObject arg2) {
            String key = arg1.convertToString().asJavaString();
            String value = arg2.convertToString().asJavaString();
            if (node instanceof Element) {
                Element element = (Element)node;
                element.setAttribute(key, value);
            }
            return arg2;
        }

        @JRubyMethod
        public IRubyObject remove_attribute(IRubyObject arg1) {
            String key = arg1.convertToString().asJavaString();
            if (node instanceof Element) {
                Element element = (Element)node;
                element.removeAttribute(key);
            }
            return getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject attributes() {
            Ruby ruby = getRuntime();
            ThreadContext context = ruby.getCurrentContext();
            RubyHash hash = RubyHash.newHash(ruby);
            NamedNodeMap attrs = node.getAttributes();
            for (int i = 0; i < attrs.getLength(); i++) {
                Node attr = attrs.item(i);
                hash.op_aset(context, RubyString.newString(ruby, attr.getNodeName()), RubyString.newString(ruby, attr.getNodeValue()));
            }
            return hash;
        }

        @JRubyMethod
        public IRubyObject namespaces() {
            Ruby ruby = getRuntime();
            ThreadContext context = ruby.getCurrentContext();
            RubyHash hash = RubyHash.newHash(ruby);
            NamedNodeMap attrs = node.getAttributes();
            for (int i = 0; i < attrs.getLength(); i++) {
                Node attr = attrs.item(i);
                hash.op_aset(context, RubyString.newString(ruby, attr.getNodeName()), RubyString.newString(ruby, attr.getNodeValue()));
            }
            return hash;
        }

        @JRubyMethod
        public IRubyObject add_previous_sibling(IRubyObject arg) {
            if (arg instanceof XmlNode) {
                node.getParentNode().insertBefore(((XmlNode)arg).node, node);
                RuntimeHelpers.invoke(getRuntime().getCurrentContext(), arg, "decorate!");
                return arg;
            } else {
                throw getRuntime().newTypeError(arg, (RubyClass)getRuntime().getClassFromPath("Nokogiri::XML::Node"));
            }
        }

        @JRubyMethod
        public IRubyObject add_next_sibling(IRubyObject arg) {
            if (arg instanceof XmlNode) {
                Node next = node.getNextSibling();
                if (next != null) {
                    node.getParentNode().insertBefore(((XmlNode)arg).node, next);
                } else {
                    node.getParentNode().appendChild(((XmlNode)arg).node);
                }
                RuntimeHelpers.invoke(getRuntime().getCurrentContext(), arg, "decorate!");
                return arg;
            } else {
                throw getRuntime().newTypeError(arg, (RubyClass)getRuntime().getClassFromPath("Nokogiri::XML::Node"));
            }
        }

        @JRubyMethod
        public IRubyObject encode_special_chars(IRubyObject arg) {
            // TODO: actually encode :)
            return arg;
        }

        @JRubyMethod
        public IRubyObject to_xml() {
            try {
                Transformer xformer = TransformerFactory.newInstance().newTransformer();
                ByteArrayOutputStream baos = new ByteArrayOutputStream(1024);
                xformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "yes");
                xformer.transform(new DOMSource(node), new StreamResult(baos));
                return RubyString.newString(getRuntime(), baos.toByteArray());
            } catch (TransformerFactoryConfigurationError tfce) {
                throw RaiseException.createNativeRaiseException(getRuntime(), tfce);
            } catch (TransformerConfigurationException tce) {
                throw RaiseException.createNativeRaiseException(getRuntime(), tce);
            } catch (TransformerException te) {
                throw RaiseException.createNativeRaiseException(getRuntime(), te);
            }
        }

        @JRubyMethod
        public IRubyObject dup() {
            return constructNode(getRuntime(), node);
        }

        @JRubyMethod
        public IRubyObject unlink() {
            node.getParentNode().removeChild(node);
            return this;
        }

        @JRubyMethod
        public IRubyObject internal_subset() {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject pointer_id() {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod(name = "native_content=", visibility = Visibility.PRIVATE)
        public IRubyObject native_content_set(IRubyObject arg) {
            node.setTextContent(arg.convertToString().asJavaString());
            return arg;
        }

        @JRubyMethod(visibility = Visibility.PRIVATE)
        public IRubyObject get(IRubyObject arg1) {
            String key = arg1.convertToString().asJavaString();
            if (node instanceof Element) {
                Element element = (Element)node;
                String value = element.getAttribute(key);
                return RubyString.newString(getRuntime(), value);
            }
            return getRuntime().getNil();
        }
    }

    public static class XmlText extends XmlNode {
        public XmlText(Ruby ruby, RubyClass rubyClass, Node node) {
            super(ruby, rubyClass, node);
        }

        @JRubyMethod(name = "new", meta = true)
        public static IRubyObject rbNew(IRubyObject cls, IRubyObject text, IRubyObject doc) {
            XmlDocument xmlDoc = (XmlDocument)doc;
            Document document = xmlDoc.getDocument();
            Node node = document.createTextNode(text.convertToString().asJavaString());
            return XmlNode.constructNode(cls.getRuntime(), node);
        }
    }

    public static class XmlCdata extends XmlText {
        public XmlCdata(Ruby ruby, RubyClass rubyClass, Node node) {
            super(ruby, rubyClass, node);
        }

        @JRubyMethod(name = "new", meta = true)
        public static IRubyObject rbNew(IRubyObject cls, IRubyObject text, IRubyObject doc) {
            XmlDocument xmlDoc = (XmlDocument)doc;
            Document document = xmlDoc.getDocument();
            Node node = document.createCDATASection(text.convertToString().asJavaString());
            return XmlNode.constructNode(cls.getRuntime(), node);
        }
    }

    public static class XmlComment extends XmlNode {
        public XmlComment(Ruby ruby, RubyClass rubyClass, Node node) {
            super(ruby, rubyClass, node);
        }

        @JRubyMethod(name = "new", meta = true)
        public static IRubyObject rbNew(IRubyObject cls, IRubyObject doc, IRubyObject text) {
            XmlDocument xmlDoc = (XmlDocument)doc;
            Document document = xmlDoc.getDocument();
            Node node = document.createComment(text.convertToString().asJavaString());
            return XmlNode.constructNode(cls.getRuntime(), node);
        }
    }

    public static class XmlNodeSet extends RubyObject {
        private NodeList nodes;

        public XmlNodeSet(Ruby ruby, RubyClass rubyClass, NodeList nodes) {
            super(ruby, rubyClass);
            this.nodes = nodes;
        }

        @JRubyMethod
        public IRubyObject length() {
            return RubyFixnum.newFixnum(getRuntime(), nodes.getLength());
        }

        @JRubyMethod(name = "[]")
        public IRubyObject op_aref(IRubyObject arg1) {
            int index = (int)arg1.convertToInteger().getLongValue();
            if (index < 0) index = nodes.getLength() + index;
            return XmlNode.constructNode(getRuntime(), nodes.item(index));
        }

        @JRubyMethod
        public IRubyObject push(IRubyObject arg1) {
            throw getRuntime().newNotImplementedError("not implemented");
        }
    }

    public static class XpathContext extends RubyObject {
        private Node context;
        private XPath xpath;
        
        public XpathContext(Ruby ruby, RubyClass rubyClass, Node context) {
            super(ruby, rubyClass);
            this.context = context;
            this.xpath = XPathFactory.newInstance().newXPath();
        }

        @JRubyMethod(name = "new", meta = true)
        public static IRubyObject rbNew(IRubyObject cls, IRubyObject arg1) {
            XmlNode node = (XmlNode)arg1;
            return new XpathContext(cls.getRuntime(), (RubyClass)cls, node.getNode());
        }

        @JRubyMethod
        public IRubyObject evaluate(IRubyObject arg1) {
            String src = arg1.convertToString().asJavaString();
            try {
                XPathExpression xpathExpression = xpath.compile(src);
                return new Xpath(getRuntime(), (RubyClass)getRuntime().getClassFromPath("Nokogiri::XML::XPath"), xpathExpression, context);
            } catch (XPathExpressionException xpee) {
                throw getRuntime().newSyntaxError("Couldn't evaluate expression '" + src + "'");
            }
        }

        @JRubyMethod
        public IRubyObject register_ns(IRubyObject arg1, IRubyObject arg2) {
            return getRuntime().getNil();
        }
    }

    public static class Xpath extends RubyObject {
        private XPathExpression xpath;
        private Node context;
        
        public Xpath(Ruby ruby, RubyClass rubyClass, XPathExpression xpath, Node context) {
            super(ruby, rubyClass);
            this.xpath = xpath;
            this.context = context;
        }

        @JRubyMethod(name = "node_set")
        public IRubyObject node_set() {
            try {
                NodeList nodes = (NodeList)xpath.evaluate(context, XPathConstants.NODESET);
                return new XmlNodeSet(getRuntime(), (RubyClass)getRuntime().getClassFromPath("Nokogiri::XML::NodeSet"), nodes);
            } catch (XPathExpressionException xpee) {
                throw getRuntime().newSyntaxError("Couldn't evaluate expression '" + xpath.toString() + "'");
            }
        }
    }

    public static class SaxParser extends RubyObject {
        public SaxParser(Ruby ruby, RubyClass rubyClass) {
            super(ruby, rubyClass);
        }

        @JRubyMethod
        public static IRubyObject parse_memory(IRubyObject self, IRubyObject arg1) {
            throw self.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod(visibility = Visibility.PRIVATE)
        public static IRubyObject native_parse_file(IRubyObject self, IRubyObject arg1) {
            throw self.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod(visibility = Visibility.PRIVATE)
        public static IRubyObject native_parse_io(IRubyObject self, IRubyObject arg1, IRubyObject arg2) {
            throw self.getRuntime().newNotImplementedError("not implemented");
        }
    }

    public static class HtmlSaxParser extends RubyObject {
        public HtmlSaxParser(Ruby ruby, RubyClass rubyClass) {
            super(ruby, rubyClass);
        }

        @JRubyMethod(visibility = Visibility.PRIVATE)
        public static IRubyObject native_parse_memory(IRubyObject self, IRubyObject arg1, IRubyObject arg2) {
            throw self.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod(visibility = Visibility.PRIVATE)
        public static IRubyObject native_parse_file(IRubyObject self, IRubyObject arg1, IRubyObject arg2) {
            throw self.getRuntime().newNotImplementedError("not implemented");
        }
    }

    public static class Reader extends RubyObject {
        public Reader(Ruby ruby, RubyClass rubyClass) {
            super(ruby, rubyClass);
        }

        @JRubyMethod(meta = true, rest = true)
        public static IRubyObject from_memory(IRubyObject cls, IRubyObject args[]) {
            throw cls.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject read() {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject state() {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject name() {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject local_name() {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject namespace_uri() {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject prefix() {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject value() {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject lang() {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject xml_version() {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject encoding() {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject depth() {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject attribute_count() {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject attribute(IRubyObject arg) {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject attribute_at(IRubyObject arg) {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject attributes() {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod(name = "attributes?")
        public IRubyObject attributes_p() {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod(name = "value?")
        public IRubyObject value_p() {
            throw getRuntime().newNotImplementedError("not implemented");
        }
    }

    public static class DTD extends RubyObject {
        public DTD(Ruby ruby, RubyClass rubyClass) {
            super(ruby, rubyClass);
        }

        @JRubyMethod
        public IRubyObject notations() {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject elements() {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject attributes() {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject entities() {
            throw getRuntime().newNotImplementedError("not implemented");
        }
    }

    public static class XsltStylesheet extends RubyObject {
        public XsltStylesheet(Ruby ruby, RubyClass rubyClass) {
            super(ruby, rubyClass);
        }

        @JRubyMethod(meta = true)
        public static IRubyObject parse_stylesheet_doc(IRubyObject cls, IRubyObject arg1) {
            throw cls.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject serialize(IRubyObject arg1) {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod(rest = true)
        public IRubyObject apply_to(IRubyObject[] args) {
            throw getRuntime().newNotImplementedError("not implemented");
        }
    }

    public static class SyntaxError extends RubyObject {
        public SyntaxError(Ruby ruby, RubyClass rubyClass) {
            super(ruby, rubyClass);
        }

        @JRubyMethod
        public IRubyObject message(IRubyObject arg1) {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject domain(IRubyObject arg) {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject code(IRubyObject arg) {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject level(IRubyObject arg) {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject file(IRubyObject arg) {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject line(IRubyObject arg) {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject str1(IRubyObject arg) {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject str2(IRubyObject arg) {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject str3(IRubyObject arg) {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject int1(IRubyObject arg) {
            throw getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject column(IRubyObject arg) {
            throw getRuntime().newNotImplementedError("not implemented");
        }
    }
}
