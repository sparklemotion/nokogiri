package nokogiri;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
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
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.Text;
import org.xml.sax.EntityResolver;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

import static nokogiri.NokogiriHelpers.isNamespace;

public class XmlNode extends RubyObject {
    // TODO: Talk to Tom about this.
    // Try not to have node, but its attributes.
    private Node node;
    private IRubyObject name, namespace_definitions, content;
    
    public XmlNode(Ruby ruby, RubyClass cls){
        this(ruby,cls,null);
    }

    public XmlNode(Ruby ruby, RubyClass cls, Node node) {
        super(ruby, cls);
        this.node = node;
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

    protected RubyArray getNsDefinitions(Ruby ruby) {
        if(this.namespace_definitions == null) {
            RubyArray arr = ruby.newArray();
            NamedNodeMap nodes = this.node.getAttributes();

            for(int i = 0; i < nodes.getLength(); i++) {
                Node n = nodes.item(i);
                if(isNamespace(n))
                    arr.append(XmlNamespace.fromNode(ruby, n));
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

    @JRubyMethod(name = "new", meta = true)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject name, IRubyObject doc) {
        XmlDocument xmlDoc = (XmlDocument)doc;
        Document document = xmlDoc.getDocument();
        Element element = document.createElement(name.convertToString().asJavaString());
        RubyArray node_cache = (RubyArray) RuntimeHelpers.getInstanceVariable(xmlDoc,
                                            context.getRuntime(), "@node_cache");

        XmlNode node = new XmlNode(context.getRuntime(), (RubyClass)cls, element);

        node_cache.append(node);
        RuntimeHelpers.invoke(context, xmlDoc, "decorate", node);

        return node;
    }

    @JRubyMethod
    public IRubyObject add_child(ThreadContext context, IRubyObject child) {
        node.appendChild(asXmlNode(context, child).node);

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
    public IRubyObject child(ThreadContext context) {
        return constructNode(context.getRuntime(), node.getFirstChild());
    }

    @JRubyMethod
    public IRubyObject children(ThreadContext context){
       return new XmlNodeSet(context.getRuntime(), (RubyClass) context.getRuntime().getClassFromPath("Nokogiri::XML::NodeSet"), this.node.getChildNodes());
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
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod
    public IRubyObject namespace_definitions(ThreadContext context) {
        return this.getNsDefinitions(context.getRuntime());
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

    @JRubyMethod
    public IRubyObject replace(ThreadContext context, IRubyObject newNode) {
        Node otherNode = getNodeFromXmlNode(context, newNode);
        node.getParentNode().replaceChild(otherNode, node);

        return this;
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
    public IRubyObject attribute_node(ThreadContext context){
        Ruby ruby = context.getRuntime();
        NamedNodeMap attrs = node.getAttributes();
        RubyArray arr = RubyArray.newArray(ruby,attrs.getLength());
        Node attr;
        for(int i = 0; i < attrs.getLength(); i++){
            attr = attrs.item(i);
            arr.append(constructNode(ruby,attr));
        }
        return arr;
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
    public IRubyObject native_content_set(ThreadContext context, IRubyObject content) {
        node.setTextContent(content.convertToString().asJavaString());
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
        if(attr == null)
            return  context.getRuntime().getNil();
        return constructNode(context.getRuntime(), attr);
    }

    private XmlNode asXmlNode(ThreadContext context, IRubyObject node) {
        if (!(node instanceof XmlNode)) {
            throw context.getRuntime().newTypeError(node, (RubyClass) context.getRuntime().getClassFromPath("Nokogiri::XML::Node"));
        }

        return (XmlNode) node;
    }
}
