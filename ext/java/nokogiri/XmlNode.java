package nokogiri;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.StringWriter;
import java.util.Hashtable;
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
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyBoolean;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyHash;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.Arity;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.Visibility;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;
import org.w3c.dom.Attr;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.w3c.dom.Text;
import org.xml.sax.EntityResolver;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

import static nokogiri.NokogiriHelpers.isNamespace;

public class XmlNode extends RubyObject {
    protected Node node;
    protected IRubyObject content, doc, name, namespace, namespace_definitions;
    protected Hashtable<Node,IRubyObject> internalCache;

    /*
     * Taken from http://ejohn.org/blog/comparing-document-position/
     * Used for compareDocumentPosition.
     * <ironic>Thanks to both java api and w3 doc for its helpful documentation</ironic>
     */

    protected static int IDENTICAL_ELEMENTS = 0;
    protected static int IN_DIFFERENT_DOCUMENTS = 1;
    protected static int SECOND_PRECEDES_FIRST = 2;
    protected static int FIRST_PRECEDES_SECOND = 4;
    protected static int SECOND_CONTAINS_FIRST = 8;
    protected static int FIRST_CONTAINS_SECOND = 16;
    
    public XmlNode(Ruby ruby, RubyClass cls){
        this(ruby,cls,null);
    }

    public XmlNode(Ruby ruby, RubyClass cls, Node node) {
        super(ruby, cls);
        this.node = node;
        this.internalCache = new Hashtable<Node,IRubyObject>();
        if(node != null) {
            this.name = ruby.newString(node.getNodeName());
            String textContent = node.getTextContent();
            this.content = (textContent == null) ? ruby.newString() : ruby.newString(node.getTextContent());
        }
    }

    protected static IRubyObject constructNode(Ruby ruby, Node node) {
        if (node == null) return ruby.getNil();
        // this is slow; need a way to cache nokogiri classes/modules somewhere
        switch (node.getNodeType()) {
            case Node.ATTRIBUTE_NODE:
                return new XmlAttr(ruby, node);
            case Node.TEXT_NODE:
                return new XmlText(ruby, (RubyClass)ruby.getClassFromPath("Nokogiri::XML::Text"), node);
            case Node.COMMENT_NODE:
                return new XmlNode(ruby, (RubyClass)ruby.getClassFromPath("Nokogiri::XML::Comment"), node);
            case Node.ELEMENT_NODE:
                return new XmlElement(ruby, (RubyClass)ruby.getClassFromPath("Nokogiri::XML::Element"), node);
            case Node.ENTITY_NODE:
                return new XmlNode(ruby, (RubyClass)ruby.getClassFromPath("Nokogiri::XML::EntityDeclaration"), node);
            case Node.CDATA_SECTION_NODE:
                return new XmlCdata(ruby, (RubyClass)ruby.getClassFromPath("Nokogiri::XML::CDATA"), node);
            case Node.DOCUMENT_TYPE_NODE:
                return new XmlDtd(ruby, (RubyClass)ruby.getClassFromPath("Nokogiri::XML::DTD"), node);
            default:
                return new XmlNode(ruby, (RubyClass)ruby.getClassFromPath("Nokogiri::XML::Node"), node);
        }
    }

    protected IRubyObject getFromInternalCache(ThreadContext context, Node node) {

        if(node == null) return context.getRuntime().getNil();

        IRubyObject res = this.internalCache.get(node);

        if(res == null) {
            res = XmlNode.constructNode(context.getRuntime(), node);
            this.internalCache.put(node, res);
        }

        return res;
    }

    protected RubyArray getNsDefinitions(Ruby ruby) {
        if(this.namespace_definitions == null) {
            RubyArray arr = ruby.newArray();
            NamedNodeMap nodes = this.node.getAttributes();

            if(nodes == null) {
                return ruby.newEmptyArray();
            }

            for(int i = 0; i < nodes.getLength(); i++) {
                Node n = nodes.item(i);
                if(isNamespace(n)) {
                    arr.append(XmlNamespace.fromNode(ruby, n));
                }
            }

            this.namespace_definitions = arr;
        }

        return (RubyArray) this.namespace_definitions;
    }

    public Node getNode() {
        return node;
    }

    public static Node getNodeFromXmlNode(ThreadContext context, IRubyObject xmlNode) {
        Ruby ruby = context.getRuntime();
        if (!(xmlNode instanceof XmlNode)) throw ruby.newTypeError(xmlNode, (RubyClass)ruby.getClassFromPath("Nokogiri::XML::Node"));
        return ((XmlNode)xmlNode).node;
    }

    protected void relink_namespace(ThreadContext context) {
        if(this.node.getNodeType() == Node.ELEMENT_NODE) {
            Element e = (Element) this.node;
            NamedNodeMap attrs = e.getAttributes();

            for(int i = 0; i < attrs.getLength(); i++) {
                Attr attr = (Attr) attrs.item(i);
                if(NokogiriHelpers.isNamespace(attr)){
                    e.removeAttributeNode(attr);
                }
            }
        }
        ((XmlNodeSet) this.children(context)).relink_namespace(context);
    }

    @JRubyMethod(name = "new", meta = true)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject name, IRubyObject doc) {

        if(!(doc instanceof XmlDocument)) {
            throw context.getRuntime().newArgumentError("document must be an instance of Nokogiri::XML::Document");
        }

        XmlDocument xmlDoc = (XmlDocument)doc;
        Document document = xmlDoc.getDocument();
        Element element = document.createElementNS(null, name.convertToString().asJavaString());

        XmlNode node = new XmlNode(context.getRuntime(), (RubyClass)cls, element);
        node.doc = doc;
        
        RuntimeHelpers.invoke(context, xmlDoc, "decorate", node);

        xmlDoc.cacheNode(element, node);

        return node;
    }

    @JRubyMethod
    public IRubyObject add_child(ThreadContext context, IRubyObject child) {
        try{
            node.appendChild(asXmlNode(context, child).node);
        } catch (Exception ex) {
            throw context.getRuntime().newRuntimeError(ex.toString());
        }
        return child;
    }

    @JRubyMethod
    public IRubyObject add_namespace_definition(ThreadContext context, IRubyObject prefix, IRubyObject href) {
        Ruby ruby = context.getRuntime();
        XmlNamespace ns = new XmlNamespace(ruby, prefix, href);

        this.getNsDefinitions(ruby).append(ns);
        return ns;
    }

    @JRubyMethod
    public IRubyObject attribute_nodes(ThreadContext context) {
        NamedNodeMap nodeMap = this.node.getAttributes();

        if(nodeMap == null){
            return context.getRuntime().newEmptyArray();
        }

        RubyArray attr = context.getRuntime().newArray();

        for(int i = 0; i < nodeMap.getLength(); i++) {
            attr.append(this.getFromInternalCache(context, nodeMap.item(i)));
        }

        return attr;
    }

    @JRubyMethod
    public IRubyObject attribute_with_ns(ThreadContext context, IRubyObject name, IRubyObject namespace) {
        String namej = name.convertToString().asJavaString();
        String nsj = (namespace.isNil()) ? null : namespace.convertToString().asJavaString();

        Node el = this.node.getAttributes().getNamedItemNS(nsj, namej);

        return this.getFromInternalCache(context, el);
    }

    @JRubyMethod
    public IRubyObject child(ThreadContext context) {
        return constructNode(context.getRuntime(), node.getFirstChild());
    }

    @JRubyMethod
    public IRubyObject children(ThreadContext context) {
       return new XmlNodeSet(context.getRuntime(), (RubyClass) context.getRuntime().getClassFromPath("Nokogiri::XML::NodeSet"), this.node.getChildNodes());
    }

    @JRubyMethod
    public IRubyObject compare(ThreadContext context, IRubyObject otherNode) {
        if(!(otherNode instanceof XmlNode)) {
            return context.getRuntime().newFixnum(-2);
        }

        Node on = ((XmlNode) otherNode).getNode();

        try{
            int res = this.node.compareDocumentPosition(on);
            if( (res & FIRST_PRECEDES_SECOND) == FIRST_PRECEDES_SECOND) {
                return context.getRuntime().newFixnum(-1);
            } else if ( (res & SECOND_PRECEDES_FIRST) == SECOND_PRECEDES_FIRST) {
                return context.getRuntime().newFixnum(1);
            } else if ( (res & IDENTICAL_ELEMENTS) == IDENTICAL_ELEMENTS) {
                return context.getRuntime().newFixnum(0);
            }

            return context.getRuntime().newFixnum(-2);
        } catch (Exception ex) {
            return context.getRuntime().newFixnum(-2);
        }
    }

    @JRubyMethod
    public IRubyObject document(ThreadContext context) {
        if(this.doc == null) {
            this.doc = new XmlDocument(context.getRuntime(), this.node.getOwnerDocument());
        }
        return this.doc;
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
            dbf.setNamespaceAware(true);
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
    public IRubyObject namespace(ThreadContext context){
        if(this.namespace == null) {
            this.namespace = new XmlNamespace(context.getRuntime(), this.node.getPrefix(),
                                this.node.lookupNamespaceURI(this.node.getPrefix()));
        }

        return this.namespace;
    }

    @JRubyMethod
    public IRubyObject namespace_definitions(ThreadContext context) {
        return this.getNsDefinitions(context.getRuntime());
    }

    @JRubyMethod(name="namespaced_key?")
    public IRubyObject namespaced_key_p(ThreadContext context, IRubyObject elementLName, IRubyObject namespaceUri) {
        return this.attribute_with_ns(context, elementLName, namespaceUri).isNil() ?
            context.getRuntime().getFalse() : context.getRuntime().getTrue();
    }

    @JRubyMethod
    public IRubyObject next_sibling(ThreadContext context) {
        return constructNode(context.getRuntime(), node.getNextSibling());
    }

    @JRubyMethod
    public IRubyObject node_name(ThreadContext context) {
        return this.name;
    }

    @JRubyMethod(name = "node_name=")
    public IRubyObject node_name_set(ThreadContext context, IRubyObject nodeName) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod
    public IRubyObject parent(ThreadContext context) {
        return constructNode(context.getRuntime(), node.getParentNode());
    }

    @JRubyMethod(name = "parent=")
    public IRubyObject parent_set(ThreadContext context, IRubyObject parent) {
        Node otherNode = getNodeFromXmlNode(context, parent);
        otherNode.appendChild(node);
        return parent;
    }

    @JRubyMethod
    public IRubyObject previous_sibling(ThreadContext context) {
        return constructNode(context.getRuntime(), node.getPreviousSibling());
    }

    @JRubyMethod(name="replace_with_node", visibility=Visibility.PROTECTED)
    public IRubyObject replace(ThreadContext context, IRubyObject newNode) {
        Node otherNode = getNodeFromXmlNode(context, newNode);
        node.getParentNode().replaceChild(otherNode, node);

        ((XmlNode) newNode).relink_namespace(context);

        return this;
    }

    @JRubyMethod(required=4, visibility=Visibility.PRIVATE)
    public IRubyObject native_write_to(ThreadContext context, IRubyObject[] args) {//IRubyObject io, IRubyObject encoding, IRubyObject indentString, IRubyObject options) {
        IRubyObject io = args[0];
        IRubyObject encoding = args[1];
        IRubyObject indentString = args[2];
        IRubyObject options = args[3];
        
        StringWriter sw = new StringWriter();
        try {
            Transformer t = TransformerFactory.newInstance().newTransformer();
            t.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "yes");
            t.transform(new DOMSource(this.node), new StreamResult(sw));
        } catch (TransformerException te) {
            throw context.getRuntime().newRuntimeError("couldn't transform the node back to string");
        }

        RuntimeHelpers.invoke(context, io, "write", context.getRuntime().newString(sw.toString()));

        return io;
    }

    @JRubyMethod(name = "node_type")
    public IRubyObject xmlType(ThreadContext context) {
        return RubyFixnum.newFixnum(context.getRuntime(), node.getNodeType());
    }

    @JRubyMethod
    public IRubyObject content(ThreadContext context) {
        return this.content;
    }

    @JRubyMethod
    public IRubyObject path(ThreadContext context) {
        return RubyString.newString(context.getRuntime(), node.getNodeName());
    }

    @JRubyMethod(name = "key?")
    public IRubyObject key_p(ThreadContext context, IRubyObject k) {
        Ruby ruby = context.getRuntime();
        String key = k.convertToString().asJavaString();
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
    public IRubyObject op_aset(ThreadContext context, IRubyObject index, IRubyObject val) {
        String key = index.convertToString().asJavaString();
        String value = val.convertToString().asJavaString();
        if (node instanceof Element) {
            Element element = (Element)node;
            element.setAttribute(key, value);
        }
        return val;
    }

    @JRubyMethod
    public IRubyObject remove_attribute(ThreadContext context, IRubyObject name) {
        String key = name.convertToString().asJavaString();
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
    public IRubyObject add_previous_sibling(ThreadContext context, IRubyObject node) {
        if (node instanceof XmlNode) {
            this.node.getParentNode().insertBefore(((XmlNode)node).node, this.node);
            RuntimeHelpers.invoke(context , node, "decorate!");
            return node;
        } else {
            throw context.getRuntime().newTypeError(node, (RubyClass) context.getRuntime().getClassFromPath("Nokogiri::XML::Node"));
        }
    }

    @JRubyMethod
    public IRubyObject add_next_sibling(ThreadContext context, IRubyObject node) {
        if (node instanceof XmlNode) {
            Node next = this.node.getNextSibling();
            if (next != null) {
                this.node.getParentNode().insertBefore(((XmlNode)node).node, next);
            } else {
                this.node.getParentNode().appendChild(((XmlNode)node).node);
            }
            RuntimeHelpers.invoke(context, node, "decorate!");
            return node;
        } else {
            throw context.getRuntime().newTypeError(node, (RubyClass) context.getRuntime().getClassFromPath("Nokogiri::XML::Node"));
        }
    }

    @JRubyMethod
    public IRubyObject encode_special_chars(ThreadContext context, IRubyObject string) {
        String s = string.convertToString().asJavaString();
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
        return this.dup_implementation(context, true);
    }

    @JRubyMethod
    public IRubyObject dup(ThreadContext context, IRubyObject depth) {
        boolean deep = depth.convertToInteger().getLongValue() != 0;

        return this.dup_implementation(context, deep);
    }

    protected IRubyObject dup_implementation(ThreadContext context, boolean deep) {
        Node newNode = node.cloneNode(deep);

        return new XmlNode(context.getRuntime(), this.getType(), newNode);
    }

    @JRubyMethod
    public IRubyObject unlink(ThreadContext context) {
        if(this.node.getNodeType() == Node.ATTRIBUTE_NODE) {
            Attr attr = (Attr) this.node;
            Element parent = attr.getOwnerElement();
            parent.removeAttributeNode(attr);
        } else if(this.node.getParentNode() == null) {
            throw context.getRuntime().newRuntimeError("TYPE: "+this.node.getNodeType()+ " PARENT NULL");
        } else {
            node.getParentNode().removeChild(node);
        }
        return this;
    }

    @JRubyMethod
    public IRubyObject internal_subset(ThreadContext context) {
        if(this.node.getOwnerDocument() == null) {
            return context.getRuntime().getNil();
        }

        return XmlNode.constructNode(context.getRuntime(), this.node.getOwnerDocument().getDoctype());
    }

    @JRubyMethod
    public IRubyObject pointer_id(ThreadContext context) {
        return RubyFixnum.newFixnum(context.getRuntime(), this.node.hashCode());
    }

    @JRubyMethod(name = "native_content=", visibility = Visibility.PRIVATE)
    public IRubyObject native_content_set(ThreadContext context, IRubyObject content) {
        RubyString newContent = content.convertToString();
        this.content = newContent;
        this.node.setTextContent(newContent.asJavaString());
        return content;
    }

    @JRubyMethod(visibility = Visibility.PRIVATE)
    public IRubyObject get(ThreadContext context, IRubyObject attribute) {
        String key = attribute.convertToString().asJavaString();
        if (node instanceof Element) {
            Element element = (Element)node;
            String value = element.getAttribute(key);
            if(!value.equals("")){
                return RubyString.newString(context.getRuntime(), value);
            }
        }
        return context.getRuntime().getNil();
    }

    @JRubyMethod
    public IRubyObject attribute(ThreadContext context, IRubyObject name){
        NamedNodeMap attrs = this.node.getAttributes();
        Node attr = attrs.getNamedItem(name.convertToString().asJavaString());
        if(attr == null) {
            return  context.getRuntime().getNil();
        }
        return constructNode(context.getRuntime(), attr);
    }

    private XmlNode asXmlNode(ThreadContext context, IRubyObject node) {
        if (!(node instanceof XmlNode)) {
            throw context.getRuntime().newTypeError(node, (RubyClass) context.getRuntime().getClassFromPath("Nokogiri::XML::Node"));
        }

        return (XmlNode) node;
    }
}
