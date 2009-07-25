package nokogiri;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.util.Hashtable;
import javax.xml.parsers.ParserConfigurationException;
import nokogiri.internals.ParseOptions;
import nokogiri.internals.XmlDocumentImpl;
import nokogiri.internals.XmlEmptyDocumentImpl;
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
    private static boolean substituteEntities = false;
    private static boolean loadExternalSubset = false; // TODO: Verify this.
    private Hashtable<Node, XmlNode> hashNode;

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

    protected XmlDocumentImpl internals() {
        return (XmlDocumentImpl) this.internalNode;
    }

    @JRubyMethod(name="new", meta = true, rest = true, required=0)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject[] args) {
        XmlDocument doc = null;
        try {
//            doc = new XmlDocument(context.getRuntime(), (RubyClass) cls,
//                       DOMImplementationRegistry.newInstance().getDOMImplementation("XML 1.0").createDocument(null, "empty", null));

            Document docNode = (new ParseOptions(0)).getDocumentBuilder().newDocument();
            doc = new XmlDocument(context.getRuntime(), (RubyClass) cls,
                    docNode);
            doc.internalNode = new XmlEmptyDocumentImpl(context.getRuntime(),
                    docNode);
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
        internals().encoding_set(context, this, encoding);
        return encoding;
    }

    @JRubyMethod
    public IRubyObject encoding(ThreadContext context) {
        return internals().encoding(context, this);
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
        ParseOptions options = new ParseOptions(args[3]);
        try {
            Document document;
            if (args[0] instanceof RubyIO) {
                RubyIO io = (RubyIO)args[0];
                document = options.getDocumentBuilder().parse(io.getInStream());
                XmlDocument doc = new XmlDocument(ruby, (RubyClass)cls, document);
                options.addErrorsIfNecessary(context, doc);
                return doc;
            } else {
                throw ruby.newTypeError("Only IO supported for Document.read_io currently");
            }
        } catch (ParserConfigurationException pce) {
            return options.getDocumentWithErrorsOrRaiseException(context, pce);
        } catch (SAXException saxe) {
            return options.getDocumentWithErrorsOrRaiseException(context, saxe);
        } catch (IOException ioe) {
            return options.getDocumentWithErrorsOrRaiseException(context, ioe);
        }
    }

    @JRubyMethod(meta = true, rest = true)
    public static IRubyObject read_memory(ThreadContext context, IRubyObject cls, IRubyObject[] args) {
        Ruby ruby = context.getRuntime();
        Arity.checkArgumentCount(ruby, args, 4, 4);
        ParseOptions options = new ParseOptions(args[3]);
        try {
            Document document;
            RubyString content = args[0].convertToString();
            ByteList byteList = content.getByteList();
            ByteArrayInputStream bais = new ByteArrayInputStream(byteList.unsafeBytes(), byteList.begin(), byteList.length());
            document = options.getDocumentBuilder().parse(bais);
            XmlDocument doc = new XmlDocument(ruby, (RubyClass)cls, document);
            options.addErrorsIfNecessary(context, doc);
            return doc;
        } catch (ParserConfigurationException pce) {
            return options.getDocumentWithErrorsOrRaiseException(context, pce);
        } catch (SAXException saxe) {
            return options.getDocumentWithErrorsOrRaiseException(context, saxe);
        } catch (IOException ioe) {
            return options.getDocumentWithErrorsOrRaiseException(context, ioe);
        }
    }

    @JRubyMethod
    public IRubyObject root(ThreadContext context) {
        return internals().root(context, this);
    }

    @JRubyMethod(name="root=")
    public IRubyObject root_set(ThreadContext context, IRubyObject root) {
        internals().root_set(context, this, root);
        return root;
    }

    @JRubyMethod(meta = true)
    public static IRubyObject substitute_entities_set(ThreadContext context, IRubyObject cls, IRubyObject value) {
        XmlDocument.substituteEntities = value.isTrue();
        return context.getRuntime().getNil();
    }
}