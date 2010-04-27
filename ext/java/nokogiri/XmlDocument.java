package nokogiri;

import static nokogiri.internals.NokogiriHelpers.stringOrNil;

import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import nokogiri.internals.NokogiriUserDataHandler;
import nokogiri.internals.SaveContext;
import nokogiri.internals.XmlDomParserContext;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyNil;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.Arity;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.w3c.dom.Node;

public class XmlDocument extends XmlNode {
    /* UserData keys for storing extra info in the document node. */
    public final static String DTD_RAW_DOCUMENT = "DTD_RAW_DOCUMENT";
    protected final static String DTD_INTERNAL_SUBSET = "DTD_INTERNAL_SUBSET";
    protected final static String DTD_EXTERNAL_SUBSET = "DTD_EXTERNAL_SUBSET";

    private static boolean substituteEntities = false;
    private static boolean loadExternalSubset = false; // TODO: Verify this.

    /** cache variables */
    protected IRubyObject encoding = null;
    protected IRubyObject url = null;

    public XmlDocument(Ruby ruby, Document document) {
        this(ruby, (RubyClass) ruby.getClassFromPath("Nokogiri::XML::Document"), document);
    }

    public XmlDocument(Ruby ruby, RubyClass klass, Document document) {
        super(ruby, klass, document);

//        if(document == null) {
//            this.internalNode = new XmlEmptyDocumentImpl(ruby, document);
//        } else {

//        }

        setInstanceVariable("@decorators", ruby.getNil());
    }

//     @Override
//     protected IRubyObject dup_implementation(ThreadContext context, boolean deep) {
//         return ((XmlDocumentImpl) this.internalNode).dup_impl(context, this, deep, this.getType());
//     }

    public Document getDocument() {
        return (Document) node;
    }

    public void setUrl(IRubyObject url) {
        this.url = url;
    }

    protected IRubyObject getUrl() {
        return this.url;
    }

    @JRubyMethod
    public IRubyObject url(ThreadContext context) {
        return getUrl();
    }

    protected static Document createNewDocument() {
        try {
            return DocumentBuilderFactory.newInstance().newDocumentBuilder()
                .newDocument();
        } catch (ParserConfigurationException e) {
            return null;        // this will end is disaster...
        }
    }

    @JRubyMethod(name="new", meta = true, rest = true, required=0)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject[] args) {
        XmlDocument doc = null;
        try {
            Document docNode = createNewDocument();
            doc = new XmlDocument(context.getRuntime(), (RubyClass) cls,
                                  docNode);
        } catch (Exception ex) {
            throw context.getRuntime().newRuntimeError("couldn't create document: "+ex.toString());
        }

        RuntimeHelpers.invoke(context, doc, "initialize", args);

        return doc;
    }

    @Override
    @JRubyMethod
    public IRubyObject document(ThreadContext context) {
        return this;
    }

    @JRubyMethod(name="encoding=")
    public IRubyObject encoding_set(ThreadContext context, IRubyObject encoding) {
        this.encoding = encoding;
        return this;
    }

    @JRubyMethod
    public IRubyObject encoding(ThreadContext context) {
        if (this.encoding == null) {
            if (getDocument().getXmlEncoding() == null) {
                this.encoding = context.getRuntime().getNil();
            } else {
                this.encoding = context.getRuntime().newString(getDocument().getXmlEncoding());
            }
        }

        return this.encoding;
    }

    @JRubyMethod(meta = true)
    public static IRubyObject load_external_subsets_set(ThreadContext context, IRubyObject cls, IRubyObject value) {
        XmlDocument.loadExternalSubset = value.isTrue();
        return context.getRuntime().getNil();
    }

    /**
     * TODO: handle encoding?
     *
     * @param args[0] a Ruby IO or StringIO
     * @param args[1] url or nil
     * @param args[2] encoding
     * @param args[3] bitset of parser options
     */
    public static IRubyObject newFromData(ThreadContext context,
                                          IRubyObject klass,
                                          IRubyObject[] args) {
        Ruby ruby = context.getRuntime();
        Arity.checkArgumentCount(ruby, args, 4, 4);
        XmlDomParserContext ctx =
            new XmlDomParserContext(ruby, args[3]);
        ctx.setInputSource(context, args[0]);
        return ctx.parse(context, klass, args[1]);
    }

    @JRubyMethod(meta = true, rest = true)
    public static IRubyObject read_io(ThreadContext context,
                                      IRubyObject klass,
                                      IRubyObject[] args) {
        return newFromData(context, klass, args);
    }

    @JRubyMethod(meta = true, rest = true)
    public static IRubyObject read_memory(ThreadContext context,
                                          IRubyObject klass,
                                          IRubyObject[] args) {
        return newFromData(context, klass, args);
    }

    /** not a JRubyMethod */
    public static IRubyObject read_memory(ThreadContext context,
                                          IRubyObject[] args) {
        return read_memory(context,
                           context.getRuntime()
                           .getClassFromPath("Nokogiri::XML::Document"),
                           args);
    }
    
    @JRubyMethod(name="remove_namespaces!")
    public IRubyObject remove_namespaces(ThreadContext context) {
        removeNamespceRecursively(context, this);
        return this;
    }
    
    private void removeNamespceRecursively(ThreadContext context, XmlNode xmlNode) {
        Node node = xmlNode.getNode();
        if (node.getNodeType() == Node.ELEMENT_NODE) {
            node.setPrefix(null);
            node.getOwnerDocument().renameNode(node, null, node.getLocalName());
            xmlNode.removeNamespace(context);
        }
        XmlNodeSet nodeSet = (XmlNodeSet) xmlNode.children(context);
        for (long i=0; i < nodeSet.length(); i++) {
            XmlNode childNode = (XmlNode)nodeSet.slice(context, RubyFixnum.newFixnum(context.getRuntime(), i));
            removeNamespceRecursively(context, childNode);
        }
    }

    @JRubyMethod
    public IRubyObject root(ThreadContext context) {
        Node rootNode = getDocument().getDocumentElement();
        if (rootNode == null)
            return context.getRuntime().getNil();
        else
            return XmlNode.fromNodeOrCreate(context, rootNode);
    }

    @JRubyMethod(name="root=")
    public IRubyObject root_set(ThreadContext context, IRubyObject newRoot_) {
        // in case of document fragment, temporary root node should be deleted.
        if (newRoot_ instanceof RubyNil) {
            getDocument().getDocumentElement().setUserData(NokogiriUserDataHandler.VALID_ROOT_NODE , false, null);
            return newRoot_;
        }
        XmlNode newRoot = asXmlNode(context, newRoot_);

        IRubyObject root = root(context);
        if (root.isNil()) {
            Node newRootNode;
            if (getDocument() == newRoot.getOwnerDocument()) {
                newRootNode = newRoot.getNode();
            } else {
                // must copy otherwise newRoot may exist in two places
                // with different owner document.
                newRootNode = getDocument().importNode(newRoot.getNode(), true);
            }
            add_child_node(context, fromNodeOrCreate(context, newRootNode));
        } else {
            Node rootNode = asXmlNode(context, root).node;
            fromNode(context, rootNode).replace_node(context, newRoot);
        }

        return newRoot;
    }

    @JRubyMethod
    public IRubyObject version(ThreadContext context) {
        return stringOrNil(context.getRuntime(), getDocument().getXmlVersion());
    }

    @JRubyMethod
    public IRubyObject in_context(ThreadContext context) {
        throw getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod(meta = true)
    public static IRubyObject substitute_entities_set(ThreadContext context, IRubyObject cls, IRubyObject value) {
        XmlDocument.substituteEntities = value.isTrue();
        return context.getRuntime().getNil();
    }

    public IRubyObject getInternalSubset(ThreadContext context) {
        IRubyObject dtd =
            (IRubyObject) node.getUserData(DTD_INTERNAL_SUBSET);

        if (dtd == null) {
            if (getDocument().getDoctype() == null)
                dtd = context.getRuntime().getNil();
            else
                dtd = XmlDtd.newFromInternalSubset(context.getRuntime(),
                                                   getDocument());

            setInternalSubset(dtd);
        }

        return dtd;
    }

    /**
     * Assumes XmlNode#internal_subset() has returned nil. (i.e. there
     * is not already an internal subset).
     */
    public IRubyObject createInternalSubset(ThreadContext context,
                                            IRubyObject name,
                                            IRubyObject external_id,
                                            IRubyObject system_id) {
        XmlDtd dtd = XmlDtd.newEmpty(context.getRuntime(),
                                     this.getDocument(),
                                     name, external_id, system_id);
        setInternalSubset(dtd);
        return dtd;
    }

    protected void setInternalSubset(IRubyObject data) {
        node.setUserData(DTD_INTERNAL_SUBSET, data, null);
    }

    public IRubyObject getExternalSubset(ThreadContext context) {
        IRubyObject dtd = (IRubyObject)
            node.getUserData(DTD_EXTERNAL_SUBSET);

        if (dtd == null) {
            dtd = XmlDtd.newFromExternalSubset(context.getRuntime(),
                                               getDocument());
            setExternalSubset(dtd);
        }

        return dtd;
    }

    /**
     * Assumes XmlNode#external_subset() has returned nil. (i.e. there
     * is not already an external subset).
     */
    public IRubyObject createExternalSubset(ThreadContext context,
                                            IRubyObject name,
                                            IRubyObject external_id,
                                            IRubyObject system_id) {
        XmlDtd dtd = XmlDtd.newEmpty(context.getRuntime(),
                                     this.getDocument(),
                                     name, external_id, system_id);
        setExternalSubset(dtd);
        return dtd;
    }

    protected void setExternalSubset(IRubyObject data) {
        node.setUserData(DTD_EXTERNAL_SUBSET, data, null);
    }

    //public IRubyObject createE

    @Override
    public void saveContent(ThreadContext context, SaveContext ctx) {
        if(!ctx.noDecl()) {
            ctx.append("<?xml version=\"");
            ctx.append(getDocument().getXmlVersion());
            ctx.append("\"");
//            if(!cur.encoding(context).isNil()) {
//                ctx.append(" encoding=");
//                ctx.append(cur.encoding(context).asJavaString());
//            }

            String encoding = ctx.getEncoding();

            if(encoding == null &&
                    !encoding(context).isNil()) {
                encoding = encoding(context).convertToString().asJavaString();
            }

            if(encoding != null) {
                ctx.append(" encoding=\"");
                ctx.append(encoding);
                ctx.append("\"");
            }

            //ctx.append(" standalone=\"");
            //ctx.append(getDocument().getXmlStandalone() ? "yes" : "no");
            ctx.append("?>\n");
        }

        IRubyObject maybeRoot = root(context);
        if (maybeRoot.isNil())
            throw context.getRuntime().newRuntimeError("no root document");

        XmlNode root = (XmlNode) maybeRoot;
        root.saveContent(context, ctx);
        ctx.append("\n");
    }
}
