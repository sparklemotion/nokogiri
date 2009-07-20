package nokogiri;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.util.Hashtable;
import javax.xml.parsers.ParserConfigurationException;
import nokogiri.internals.XmlDocumentImpl;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyIO;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.Arity;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;
import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.bootstrap.DOMImplementationRegistry;
import org.xml.sax.SAXException;

public class XmlDocument extends XmlNode {
    private Document document;
    private IRubyObject encoding;
    private static boolean substituteEntities = false;
    private static boolean loadExternalSubset = false; // TODO: Verify this.
    private Hashtable<Node, XmlNode> hashNode;

    IRubyObject root;

    public XmlDocument(Ruby ruby, Document document) {
        this(ruby, (RubyClass) ruby.getClassFromPath("Nokogiri::XML::Document"), document);
    }

    public XmlDocument(Ruby ruby, RubyClass klass, Document document) {
        super(ruby, klass, document.getDocumentElement());
        this.document = document;

        this.setNode(ruby, document.getDocumentElement());

        this.internalNode = new XmlDocumentImpl(ruby, document.getDocumentElement());

        this.hashNode = new Hashtable<Node, XmlNode>();
        setInstanceVariable("@decorators", ruby.getNil());
    }

    public void cacheNode(Node element, XmlNode node) {
        this.hashNode.put(element, node);
    }

    public IRubyObject getCachedNode(Node element) {
        return this.hashNode.get(element);
    }

    public Document getDocument() {
        return document;
    }

    @Override
    protected Node getNodeToCompare() {
        return this.document;
    }

    @JRubyMethod(name="new", meta = true, rest = true, required=0)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject[] args) {
        XmlDocument doc = null;
        try {
            doc = new XmlDocument(context.getRuntime(), (RubyClass) cls,
                       DOMImplementationRegistry.newInstance().getDOMImplementation("XML 1.0").createDocument(null, "empty", null));
        } catch (Exception ex) {
            throw context.getRuntime().newRuntimeError("couldn't create document: "+ex.toString());
        }

        RuntimeHelpers.invoke(context, doc, "initialize", args);

        return doc;
    }

    @Override
    @JRubyMethod
    public IRubyObject children(ThreadContext context) {
        Ruby ruby = context.getRuntime();
        RubyArray nodes = ruby.newArray();
        nodes.append(this.root(context));
        return new XmlNodeSet(ruby, (RubyClass) ruby.getClassFromPath("Nokogiri::XML::NodeSet"), nodes);
    }

    @JRubyMethod(name="encoding=")
    public IRubyObject encoding_set(ThreadContext context, IRubyObject encoding) {
        this.encoding = encoding;
        return encoding;
    }

    @JRubyMethod
    public IRubyObject encoding(ThreadContext context) {
        if(this.encoding == null) {
            if(this.document.getXmlEncoding() == null) {
                this.encoding = context.getRuntime().getNil();
            } else {
                this.encoding = context.getRuntime().newString(this.document.getXmlEncoding());
            }
        }
        return this.encoding;
    }

    @JRubyMethod(meta = true)
    public static IRubyObject load_external_subsets_set(ThreadContext context, IRubyObject cls, IRubyObject value) {
        XmlDocument.loadExternalSubset = value.isTrue();
        return context.getRuntime().getNil();
    }

    @JRubyMethod(meta = true, rest = true)
    public static IRubyObject read_io(ThreadContext context, IRubyObject cls, IRubyObject[] args) {
        Ruby ruby = context.getRuntime();
        Arity.checkArgumentCount(ruby, args, 4, 4);
        try {
            Document document;
            if (args[0] instanceof RubyIO) {
                RubyIO io = (RubyIO)args[0];
                document = getDocumentBuilder().parse(io.getInStream());
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
    public static IRubyObject read_memory(ThreadContext context, IRubyObject cls, IRubyObject[] args) {
        Ruby ruby = context.getRuntime();
        Arity.checkArgumentCount(ruby, args, 4, 4);
        try {
            Document document;
            RubyString content = args[0].convertToString();
            ByteList byteList = content.getByteList();
            ByteArrayInputStream bais = new ByteArrayInputStream(byteList.unsafeBytes(), byteList.begin(), byteList.length());
            document = getDocumentBuilder().parse(bais);
            return new XmlDocument(ruby, (RubyClass)cls, document);
        } catch (ParserConfigurationException pce) {
            throw RaiseException.createNativeRaiseException(ruby, pce);
        } catch (SAXException saxe) {
            throw RaiseException.createNativeRaiseException(ruby, saxe);
        } catch (IOException ioe) {
            throw RaiseException.createNativeRaiseException(ruby, ioe);
        }
    }

    @JRubyMethod
    public IRubyObject root(ThreadContext context) {
        if(this.root == null) {
            this.root = XmlNode.constructNode(context.getRuntime(), document.getDocumentElement());
        }
        return root;
    }

    @JRubyMethod(name="root=")
    public IRubyObject root_set(ThreadContext context, IRubyObject root) {
        Node node = XmlNode.getNodeFromXmlNode(context, root);
        document.replaceChild(node, document.getDocumentElement());
        return root;
    }

    @JRubyMethod(meta = true)
    public static IRubyObject substitute_entities_set(ThreadContext context, IRubyObject cls, IRubyObject value) {
        XmlDocument.substituteEntities = value.isTrue();
        return context.getRuntime().getNil();
    }
}