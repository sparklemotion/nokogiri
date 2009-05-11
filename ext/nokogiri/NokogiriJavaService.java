package nokogiri;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.Vector;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParserFactory;
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
import org.jruby.RubyArray;
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
import org.jruby.util.TypeConverter;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.w3c.dom.Text;
import org.xml.sax.Attributes;
import org.xml.sax.helpers.DefaultHandler;
import org.xml.sax.EntityResolver;
import org.xml.sax.InputSource;
import org.xml.sax.Locator;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;
import org.xml.sax.XMLReader;
import org.xml.sax.ext.DefaultHandler2;
import org.xml.sax.helpers.XMLReaderFactory;

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

        saxParser.setAllocator(XML_SAXPARSER_ALLOCATOR);
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
            return new SaxParser(runtime, klazz);
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
        private static boolean substituteEntities = false;
        private static boolean loadExternalSubset = false; // TODO: Verify this.
        
        public XmlDocument(Ruby ruby, RubyClass klass, Document document) {
            super(ruby, klass, document);
            this.document = document;
        }

        public Document getDocument() {
            return document;
        }

        @JRubyMethod(meta = true, rest = true)
        public static IRubyObject read_memory(ThreadContext context, IRubyObject cls, IRubyObject[] args) {
            Ruby ruby = context.getRuntime();
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
        public static IRubyObject read_io(ThreadContext context, IRubyObject cls, IRubyObject[] args) {
            Ruby ruby = context.getRuntime();
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
        public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject[] args) {
            throw context.getRuntime().newNotImplementedError("not implemented");
            /*
             * this.document = DOMImplementationRegistry.newInstance().getDOMImplementation("XML 1.0");
             */
        }

        @JRubyMethod(meta = true)
        public static IRubyObject substitute_entities_set(ThreadContext context, IRubyObject cls, IRubyObject arg) {
            XmlDocument.substituteEntities = arg.isTrue();
            return context.getRuntime().getNil();
        }

        @JRubyMethod(meta = true)
        public static IRubyObject load_external_subsets_set(ThreadContext context, IRubyObject cls, IRubyObject arg) {
            XmlDocument.loadExternalSubset = arg.isTrue();
            return context.getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject root(ThreadContext context) {
            return XmlNode.constructNode(context.getRuntime(), document.getDocumentElement());
        }

        @JRubyMethod
        public IRubyObject root_set(ThreadContext context, IRubyObject arg) {
            Node node = XmlNode.getNodeFromXmlNode(context, arg);
            document.replaceChild(node, document.getDocumentElement());
            return arg;
        }

    }

    public static class HtmlDocument {
        @JRubyMethod(meta = true, rest = true)
        public static IRubyObject read_memory(ThreadContext context, IRubyObject cls, IRubyObject[] args) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public static IRubyObject type(ThreadContext context, IRubyObject htmlDoc) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public static IRubyObject serialize(ThreadContext context, IRubyObject htmlDoc) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }
    }

    public static class XmlNode extends RubyObject {
        private Node node;

        public XmlNode(Ruby ruby, RubyClass cls, Node node) {
            super(ruby, cls);
            this.node = node;
        }
        
        @JRubyMethod(name = "new", meta = true)
        public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject name, IRubyObject doc) {
            XmlDocument xmlDoc = (XmlDocument)doc;
            Document document = xmlDoc.getDocument();
            Element element = document.createElement(name.convertToString().asJavaString());
            return new XmlNode(context.getRuntime(), (RubyClass)cls, element);
        }

        @JRubyMethod(meta = true, rest = true)
        public static IRubyObject new_from_str(ThreadContext context, IRubyObject cls, IRubyObject[] args) {
            // TODO: duplicating code from Document.read_memory
            Ruby ruby = context.getRuntime();
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
        public IRubyObject name(ThreadContext context) {
            return RubyString.newString(context.getRuntime(), node.getNodeName());
        }

        @JRubyMethod(name = "name=")
        public IRubyObject name_set(ThreadContext context, IRubyObject arg) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject parent(ThreadContext context) {
            return constructNode(context.getRuntime(), node.getParentNode());
        }

        public Node getNode() {
            return node;
        }

        private static Node getNodeFromXmlNode(ThreadContext context, IRubyObject arg) {
            Ruby ruby = context.getRuntime();
            if (!(arg instanceof XmlNode)) throw ruby.newTypeError(arg, (RubyClass)ruby.getClassFromPath("Nokogiri::XML::Node"));
            return ((XmlNode)arg).node;
        }

        @JRubyMethod(name = "parent=")
        public IRubyObject parent_set(ThreadContext context, IRubyObject arg) {
            Node otherNode = getNodeFromXmlNode(context, arg);
            otherNode.appendChild(node);
            return arg;
        }

        @JRubyMethod
        public IRubyObject child(ThreadContext context) {
            return constructNode(context.getRuntime(), node.getFirstChild());
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
        public IRubyObject next_sibling(ThreadContext context) {
            return constructNode(context.getRuntime(), node.getNextSibling());
        }

        @JRubyMethod
        public IRubyObject previous_sibling(ThreadContext context) {
            return constructNode(context.getRuntime(), node.getPreviousSibling());
        }

        @JRubyMethod
        public IRubyObject replace(ThreadContext context, IRubyObject arg) {
            Node otherNode = getNodeFromXmlNode(context, arg);
            node.getParentNode().replaceChild(otherNode, node);

            return this;
        }

        @JRubyMethod(name = "type")
        public IRubyObject xmlType(ThreadContext context) {
            return RubyFixnum.newFixnum(context.getRuntime(), node.getNodeType());
        }

        @JRubyMethod
        public IRubyObject content(ThreadContext context) {
            return RubyString.newString(context.getRuntime(), node.getTextContent());
        }

        @JRubyMethod
        public IRubyObject path(ThreadContext context) {
            return RubyString.newString(context.getRuntime(), node.getNodeName());
        }

        @JRubyMethod(name = "key?")
        public IRubyObject key_p(ThreadContext context, IRubyObject arg) {
            Ruby ruby = context.getRuntime();
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
        public IRubyObject blank_p(ThreadContext context) {
            return RubyBoolean.newBoolean(context.getRuntime(), node instanceof Text && ((Text)node).isElementContentWhitespace());
        }

        @JRubyMethod(name = "[]=")
        public IRubyObject op_aset(ThreadContext context, IRubyObject arg1, IRubyObject arg2) {
            String key = arg1.convertToString().asJavaString();
            String value = arg2.convertToString().asJavaString();
            if (node instanceof Element) {
                Element element = (Element)node;
                element.setAttribute(key, value);
            }
            return arg2;
        }

        @JRubyMethod
        public IRubyObject remove_attribute(ThreadContext context, IRubyObject arg1) {
            String key = arg1.convertToString().asJavaString();
            if (node instanceof Element) {
                Element element = (Element)node;
                element.removeAttribute(key);
            }
            return context.getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject attributes(ThreadContext context) {
            Ruby ruby = context.getRuntime();
            RubyHash hash = RubyHash.newHash(ruby);
            NamedNodeMap attrs = node.getAttributes();
            for (int i = 0; i < attrs.getLength(); i++) {
                Node attr = attrs.item(i);
                hash.op_aset(context, RubyString.newString(ruby, attr.getNodeName()), RubyString.newString(ruby, attr.getNodeValue()));
            }
            return hash;
        }

        @JRubyMethod
        public IRubyObject namespaces(ThreadContext context) {
            Ruby ruby = context.getRuntime();
            RubyHash hash = RubyHash.newHash(ruby);
            NamedNodeMap attrs = node.getAttributes();
            for (int i = 0; i < attrs.getLength(); i++) {
                Node attr = attrs.item(i);
                hash.op_aset(context, RubyString.newString(ruby, attr.getNodeName()), RubyString.newString(ruby, attr.getNodeValue()));
            }
            return hash;
        }

        @JRubyMethod
        public IRubyObject add_previous_sibling(ThreadContext context, IRubyObject arg) {
            if (arg instanceof XmlNode) {
                node.getParentNode().insertBefore(((XmlNode)arg).node, node);
                RuntimeHelpers.invoke(context , arg, "decorate!");
                return arg;
            } else {
                throw context.getRuntime().newTypeError(arg, (RubyClass) context.getRuntime().getClassFromPath("Nokogiri::XML::Node"));
            }
        }

        @JRubyMethod
        public IRubyObject add_next_sibling(ThreadContext context, IRubyObject arg) {
            if (arg instanceof XmlNode) {
                Node next = node.getNextSibling();
                if (next != null) {
                    node.getParentNode().insertBefore(((XmlNode)arg).node, next);
                } else {
                    node.getParentNode().appendChild(((XmlNode)arg).node);
                }
                RuntimeHelpers.invoke(context, arg, "decorate!");
                return arg;
            } else {
                throw context.getRuntime().newTypeError(arg, (RubyClass) context.getRuntime().getClassFromPath("Nokogiri::XML::Node"));
            }
        }

        @JRubyMethod
        public IRubyObject encode_special_chars(ThreadContext context, IRubyObject arg) {
            String s = arg.convertToString().asJavaString();
            // From entities.c
            s = s.replaceAll("&", "&amp;");
            s = s.replaceAll("<", "&lt;");
            s = s.replaceAll(">", "&gt;");
            s = s.replaceAll("\"", "&quot;");
            s = s.replaceAll("\r", "&#13;");
            return RubyString.newString(context.getRuntime(), s);
        }

        @JRubyMethod
        public IRubyObject to_xml(ThreadContext context) {
            try {
                Transformer xformer = TransformerFactory.newInstance().newTransformer();
                ByteArrayOutputStream baos = new ByteArrayOutputStream(1024);
                xformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "yes");
                xformer.transform(new DOMSource(node), new StreamResult(baos));
                return RubyString.newString(context.getRuntime(), baos.toByteArray());
            } catch (TransformerFactoryConfigurationError tfce) {
                throw RaiseException.createNativeRaiseException(context.getRuntime(), tfce);
            } catch (TransformerConfigurationException tce) {
                throw RaiseException.createNativeRaiseException(context.getRuntime(), tce);
            } catch (TransformerException te) {
                throw RaiseException.createNativeRaiseException(context.getRuntime(), te);
            }
        }

        @JRubyMethod
        public IRubyObject dup(ThreadContext context) {
            return constructNode(context.getRuntime(), node);
        }

        @JRubyMethod
        public IRubyObject unlink(ThreadContext context) {
            node.getParentNode().removeChild(node);
            return this;
        }

        @JRubyMethod
        public IRubyObject internal_subset(ThreadContext context) {
            if(this.node.getOwnerDocument() == null)
                return context.getRuntime().getNil();

            String dtd = this.node.getOwnerDocument().getDoctype().getInternalSubset();

            if(dtd == null)
                return context.getRuntime().getNil();

            return RubyString.newString(context.getRuntime(), dtd);
        }

        @JRubyMethod
        public IRubyObject pointer_id(ThreadContext context) {
            return RubyFixnum.newFixnum(context.getRuntime(), this.node.hashCode());
        }

        @JRubyMethod(name = "native_content=", visibility = Visibility.PRIVATE)
        public IRubyObject native_content_set(ThreadContext context, IRubyObject arg) {
            node.setTextContent(arg.convertToString().asJavaString());
            return arg;
        }

        @JRubyMethod(visibility = Visibility.PRIVATE)
        public IRubyObject get(ThreadContext context, IRubyObject arg1) {
            String key = arg1.convertToString().asJavaString();
            if (node instanceof Element) {
                Element element = (Element)node;
                String value = element.getAttribute(key);
                return RubyString.newString(context.getRuntime(), value);
            }
            return context.getRuntime().getNil();
        }
    }

    public static class XmlText extends XmlNode {
        public XmlText(Ruby ruby, RubyClass rubyClass, Node node) {
            super(ruby, rubyClass, node);
        }

        @JRubyMethod(name = "new", meta = true)
        public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject text, IRubyObject doc) {
            XmlDocument xmlDoc = (XmlDocument)doc;
            Document document = xmlDoc.getDocument();
            Node node = document.createTextNode(text.convertToString().asJavaString());
            return XmlNode.constructNode(context.getRuntime(), node);
        }
    }

    public static class XmlCdata extends XmlText {
        public XmlCdata(Ruby ruby, RubyClass rubyClass, Node node) {
            super(ruby, rubyClass, node);
        }

        @JRubyMethod(name = "new", meta = true)
        public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject text, IRubyObject doc) {
            XmlDocument xmlDoc = (XmlDocument)doc;
            Document document = xmlDoc.getDocument();
            Node node = document.createCDATASection(text.convertToString().asJavaString());
            return XmlNode.constructNode(context.getRuntime(), node);
        }
    }

    public static class XmlComment extends XmlNode {
        public XmlComment(Ruby ruby, RubyClass rubyClass, Node node) {
            super(ruby, rubyClass, node);
        }

        @JRubyMethod(name = "new", meta = true)
        public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject doc, IRubyObject text) {
            XmlDocument xmlDoc = (XmlDocument)doc;
            Document document = xmlDoc.getDocument();
            Node node = document.createComment(text.convertToString().asJavaString());
            return XmlNode.constructNode(context.getRuntime(), node);
        }
    }

    public static class XmlNodeSet extends RubyObject {
        private Vector<XmlNode> nodes;

        // TODO Change internal implementation.
        public XmlNodeSet(Ruby ruby, RubyClass rubyClass, NodeList nodes) {
            super(ruby, rubyClass);
            this.nodes = new Vector<XmlNode>(nodes.getLength());
            for(int i = 0; i < nodes.getLength(); i++)
                this.nodes.add((XmlNode) XmlNode.constructNode(ruby, nodes.item(i)));
        }

        private XmlNodeSet(Ruby ruby, RubyClass rubyClass, Vector<XmlNode> nodes){
            super(ruby, rubyClass);
            this.nodes = nodes;
        }

        @JRubyMethod(name="&")
        public IRubyObject and(ThreadContext context, IRubyObject arg){
            // TODO: Talk to Enebo about this. Maybe calling "to_a & to_a" and adding it to the Vector would be better.
            // who knows.
            if(!(arg1 instanceof XmlNodeSet)) context.getRuntime().newArgumentError("node_set must be a Nokogiri::XML::NodeSet");
            XmlNodeSet xns = (XmlNodeSet) arg;
            Vector<XmlNode> v = new Vector<XmlNode>();
            for(XmlNode node: this.nodes)
                if(xns.nodes.contains(node))
                    v.add(node);
            return new XmlNodeSet(context.getRuntime(), context.getRuntime().getClassFromPath("Nokogiri::XML::NodeSet"), v);
        }
        @JRubyMethod
        public IRubyObject delete(ThreadContext context, IRubyObject arg){
            if(!(arg1 instanceof XmlNode)) context.getRuntime().newArgumentError("node must be a Nokogiri::XML::Node");
            return  this.nodes.remove(arg1) ? arg : context.getRuntime().getNil();
        }

        @JRubyMethod
        public IRubyObject dup(ThreadContext context){
            return new XmlNodeSet(context.getRuntime(), (RubyClass)context.getRuntime().getClassFromPath("Nokogiri::XML::NodeSet"), (Vector<XmlNode>) this.nodes.clone());
        }

        @JRubyMethod
        public IRubyObject length(ThreadContext context) {
            return RubyFixnum.newFixnum(context.getRuntime(), nodes.size());
        }

        @JRubyMethod(name = "[]")
        public IRubyObject op_aref(ThreadContext context, IRubyObject arg1) {
            int index = (int)arg1.convertToInteger().getLongValue();
            if (index < 0) index = nodes.size() + index;
            return nodes.get(index);
        }

        @JRubyMethod
        public IRubyObject push(ThreadContext context, IRubyObject arg1) {
            if(!(arg1 instanceof XmlNode)) context.getRuntime().newArgumentError("node must be a Nokogiri::XML::Node");
            this.nodes.add((XmlNode) arg1);
            return this;
        }

        @JRubyMethod
        public IRubyObject to_a(ThreadContext context){
           XmlNode[] narr = new XmlNode[this.nodes.size()];
           return RubyArray.newArray(context.getRuntime(), this.nodes.toArray(narr));
        }

        @JRubyMethod
        public IRubyObject unlink(ThreadContext context){
            for(XmlNode node: nodes)
                node.unlink(context);
            return this;
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
        public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject arg1) {
            XmlNode node = (XmlNode)arg1;
            return new XpathContext(context.getRuntime(), (RubyClass)cls, node.getNode());
        }

        @JRubyMethod
        public IRubyObject evaluate(ThreadContext context, IRubyObject arg1) {
            String src = arg1.convertToString().asJavaString();
            try {
                XPathExpression xpathExpression = xpath.compile(src);
                return new Xpath(context.getRuntime(), (RubyClass)context.getRuntime().getClassFromPath("Nokogiri::XML::XPath"), xpathExpression, this.context);
            } catch (XPathExpressionException xpee) {
                throw context.getRuntime().newSyntaxError("Couldn't evaluate expression '" + src + "'");
            }
        }

        @JRubyMethod
        public IRubyObject register_ns(ThreadContext context, IRubyObject arg1, IRubyObject arg2) {
            return context.getRuntime().getNil();
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
        public IRubyObject node_set(ThreadContext context) {
            try {
                NodeList nodes = (NodeList)xpath.evaluate(this.context, XPathConstants.NODESET);
                return new XmlNodeSet(context.getRuntime(), (RubyClass)context.getRuntime().getClassFromPath("Nokogiri::XML::NodeSet"), nodes);
            } catch (XPathExpressionException xpee) {
                throw context.getRuntime().newSyntaxError("Couldn't evaluate expression '" + xpath.toString() + "'");
            }
        }
    }

    public static class SaxParser extends RubyObject {
        private DefaultHandler2 handler;
        private XMLReader reader;

        public SaxParser(final Ruby ruby, RubyClass rubyClass) {
            super(ruby, rubyClass);

            final ThreadContext context = ruby.getCurrentContext();
            final IRubyObject self = this;
            handler = new DefaultHandler2() {
                public void startDocument() throws SAXException {
                    RuntimeHelpers.invoke(context, document(context), "start_document");
                }

                public void endDocument() throws SAXException {
                    RuntimeHelpers.invoke(context, document(context), "end_document");
                }

                public void startElement(String arg0, String arg1, String arg2, Attributes arg3) throws SAXException {
                    RubyArray attrs = RubyArray.newArray(ruby, arg3.getLength());
                    for (int i = 0; i < arg3.getLength(); i++) {
                        attrs.append(RubyString.newString(ruby, arg3.getQName(i)));
                        attrs.append(RubyString.newString(ruby, arg3.getValue(i)));
                    }
                    RuntimeHelpers.invoke(context, document(context), "start_element",
                            RubyString.newString(ruby, arg2),
                            attrs);
                }

                public void endElement(String arg0, String arg1, String arg2) throws SAXException {
                    RuntimeHelpers.invoke(context, document(context), "end_element",
                            RubyString.newString(ruby, arg2));
                }

                public void characters(char[] arg0, int arg1, int arg2) throws SAXException {
                    String target;
                    if (inCDATA) {
                        target = "cdata_block";
                    } else {
                        target = "characters";
                    }
                    RuntimeHelpers.invoke(context, document(context), target,
                            RubyString.newString(ruby, new String(arg0, arg1, arg2)));
                }

                @Override
                public void comment(char[] arg0, int arg1, int arg2) throws SAXException {
                    RuntimeHelpers.invoke(context, document(context), "comment",
                            RubyString.newString(ruby, new String(arg0, arg1, arg2)));
                }

                boolean inCDATA = false;

                public void startCDATA() throws SAXException {
                    inCDATA = true;
                }

                public void endCDATA() throws SAXException {
                    inCDATA = false;
                }

                public void error(SAXParseException saxpe) {
                    RuntimeHelpers.invoke(context, document(context), "error",
                            RubyString.newString(ruby, saxpe.getMessage()));
                }

                public void warning(SAXParseException saxpe) {
                    RuntimeHelpers.invoke(context, document(context), "warning",
                            RubyString.newString(ruby, saxpe.getMessage()));
                }
            };
            try {
                reader = XMLReaderFactory.createXMLReader();
                reader.setContentHandler(handler);
                reader.setErrorHandler(handler);
                reader.setProperty("http://xml.org/sax/properties/lexical-handler", handler);
            } catch (SAXException se) {
                throw RaiseException.createNativeRaiseException(context.getRuntime(), se);
            }
        }

        @JRubyMethod
        public IRubyObject parse_memory(ThreadContext context, IRubyObject arg1) {
            try {
                RubyString content = arg1.convertToString();
                ByteList byteList = content.getByteList();
                ByteArrayInputStream bais = new ByteArrayInputStream(byteList.unsafeBytes(), byteList.begin(), byteList.length());
                reader.parse(new InputSource(bais));
                return arg1;
            } catch (SAXException se) {
                throw RaiseException.createNativeRaiseException(context.getRuntime(), se);
            } catch (IOException ioe) {
                throw context.getRuntime().newIOErrorFromException(ioe);
            }
        }

        @JRubyMethod(visibility = Visibility.PRIVATE)
        public IRubyObject native_parse_file(ThreadContext context, IRubyObject arg1) {
            try {
                String filename = arg1.convertToString().asJavaString();
                reader.parse(new InputSource(new FileInputStream(filename)));
                return arg1;
            } catch (SAXException se) {
                throw RaiseException.createNativeRaiseException(context.getRuntime(), se);
            } catch (IOException ioe) {
                throw context.getRuntime().newIOErrorFromException(ioe);
            }
        }

        @JRubyMethod(visibility = Visibility.PRIVATE)
        public IRubyObject native_parse_io(ThreadContext context, IRubyObject arg1, IRubyObject arg2) {
            try {
                int encoding = (int)arg2.convertToInteger().getLongValue();
                RubyIO io = (RubyIO)TypeConverter.convertToType(arg1, getRuntime().getIO(), "to_io");
                reader.parse(new InputSource(io.getInStream()));
                return arg1;
            } catch (SAXException se) {
                throw RaiseException.createNativeRaiseException(context.getRuntime(), se);
            } catch (IOException ioe) {
                throw context.getRuntime().newIOErrorFromException(ioe);
            }
        }

        private IRubyObject document(ThreadContext context){
            return RuntimeHelpers.invoke(context, this, "document");
        }
    }

    public static class HtmlSaxParser extends RubyObject {
        public HtmlSaxParser(Ruby ruby, RubyClass rubyClass) {
            super(ruby, rubyClass);
        }

        @JRubyMethod(visibility = Visibility.PRIVATE)
        public static IRubyObject native_parse_memory(ThreadContext context, IRubyObject self, IRubyObject arg1, IRubyObject arg2) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod(visibility = Visibility.PRIVATE)
        public static IRubyObject native_parse_file(ThreadContext context, IRubyObject self, IRubyObject arg1, IRubyObject arg2) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }
    }

    public static class Reader extends RubyObject {
        public Reader(Ruby ruby, RubyClass rubyClass) {
            super(ruby, rubyClass);
        }

        @JRubyMethod(meta = true, rest = true)
        public static IRubyObject from_memory(ThreadContext context, IRubyObject cls, IRubyObject args[]) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject read(ThreadContext context) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject state(ThreadContext context) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject name(ThreadContext context) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject local_name(ThreadContext context) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject namespace_uri(ThreadContext context) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject prefix(ThreadContext context) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject value(ThreadContext context) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject lang(ThreadContext context) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject xml_version(ThreadContext context) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject encoding(ThreadContext context) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject depth(ThreadContext context) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject attribute_count(ThreadContext context) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject attribute(ThreadContext context, IRubyObject arg) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject attribute_at(ThreadContext context, IRubyObject arg) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject attributes(ThreadContext context) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod(name = "attributes?")
        public IRubyObject attributes_p(ThreadContext context) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod(name = "value?")
        public IRubyObject value_p(ThreadContext context) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }
    }

    public static class DTD extends RubyObject {
        public DTD(Ruby ruby, RubyClass rubyClass) {
            super(ruby, rubyClass);
        }

        @JRubyMethod
        public IRubyObject notations(ThreadContext context) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject elements(ThreadContext context) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject attributes(ThreadContext context) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject entities(ThreadContext context) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }
    }

    public static class XsltStylesheet extends RubyObject {
        public XsltStylesheet(Ruby ruby, RubyClass rubyClass) {
            super(ruby, rubyClass);
        }

        @JRubyMethod(meta = true)
        public static IRubyObject parse_stylesheet_doc(ThreadContext context, IRubyObject cls, IRubyObject arg1) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject serialize(ThreadContext context, IRubyObject arg1) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod(rest = true)
        public IRubyObject apply_to(ThreadContext context, IRubyObject[] args) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }
    }

    public static class SyntaxError extends RubyObject {
        public SyntaxError(Ruby ruby, RubyClass rubyClass) {
            super(ruby, rubyClass);
        }

        @JRubyMethod
        public IRubyObject message(ThreadContext context, IRubyObject arg1) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject domain(ThreadContext context, IRubyObject arg) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject code(ThreadContext context, IRubyObject arg) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject level(ThreadContext context, IRubyObject arg) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject file(ThreadContext context, IRubyObject arg) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject line(ThreadContext context, IRubyObject arg) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject str1(ThreadContext context, IRubyObject arg) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject str2(ThreadContext context, IRubyObject arg) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject str3(ThreadContext context, IRubyObject arg) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject int1(ThreadContext context, IRubyObject arg) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }

        @JRubyMethod
        public IRubyObject column(ThreadContext context, IRubyObject arg) {
            throw context.getRuntime().newNotImplementedError("not implemented");
        }
    }
}
