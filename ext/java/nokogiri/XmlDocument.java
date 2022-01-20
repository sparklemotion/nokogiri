package nokogiri;

import static nokogiri.internals.NokogiriHelpers.clearXpathContext;
import static nokogiri.internals.NokogiriHelpers.getCachedNodeOrCreate;
import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;
import static nokogiri.internals.NokogiriHelpers.isNamespace;
import static nokogiri.internals.NokogiriHelpers.rubyStringToString;
import static nokogiri.internals.NokogiriHelpers.stringOrNil;

import java.util.List;
import java.io.ByteArrayOutputStream;

import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import org.jcodings.specific.USASCIIEncoding;
import org.jcodings.specific.UTF8Encoding;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.Block;
import org.jruby.runtime.Helpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.Visibility;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;
import org.w3c.dom.Attr;
import org.w3c.dom.Document;
import org.w3c.dom.DocumentType;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import org.apache.xml.security.exceptions.XMLSecurityException;
import org.apache.xml.security.c14n.Canonicalizer;

import nokogiri.internals.NokogiriHelpers;
import nokogiri.internals.NokogiriNamespaceCache;
import nokogiri.internals.SaveContextVisitor;
import nokogiri.internals.XmlDomParserContext;

/**
 * Class for Nokogiri::XML::Document
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 * @author John Shahid <jvshahid@gmail.com>
 */
@JRubyClass(name = "Nokogiri::XML::Document", parent = "Nokogiri::XML::Node")
public class XmlDocument extends XmlNode
{
  private static final long serialVersionUID = 1L;

  private NokogiriNamespaceCache nsCache;

  /* UserData keys for storing extra info in the document node. */
  public final static String DTD_RAW_DOCUMENT = "DTD_RAW_DOCUMENT";
  public final static String DTD_INTERNAL_SUBSET = "DTD_INTERNAL_SUBSET";
  public final static String DTD_EXTERNAL_SUBSET = "DTD_EXTERNAL_SUBSET";

  /* DocumentBuilderFactory implementation class name. This needs to set a classloader into it.
   * Setting an appropriate classloader resolves issue 380.
   */
  private static final String DOCUMENTBUILDERFACTORY_IMPLE_NAME = "org.apache.xerces.jaxp.DocumentBuilderFactoryImpl";

  private static final ByteList DOCUMENT = ByteList.create("document");
  static { DOCUMENT.setEncoding(USASCIIEncoding.INSTANCE); }

  private static boolean substituteEntities = false;
  private static boolean loadExternalSubset = false; // TODO: Verify this.

  /** cache variables */
  protected IRubyObject encoding;
  protected IRubyObject url;

  public
  XmlDocument(Ruby runtime, RubyClass klazz)
  {
    super(runtime, klazz, createNewDocument(runtime));
  }

  public
  XmlDocument(Ruby runtime, Document document)
  {
    this(runtime, getNokogiriClass(runtime, "Nokogiri::XML::Document"), document);
  }

  public
  XmlDocument(Ruby runtime, RubyClass klass, Document document)
  {
    super(runtime, klass, document);
    init(runtime, document);
  }

  void
  init(Ruby runtime, Document document)
  {
    stabilizeTextContent(document);
    if (document.getDocumentElement() != null) {
      createAndCacheNamespaces(runtime, document.getDocumentElement());
    }
    setInstanceVariable("@decorators", runtime.getNil());
  }

  public final void
  setDocumentNode(Ruby runtime, Document node)
  {
    super.setNode(runtime, node);
    if (node != null) { init(runtime, node); }
    else { setInstanceVariable("@decorators", runtime.getNil()); }
  }

  public void
  setEncoding(IRubyObject encoding)
  {
    this.encoding = encoding;
  }

  public IRubyObject
  getEncoding()
  {
    return encoding;
  }

  // not sure, but like attribute values, text value will be lost
  // unless it is referred once before this document is used.
  // this seems to happen only when the fragment is parsed from Node#in_context.
  protected static void
  stabilizeTextContent(Document document)
  {
    if (document.getDocumentElement() != null) { document.getDocumentElement().getTextContent(); }
  }

  private static void
  createAndCacheNamespaces(Ruby runtime, Node node)
  {
    if (node.hasAttributes()) {
      NamedNodeMap nodeMap = node.getAttributes();
      for (int i = 0; i < nodeMap.getLength(); i++) {
        Node n = nodeMap.item(i);
        if (n instanceof Attr) {
          Attr attr = (Attr) n;
          stabilizeAttr(attr);
          if (isNamespace(attr.getName())) {
            // create and cache
            XmlNamespace.createFromAttr(runtime, attr);
          }
        }
      }
    }
    NodeList children = node.getChildNodes();
    for (int i = 0; i < children.getLength(); i++) {
      createAndCacheNamespaces(runtime, children.item(i));
    }
  }

  static void
  stabilizeAttr(final Attr attr)
  {
    // TODO not sure, but need to get value always before document is referred or lose attribute value
    attr.getValue(); // don't delete this line
  }

  // When a document is created from fragment with a context (reference) document,
  // namespace should be resolved based on the context document.
  public
  XmlDocument(Ruby ruby, RubyClass klass, Document document, XmlDocument contextDoc)
  {
    super(ruby, klass, document);
    nsCache = contextDoc.getNamespaceCache();
    String default_href = nsCache.getDefault().getHref();
    resolveNamespaceIfNecessary(document.getDocumentElement(), default_href);
  }

  private void
  resolveNamespaceIfNecessary(Node node, String default_href)
  {
    if (node == null) { return; }
    String nodePrefix = node.getPrefix();
    if (nodePrefix == null) { // default namespace
      NokogiriHelpers.renameNode(node, default_href, node.getNodeName());
    } else {
      String href = getNamespaceCache().get(node, nodePrefix).getHref();
      NokogiriHelpers.renameNode(node, href, node.getNodeName());
    }
    resolveNamespaceIfNecessary(node.getNextSibling(), default_href);
    NodeList children = node.getChildNodes();
    for (int i = 0; i < children.getLength(); i++) {
      resolveNamespaceIfNecessary(children.item(i), default_href);
    }
  }

  public NokogiriNamespaceCache
  getNamespaceCache()
  {
    if (nsCache == null) { nsCache = new NokogiriNamespaceCache(); }
    return nsCache;
  }

  public Document
  getDocument()
  {
    return (Document) node;
  }

  @Override
  protected IRubyObject
  getNodeName(ThreadContext context)
  {
    if (name == null) { name = RubyString.newStringShared(context.runtime, DOCUMENT); }
    return name;
  }

  public void
  setUrl(IRubyObject url)
  {
    this.url = url;
  }

  protected IRubyObject
  getUrl()
  {
    return this.url;
  }

  @JRubyMethod
  public IRubyObject
  url(ThreadContext context)
  {
    return getUrl();
  }

  public static Document
  createNewDocument(final Ruby runtime)
  {
    try {
      return DocumentBuilderFactoryHolder.INSTANCE.newDocumentBuilder().newDocument();
    } catch (ParserConfigurationException e) {
      throw asRuntimeError(runtime, null, e);
    }
  }

  private static class DocumentBuilderFactoryHolder
  {
    static final DocumentBuilderFactory INSTANCE;
    static
    {
      INSTANCE = DocumentBuilderFactory.newInstance(DOCUMENTBUILDERFACTORY_IMPLE_NAME,
                 NokogiriService.class.getClassLoader());
    }
  }

  static RaiseException
  asRuntimeError(Ruby runtime, String message, Exception cause)
  {
    if (cause instanceof RaiseException) { return (RaiseException) cause; }

    if (message == null) { message = cause.toString(); }
    else { message = message + '(' + cause.toString() + ')'; }
    RaiseException ex = runtime.newRuntimeError(message);
    ex.initCause(cause);
    return ex;
  }

  /*
   * call-seq:
   *  new(version = default)
   *
   * Create a new document with +version+ (defaults to "1.0")
   */
  @JRubyMethod(name = "new", meta = true, rest = true, required = 0)
  public static IRubyObject
  rbNew(ThreadContext context, IRubyObject klazz, IRubyObject[] args)
  {
    final Ruby runtime = context.runtime;
    XmlDocument xmlDocument;
    try {
      Document docNode = createNewDocument(runtime);
      if ("Nokogiri::HTML4::Document".equals(((RubyClass)klazz).getName())) {
        xmlDocument = new Html4Document(context.runtime, (RubyClass) klazz, docNode);
      } else {
        xmlDocument = new XmlDocument(context.runtime, (RubyClass) klazz, docNode);
      }
    } catch (Exception ex) {
      throw asRuntimeError(runtime, "couldn't create document: ", ex);
    }

    Helpers.invoke(context, xmlDocument, "initialize", args);

    return xmlDocument;
  }

  @JRubyMethod(required = 1, optional = 4)
  public IRubyObject
  create_entity(ThreadContext context, IRubyObject[] argv)
  {
    // FIXME: Entity node should be create by some right way.
    // this impl passes tests, but entity doesn't exists in DTD, which
    // would cause validation failure.
    if (argv.length == 0) { throw context.runtime.newRuntimeError("Could not create entity"); }
    String tagName = rubyStringToString(argv[0]);
    Node node = getOwnerDocument().createElement(tagName);
    return XmlEntityDecl.create(context, node, argv);
  }

  @Override
  XmlDocument
  document(Ruby runtime)
  {
    return this;
  }

  @JRubyMethod(name = "encoding=")
  public IRubyObject
  encoding_set(IRubyObject encoding)
  {
    this.encoding = encoding;
    return this;
  }

  @JRubyMethod
  public IRubyObject
  encoding(ThreadContext context)
  {
    if (this.encoding == null || this.encoding.isNil()) {
      final String enc = getDocument().getXmlEncoding();
      if (enc == null) {
        this.encoding = context.nil;
      } else {
        this.encoding = context.runtime.newString(enc);
      }
    }

    return this.encoding.isNil() ? this.encoding : this.encoding.asString().encode(context,
           context.getRuntime().newString("UTF-8"));
  }

  @JRubyMethod(meta = true)
  public static IRubyObject
  load_external_subsets_set(ThreadContext context, IRubyObject cls, IRubyObject value)
  {
    XmlDocument.loadExternalSubset = value.isTrue();
    return context.nil;
  }

  @JRubyMethod(meta = true, required = 4)
  public static IRubyObject
  read_io(ThreadContext context, IRubyObject klass, IRubyObject[] args)
  {
    XmlDomParserContext ctx = new XmlDomParserContext(context.runtime, args[2], args[3]);
    ctx.setIOInputSource(context, args[0], args[1]);
    return ctx.parse(context, (RubyClass) klass, args[1]);
  }

  @JRubyMethod(meta = true, required = 4)
  public static IRubyObject
  read_memory(ThreadContext context, IRubyObject klass, IRubyObject[] args)
  {
    XmlDomParserContext ctx = new XmlDomParserContext(context.runtime, args[2], args[3]);
    ctx.setStringInputSource(context, args[0], args[1]);
    return ctx.parse(context, (RubyClass) klass, args[1]);
  }

  @JRubyMethod(name = "remove_namespaces!")
  public IRubyObject
  remove_namespaces(ThreadContext context)
  {
    removeNamespaceRecursively(this);
    if (nsCache != null) { nsCache.clear(); }
    clearXpathContext(getNode());
    return this;
  }

  private void
  removeNamespaceRecursively(XmlNode xmlNode)
  {
    Node node = xmlNode.node;
    if (node.getNodeType() == Node.ELEMENT_NODE) {
      node.setPrefix(null);
      NokogiriHelpers.renameNode(node, null, node.getLocalName());
      NamedNodeMap attrs = node.getAttributes();
      for (int i = 0; i < attrs.getLength(); i++) {
        Attr attr = (Attr) attrs.item(i);
        if (isNamespace(attr.getNodeName())) {
          ((org.w3c.dom.Element) node).removeAttributeNode(attr);
        } else {
          attr.setPrefix(null);
          NokogiriHelpers.renameNode(attr, null, attr.getLocalName());
        }
      }
    }
    IRubyObject[] nodes = xmlNode.getChildren();
    for (int i = 0; i < nodes.length; i++) {
      XmlNode childNode = (XmlNode) nodes[i];
      removeNamespaceRecursively(childNode);
    }
  }

  @JRubyMethod
  public IRubyObject
  root(ThreadContext context)
  {
    Node rootNode = getDocument().getDocumentElement();
    if (rootNode == null) { return context.nil; }

    Object invalid = rootNode.getUserData(NokogiriHelpers.ROOT_NODE_INVALID);
    if (invalid != null && ((Boolean) invalid)) { return context.nil; }

    return getCachedNodeOrCreate(context.runtime, rootNode);
  }

  protected IRubyObject
  dup_implementation(Ruby runtime, boolean deep)
  {
    XmlDocument doc = (XmlDocument) super.dup_implementation(runtime, deep);
    // Avoid creating a new XmlDocument since we cloned one
    // already. Otherwise the following test will fail:
    //
    //   dup = doc.dup
    //   dup.equal?(dup.children[0].document)
    //
    // Since `dup.children[0].document' will end up creating a new
    // XmlDocument.  See #1060.
    doc.resetCache();
    return doc;
  }

  @JRubyMethod(name = "root=")
  public IRubyObject
  root_set(ThreadContext context, IRubyObject new_root)
  {
    // in case of document fragment, temporary root node should be deleted.

    // Java can't have a root whose value is null. Instead of setting null,
    // the method sets user data so that other methods are able to know the root
    // should be nil.
    if (new_root == context.nil) {
      getDocument().getDocumentElement().setUserData(NokogiriHelpers.ROOT_NODE_INVALID, Boolean.TRUE, null);
      return new_root;
    }
    if (!(new_root instanceof XmlNode)) {
      throw context.runtime.newArgumentError("expected Nokogiri::XML::Node but received " + new_root.getType());
    }
    XmlNode newRoot = asXmlNode(context, new_root);

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
      add_child_node(context, getCachedNodeOrCreate(context.runtime, newRootNode));
    } else {
      Node rootNode = asXmlNode(context, root).node;
      ((XmlNode) getCachedNodeOrCreate(context.runtime, rootNode)).replace_node(context, newRoot);
    }

    return newRoot;
  }

  @JRubyMethod
  public IRubyObject
  version(ThreadContext context)
  {
    return stringOrNil(context.runtime, getDocument().getXmlVersion());
  }

  @JRubyMethod(meta = true)
  public static IRubyObject
  substitute_entities_set(ThreadContext context, IRubyObject cls, IRubyObject value)
  {
    XmlDocument.substituteEntities = value.isTrue();
    return context.nil;
  }

  public IRubyObject
  getInternalSubset(ThreadContext context)
  {
    IRubyObject dtd = (IRubyObject) node.getUserData(DTD_INTERNAL_SUBSET);

    if (dtd == null) {
      Document document = getDocument();
      if (document.getUserData(XmlDocument.DTD_RAW_DOCUMENT) != null) {
        dtd = XmlDtd.newFromInternalSubset(context.runtime, document);
      } else if (document.getDoctype() != null) {
        DocumentType docType = document.getDoctype();
        IRubyObject name, publicId, systemId;
        name = publicId = systemId = context.nil;
        if (docType.getName() != null) {
          name = context.runtime.newString(docType.getName());
        }
        if (docType.getPublicId() != null) {
          publicId = context.runtime.newString(docType.getPublicId());
        }
        if (docType.getSystemId() != null) {
          systemId = context.runtime.newString(docType.getSystemId());
        }
        dtd = XmlDtd.newEmpty(context.runtime, document, name, publicId, systemId);
      } else {
        dtd = context.nil;
      }

      setInternalSubset(dtd);
    }

    return dtd;
  }

  /**
   * Assumes XmlNode#internal_subset() has returned nil. (i.e. there
   * is not already an internal subset).
   */
  public IRubyObject
  createInternalSubset(ThreadContext context,
                       IRubyObject name,
                       IRubyObject external_id,
                       IRubyObject system_id)
  {
    XmlDtd dtd = XmlDtd.newEmpty(context.runtime, getDocument(), name, external_id, system_id);
    setInternalSubset(dtd);
    return dtd;
  }

  protected void
  setInternalSubset(IRubyObject data)
  {
    node.setUserData(DTD_INTERNAL_SUBSET, data, null);
  }

  public IRubyObject
  getExternalSubset(ThreadContext context)
  {
    IRubyObject dtd = (IRubyObject) node.getUserData(DTD_EXTERNAL_SUBSET);

    if (dtd == null) { return context.nil; }
    return dtd;
  }

  /**
   * Assumes XmlNode#external_subset() has returned nil. (i.e. there
   * is not already an external subset).
   */
  public IRubyObject
  createExternalSubset(ThreadContext context,
                       IRubyObject name,
                       IRubyObject external_id,
                       IRubyObject system_id)
  {
    XmlDtd dtd = XmlDtd.newEmpty(context.runtime, getDocument(), name, external_id, system_id);
    setExternalSubset(dtd);
    return dtd;
  }

  protected void
  setExternalSubset(IRubyObject data)
  {
    node.setUserData(DTD_EXTERNAL_SUBSET, data, null);
  }

  @Override
  public void
  accept(ThreadContext context, SaveContextVisitor visitor)
  {
    Document document = getDocument();
    visitor.enter(document);
    NodeList children = document.getChildNodes();
    for (int i = 0; i < children.getLength(); i++) {
      Node child = children.item(i);
      short type = child.getNodeType();
      if (type == Node.COMMENT_NODE) {
        XmlComment xmlComment = (XmlComment) getCachedNodeOrCreate(context.runtime, child);
        xmlComment.accept(context, visitor);
      } else if (type == Node.DOCUMENT_TYPE_NODE) {
        XmlDtd xmlDtd = (XmlDtd) getCachedNodeOrCreate(context.runtime, child);
        xmlDtd.accept(context, visitor);
      } else if (type == Node.PROCESSING_INSTRUCTION_NODE) {
        XmlProcessingInstruction xmlProcessingInstruction = (XmlProcessingInstruction) getCachedNodeOrCreate(context.runtime,
            child);
        xmlProcessingInstruction.accept(context, visitor);
      } else if (type == Node.TEXT_NODE) {
        XmlText xmlText = (XmlText) getCachedNodeOrCreate(context.runtime, child);
        xmlText.accept(context, visitor);
      } else if (type == Node.ELEMENT_NODE) {
        XmlElement xmlElement = (XmlElement) getCachedNodeOrCreate(context.runtime, child);
        xmlElement.accept(context, visitor);
      }
    }
    visitor.leave(document);
  }

  @JRubyMethod(meta = true)
  public static IRubyObject
  wrap(ThreadContext context, IRubyObject klass, IRubyObject arg)
  {
    XmlDocument xmlDocument = new XmlDocument(context.runtime, (RubyClass) klass, arg.toJava(Document.class));
    Helpers.invoke(context, xmlDocument, "initialize");
    return xmlDocument;
  }

  @Deprecated
  @JRubyMethod(meta = true, visibility = Visibility.PRIVATE)
  public static IRubyObject
  wrapJavaDocument(ThreadContext context, IRubyObject klass, IRubyObject arg)
  {
    return wrap(context, klass, arg);
  }

  @Deprecated // default to_java works (due inherited from XmlNode#toJava)
  @JRubyMethod(visibility = Visibility.PRIVATE)
  public IRubyObject
  toJavaDocument(ThreadContext context)
  {
    return JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), node);
  }

  /* call-seq:
   *  doc.canonicalize(mode=XML_C14N_1_0,inclusive_namespaces=nil,with_comments=false)
   *  doc.canonicalize { |obj, parent| ... }
   *
   * Canonicalize a document and return the results.  Takes an optional block
   * that takes two parameters: the +obj+ and that node's +parent+.
   * The  +obj+ will be either a Nokogiri::XML::Node, or a Nokogiri::XML::Namespace
   * The block must return a non-nil, non-false value if the +obj+ passed in
   * should be included in the canonicalized document.
   */
  @JRubyMethod(optional = 3)
  public IRubyObject
  canonicalize(ThreadContext context, IRubyObject[] args, Block block)
  {
    int mode = 0;
    String inclusive_namespace = null;
    Boolean with_comments = false;
    if (args.length > 0 && !(args[0].isNil())) {
      mode = RubyFixnum.fix2int(args[0]);
    }
    if (args.length > 1) {
      if (!args[1].isNil() && !(args[1] instanceof List)) {
        throw context.runtime.newTypeError("Expected array");
      }
      if (!args[1].isNil()) {
        inclusive_namespace = ((RubyArray)args[1])
                              .join(context, context.runtime.newString(" "))
                              .asString()
                              .asJavaString(); // OMG I wish I knew JRuby better, this is ugly
      }
    }
    if (args.length > 2) {
      with_comments = args[2].isTrue();
    }
    String algorithmURI = null;
    switch (mode) {
      case 0:  // XML_C14N_1_0
        if (with_comments) { algorithmURI = Canonicalizer.ALGO_ID_C14N_WITH_COMMENTS; }
        else { algorithmURI = Canonicalizer.ALGO_ID_C14N_OMIT_COMMENTS; }
        break;
      case 1:  // XML_C14N_EXCLUSIVE_1_0
        if (with_comments) { algorithmURI = Canonicalizer.ALGO_ID_C14N_EXCL_WITH_COMMENTS; }
        else { algorithmURI = Canonicalizer.ALGO_ID_C14N_EXCL_OMIT_COMMENTS; }
        break;
      case 2: // XML_C14N_1_1 = 2
        if (with_comments) { algorithmURI = Canonicalizer.ALGO_ID_C14N11_WITH_COMMENTS; }
        else { algorithmURI = Canonicalizer.ALGO_ID_C14N11_OMIT_COMMENTS; }
    }
    try {
      Canonicalizer canonicalizer = Canonicalizer.getInstance(algorithmURI);
      XmlNode startingNode = getStartingNode(block);
      ByteArrayOutputStream writer = new ByteArrayOutputStream();
      if (inclusive_namespace == null) {
        canonicalizer.canonicalizeSubtree(startingNode.getNode(), writer);
      } else {
        canonicalizer.canonicalizeSubtree(startingNode.getNode(), inclusive_namespace, writer);
      }
      return RubyString.newString(context.runtime, writer.toString());
    } catch (XMLSecurityException e) {
      throw context.getRuntime().newRuntimeError(e.getMessage());
    }
  }

  private XmlNode
  getStartingNode(Block block)
  {
    if (block.isGiven()) {
      IRubyObject boundSelf = block.getBinding().getSelf();
      if (boundSelf instanceof XmlNode) { return (XmlNode) boundSelf; }
    }
    return this;
  }

  public void
  resetNamespaceCache(ThreadContext context)
  {
    nsCache = new NokogiriNamespaceCache();
    createAndCacheNamespaces(context.runtime, node);
  }
}
