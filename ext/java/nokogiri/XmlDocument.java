/**
 * (The MIT License)
 *
 * Copyright (c) 2008 - 2011:
 *
 * * {Aaron Patterson}[http://tenderlovemaking.com]
 * * {Mike Dalessio}[http://mike.daless.io]
 * * {Charles Nutter}[http://blog.headius.com]
 * * {Sergio Arbeo}[http://www.serabe.com]
 * * {Patrick Mahoney}[http://polycrystal.org]
 * * {Yoko Harada}[http://yokolet.blogspot.com]
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * 'Software'), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

package nokogiri;

import static nokogiri.internals.NokogiriHelpers.getCachedNodeOrCreate;
import static nokogiri.internals.NokogiriHelpers.getLocalNameForNamespace;
import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;
import static nokogiri.internals.NokogiriHelpers.isNamespace;
import static nokogiri.internals.NokogiriHelpers.rubyStringToString;
import static nokogiri.internals.NokogiriHelpers.stringOrNil;

import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import nokogiri.internals.NokogiriHelpers;
import nokogiri.internals.NokogiriNamespaceCache;
import nokogiri.internals.SaveContextVisitor;
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

/**
 * Class for Nokogiri::XML::Document
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */

@JRubyClass(name="Nokogiri::XML::Document", parent="Nokogiri::XML::Node")
public class XmlDocument extends XmlNode {
    private NokogiriNamespaceCache nsCache;
    
    /* UserData keys for storing extra info in the document node. */
    public final static String DTD_RAW_DOCUMENT = "DTD_RAW_DOCUMENT";
    public final static String DTD_INTERNAL_SUBSET = "DTD_INTERNAL_SUBSET";
    public final static String DTD_EXTERNAL_SUBSET = "DTD_EXTERNAL_SUBSET";
    
    /* DocumentBuilderFactory implementation class name. This needs to set a classloader into it.
     * Setting an appropriate classloader resolves issue 380.
     */
    private static final String DOCUMENTBUILDERFACTORY_IMPLE_NAME = "org.apache.xerces.jaxp.DocumentBuilderFactoryImpl";

    private static boolean substituteEntities = false;
    private static boolean loadExternalSubset = false; // TODO: Verify this.

    /** cache variables */
    protected IRubyObject encoding = null;
    protected IRubyObject url = null;

    public XmlDocument(Ruby ruby, RubyClass klazz) {
        super(ruby, klazz, createNewDocument());
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
    
    @Override
    public void setNode(ThreadContext context, Node node) {
        super.setNode(context, node);
        if (nsCache == null) nsCache = new NokogiriNamespaceCache();
        Ruby runtime = context.getRuntime();
        if (node != null) {
            Document document = (Document)node;
            stabilizeTextContent(document);
            createAndCacheNamespaces(runtime, document.getDocumentElement());
        }
        setInstanceVariable("@decorators", runtime.getNil());
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
                    String attrValue = attr.getValue(); // don't delete this line
                    if (isNamespace(attrName)) {
                        // create and cache
                        XmlNamespace.createFromAttr(ruby, attr);
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
        String default_href = rubyStringToString(default_ns.href(ruby.getCurrentContext()));
        resolveNamespaceIfNecessary(ruby.getCurrentContext(), document.getDocumentElement(), default_href);
    }
    
    private void resolveNamespaceIfNecessary(ThreadContext context, Node node, String default_href) {
        if (node == null) return;
        String nodePrefix = node.getPrefix();
        if (nodePrefix == null) { // default namespace
            node.getOwnerDocument().renameNode(node, default_href, node.getNodeName());
        } else {
            XmlNamespace xmlNamespace = nsCache.get(nodePrefix);
            String href = rubyStringToString(xmlNamespace.href(context));
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
        if (name == null) name = context.getRuntime().newString("document");
        return name;
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
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance(DOCUMENTBUILDERFACTORY_IMPLE_NAME, NokogiriService.class.getClassLoader());
            return factory.newDocumentBuilder().newDocument();
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
    public static IRubyObject rbNew(ThreadContext context, IRubyObject klazz, IRubyObject[] args) {
        XmlDocument xmlDocument = null;
        try {
            Document docNode = createNewDocument();
            if ("Nokogiri::HTML::Document".equals(((RubyClass)klazz).getName())) {
                xmlDocument = (XmlDocument) NokogiriService.HTML_DOCUMENT_ALLOCATOR.allocate(context.getRuntime(), (RubyClass) klazz);
                xmlDocument.setNode(context, docNode);
            } else {
                // XML::Document and sublass
                xmlDocument = (XmlDocument) NokogiriService.XML_DOCUMENT_ALLOCATOR.allocate(context.getRuntime(), (RubyClass) klazz);
                xmlDocument.setNode(context, docNode);
            }
        } catch (Exception ex) {
            throw context.getRuntime().newRuntimeError("couldn't create document: "+ex.toString());
        }

        RuntimeHelpers.invoke(context, xmlDocument, "initialize", args);

        return xmlDocument;
    }
    
    @JRubyMethod(required=1, optional=4)
    public IRubyObject create_entity(ThreadContext context, IRubyObject[] argv) {
        // FIXME: Entity node should be create by some right way.
        // this impl passes tests, but entity doesn't exists in DTD, which
        // would cause validation failure.
        if (argv.length == 0) throw context.getRuntime().newRuntimeError("Could not create entity");
        String tagName = rubyStringToString(argv[0]);
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
        ctx.setInputSource(context, args[0], args[1]);
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
            NamedNodeMap attrs = node.getAttributes();
            for (int i=0; i<attrs.getLength(); i++) {
                Attr attr = (Attr) attrs.item(i);
                if (isNamespace(attr.getNodeName())) {
                    ((org.w3c.dom.Element)node).removeAttributeNode(attr);
                } else {
                    attr.setPrefix(null);
                    attr.getOwnerDocument().renameNode(attr, null, attr.getLocalName());
                }
            }
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

    @JRubyMethod(meta = true)
    public static IRubyObject substitute_entities_set(ThreadContext context, IRubyObject cls, IRubyObject value) {
        XmlDocument.substituteEntities = value.isTrue();
        return context.getRuntime().getNil();
    }

    public IRubyObject getInternalSubset(ThreadContext context) {
        IRubyObject dtd = (IRubyObject) node.getUserData(DTD_INTERNAL_SUBSET);

        if (dtd == null) {
            if (getDocument().getDoctype() == null) dtd = context.getRuntime().getNil();
            else dtd = XmlDtd.newFromInternalSubset(context.getRuntime(), getDocument());
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
        IRubyObject dtd = (IRubyObject) node.getUserData(DTD_EXTERNAL_SUBSET);

        if (dtd == null) return context.getRuntime().getNil();
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

    @Override
    public void accept(ThreadContext context, SaveContextVisitor visitor) {
        Document document = getDocument();
        visitor.enter(document);
        NodeList children = document.getChildNodes();
        for (int i=0; i<children.getLength(); i++) {
            Node child = children.item(i);
            short type = child.getNodeType();
            if (type == Node.COMMENT_NODE) {
                XmlComment xmlComment = (XmlComment) getCachedNodeOrCreate(context.getRuntime(), child);
                xmlComment.accept(context, visitor);
            } else if (type == Node.DOCUMENT_TYPE_NODE) {
                XmlDtd xmlDtd = (XmlDtd) getCachedNodeOrCreate(context.getRuntime(), child);
                xmlDtd.accept(context, visitor);
            } else if (type == Node.PROCESSING_INSTRUCTION_NODE) {
                XmlProcessingInstruction xmlProcessingInstruction = (XmlProcessingInstruction) getCachedNodeOrCreate(context.getRuntime(), child);
                xmlProcessingInstruction.accept(context, visitor);
            } else if (type == Node.TEXT_NODE) {
                XmlText xmlText = (XmlText) getCachedNodeOrCreate(context.getRuntime(), child);
                xmlText.accept(context, visitor);
            } else if (type == Node.ELEMENT_NODE) {
                XmlElement xmlElement = (XmlElement) getCachedNodeOrCreate(context.getRuntime(), child);
                xmlElement.accept(context, visitor);
            }
        }
        visitor.leave(document);
    }
    
    @JRubyMethod(meta=true)
    public static IRubyObject wrapJavaDocument(ThreadContext context, IRubyObject klazz, IRubyObject arg) {
        XmlDocument xmlDocument = (XmlDocument) NokogiriService.XML_DOCUMENT_ALLOCATOR.allocate(context.getRuntime(), getNokogiriClass(context.getRuntime(), "Nokogiri::XML::Document"));
        Document document = (Document)arg.toJava(Document.class);
        xmlDocument.setNode(context, document);
        return xmlDocument;
    }
    
    @JRubyMethod
    public IRubyObject toJavaDocument(ThreadContext context) {
        return JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), (org.w3c.dom.Document)node);
    }
}
