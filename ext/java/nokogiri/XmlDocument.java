package nokogiri;

import static nokogiri.internals.NokogiriHelpers.getCachedNodeOrCreate;
import static nokogiri.internals.NokogiriHelpers.getLocalNameForNamespace;
import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;
import static nokogiri.internals.NokogiriHelpers.isNamespace;
import static nokogiri.internals.NokogiriHelpers.stringOrNil;

import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import nokogiri.internals.NokogiriHelpers;
import nokogiri.internals.NokogiriNamespaceCache;
import nokogiri.internals.SaveContext;
import nokogiri.internals.XmlDomParserContext;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyNil;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.Arity;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Attr;
import org.w3c.dom.Document;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

@JRubyClass(name="Nokogiri::XML::Document", parent="Nokogiri::XML::Node")
public class XmlDocument extends XmlNode {
    private NokogiriNamespaceCache nsCache;
    
    /* UserData keys for storing extra info in the document node. */
    public final static String DTD_RAW_DOCUMENT = "DTD_RAW_DOCUMENT";
    protected final static String DTD_INTERNAL_SUBSET = "DTD_INTERNAL_SUBSET";
    protected final static String DTD_EXTERNAL_SUBSET = "DTD_EXTERNAL_SUBSET";

    private static boolean substituteEntities = false;
    private static boolean loadExternalSubset = false; // TODO: Verify this.

    /** cache variables */
    protected IRubyObject encoding = null;
    protected IRubyObject url = null;

    public XmlDocument(Ruby ruby, RubyClass klazz) {
        super(ruby, klazz);
        nsCache = new NokogiriNamespaceCache();
    }
    
    public XmlDocument(Ruby ruby, Document document) {
        this(ruby, getNokogiriClass(ruby, "Nokogiri::XML::Document"), document);
    }

    public XmlDocument(Ruby ruby, RubyClass klass, Document document) {
        super(ruby, klass, document);
        nsCache = new NokogiriNamespaceCache();
        createAndCacheNamespaces(ruby, document.getDocumentElement());
        stabilizeTextContent(document);
        setInstanceVariable("@decorators", ruby.getNil());
    }
    
    public void setEncoding(IRubyObject encoding) {
        this.encoding = encoding;
    }
    
    // not sure, but like attribute values, text value will be lost
    // unless it is referred once before this document is used.
    // this seems to happen only when the fragment is parsed from Node#in_context.
    private void stabilizeTextContent(Document document) {
        if (document.getDocumentElement() != null) document.getDocumentElement().getTextContent();
    }

    private void createAndCacheNamespaces(Ruby ruby, Node node) {
        if (node == null) return;
        if (node.hasAttributes()) {
            NamedNodeMap nodeMap = node.getAttributes();
            for (int i=0; i<nodeMap.getLength(); i++) {
                Node n = nodeMap.item(i);
                if (n instanceof Attr) {
                    Attr attr = (Attr)n;
                    String attrName = attr.getName();
                    // not sure, but need to get value always before document is referred.
                    // or lose attribute value
                    String attrValue = attr.getValue();
                    if (isNamespace(attrName)) {
                        String prefix = getLocalNameForNamespace(attrName);
                        prefix = prefix != null ? prefix : "";
                        nsCache.put(ruby, prefix, attrValue, node, this);
                    }
                }
            }
        }
        NodeList children = node.getChildNodes();
        for (int i=0; i<children.getLength(); i++) {
            createAndCacheNamespaces(ruby, children.item(i));
        }
    }
    
    // When a document is created from fragment with a context (reference) document,
    // namespace should be resolved based on the context document.
    public XmlDocument(Ruby ruby, RubyClass klass, Document document, XmlDocument contextDoc) {
        super(ruby, klass, document);
        nsCache = contextDoc.getNamespaceCache();
        XmlNamespace default_ns = nsCache.getDefault();
        String default_href = (String)(default_ns.href(ruby.getCurrentContext())).toJava(String.class);
        resolveNamespaceIfNecessary(ruby.getCurrentContext(), document.getDocumentElement(), default_href);
    }
    
    private void resolveNamespaceIfNecessary(ThreadContext context, Node node, String default_href) {
        if (node == null) return;
        String nodePrefix = node.getPrefix();
        if (nodePrefix == null) { // default namespace
            node.getOwnerDocument().renameNode(node, default_href, node.getNodeName());
        } else {
            XmlNamespace xmlNamespace = nsCache.get(nodePrefix);
            String href = (String)xmlNamespace.href(context).toJava(String.class);
            node.getOwnerDocument().renameNode(node, href, node.getNodeName());
        }
        resolveNamespaceIfNecessary(context, node.getNextSibling(), default_href);
        NodeList children = node.getChildNodes();
        for (int i=0; i<children.getLength(); i++) {
            resolveNamespaceIfNecessary(context, children.item(i), default_href);
        }   
    }

    public NokogiriNamespaceCache getNamespaceCache() {
        return nsCache;
    }
    
    public void setNamespaceCache(NokogiriNamespaceCache nsCache) {
        this.nsCache = nsCache;
    }

    public Document getDocument() {
        return (Document) node;
    }
    
    @Override
    protected IRubyObject getNodeName(ThreadContext context) {
        return JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), "document");
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
            return DocumentBuilderFactory.newInstance().newDocumentBuilder().newDocument();
        } catch (ParserConfigurationException e) {
            return null;        // this will end is disaster...
        }
    }

    /*
     * call-seq:
     *  new(version = default)
     *
     * Create a new document with +version+ (defaults to "1.0")
     */
    @JRubyMethod(name="new", meta = true, rest = true, required=0)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject[] args) {
        XmlDocument doc = null;
        try {
            Document docNode = createNewDocument();
            doc = new XmlDocument(context.getRuntime(), (RubyClass) cls, docNode);
        } catch (Exception ex) {
            throw context.getRuntime().newRuntimeError("couldn't create document: "+ex.toString());
        }

        RuntimeHelpers.invoke(context, doc, "initialize", args);

        return doc;
    }
    
    @JRubyMethod(required=1, optional=4)
    public IRubyObject create_entity(ThreadContext context, IRubyObject[] argv) {
        // FIXME: Entity node should be create by some right way.
        // this impl passes tests, but entity doesn't exists in DTD, which
        // would cause validation failure.
        if (argv.length == 0) throw context.getRuntime().newRuntimeError("Could not create entity");
        String tagName = (String) argv[0].toJava(String.class);
        Node n = this.getOwnerDocument().createElement(tagName);
        return XmlEntityDecl.create(context, n, argv);
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
            new XmlDomParserContext(ruby, args[2], args[3]);
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
                           getNokogiriClass(context.getRuntime(), "Nokogiri::XML::Document"),
                           args);
    }
    
    @JRubyMethod(name="remove_namespaces!")
    public IRubyObject remove_namespaces(ThreadContext context) {
        removeNamespceRecursively(context, this);
        nsCache.clear();
        return this;
    }
    
    private void removeNamespceRecursively(ThreadContext context, XmlNode xmlNode) {
        Node node = xmlNode.node;
        if (node.getNodeType() == Node.ELEMENT_NODE) {
            node.setPrefix(null);
            node.getOwnerDocument().renameNode(node, null, node.getLocalName());
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
        try {
            Boolean isValid = (Boolean)rootNode.getUserData(NokogiriHelpers.VALID_ROOT_NODE);
            if (!isValid) return context.getRuntime().getNil();
        } catch (NullPointerException e) {
            // does nothing since nil wasn't set to the root node before.
        }
        if (rootNode == null)
            return context.getRuntime().getNil();
        else
            return getCachedNodeOrCreate(context.getRuntime(), rootNode);
    }

    @JRubyMethod(name="root=")
    public IRubyObject root_set(ThreadContext context, IRubyObject newRoot_) {
        // in case of document fragment, temporary root node should be deleted.
        
        // Java can't have a root whose value is null. Instead of setting null,
        // the method sets user data so that other methods are able to know the root
        // should be nil.
        if (newRoot_ instanceof RubyNil) {
            getDocument().getDocumentElement().setUserData(NokogiriHelpers.VALID_ROOT_NODE, false, null);
            return newRoot_;
        }
        XmlNode newRoot = asXmlNode(context, newRoot_);

        IRubyObject root = root(context);
        if (root.isNil()) {
            Node newRootNode;
            if (getDocument() == newRoot.getOwnerDocument()) {
                newRootNode = newRoot.node;
            } else {
                // must copy otherwise newRoot may exist in two places
                // with different owner document.
                newRootNode = getDocument().importNode(newRoot.node, true);
            }
            add_child_node(context, getCachedNodeOrCreate(context.getRuntime(), newRootNode));
        } else {
            Node rootNode = asXmlNode(context, root).node;
            ((XmlNode)getCachedNodeOrCreate(context.getRuntime(), rootNode)).replace_node(context, newRoot);
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
