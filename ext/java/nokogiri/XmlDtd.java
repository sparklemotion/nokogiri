package nokogiri;

import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;
import static nokogiri.internals.NokogiriHelpers.nonEmptyStringOrNil;
import static nokogiri.internals.NokogiriHelpers.stringOrNil;
import static org.jruby.javasupport.util.RuntimeHelpers.invoke;
import nokogiri.internals.NokogiriHelpers;
import nokogiri.internals.SaveContext;

import org.apache.xerces.xni.QName;
import org.cyberneko.dtd.DTDConfiguration;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.w3c.dom.DocumentType;
import org.w3c.dom.Element;
import org.w3c.dom.Node;

@JRubyClass(name="Nokogiri::XML::DTD", parent="Nokogiri::XML::Node")
public class XmlDtd extends XmlNode {
    protected RubyArray allDecls = null;

    /** cache of children, Nokogiri::XML::NodeSet */
    protected IRubyObject children = null;

    /** cache of name => XmlAttributeDecl */
    protected RubyHash attributes = null;

    /** cache of name => XmlElementDecl */
    protected RubyHash elements = null;

    /** cache of name => XmlEntityDecl */
    protected RubyHash entities = null;

    /** cache of name => Nokogiri::XML::Notation */
    protected RubyHash notations = null;
    protected RubyClass notationClass;

    /** temporary store of content models before they are added to
     * their XmlElementDecl. */
    protected RubyHash contentModels;

    /** node name */
    protected IRubyObject name;

    /** public ID (or external ID) */
    protected IRubyObject pubId;

    /** system ID */
    protected IRubyObject sysId;

    public XmlDtd(Ruby ruby, RubyClass rubyClass) {
        super(ruby, rubyClass);
    }

    public XmlDtd(Ruby ruby) {
        this(ruby, getNokogiriClass(ruby, "Nokogiri::XML::DTD"), null);
    }

    public XmlDtd(Ruby ruby, Node dtd) {
        this(ruby, getNokogiriClass(ruby, "Nokogiri::XML::DTD"), dtd);
    }

    public XmlDtd(Ruby ruby, RubyClass rubyClass, Node dtd) {
        super(ruby, rubyClass, dtd);
        notationClass = (RubyClass)
            ruby.getClassFromPath("Nokogiri::XML::Notation");

        name = pubId = sysId = ruby.getNil();
        if (dtd == null) return;

        // This is the dtd declaration stored in the document; it
        // contains the DTD name (root element) and public and system
        // ids.  The actual declarations are in the NekoDTD 'dtd'
        // variable. I don't know of a way to consolidate the two.

        DocumentType otherDtd = dtd.getOwnerDocument().getDoctype();
        if (otherDtd != null) {
            name = stringOrNil(ruby, otherDtd.getNodeName());
            pubId = nonEmptyStringOrNil(ruby, otherDtd.getPublicId());
            sysId = nonEmptyStringOrNil(ruby, otherDtd.getSystemId());
        }
    }

    public static XmlDtd newEmpty(Ruby ruby,
                                  Document doc,
                                  IRubyObject name,
                                  IRubyObject external_id,
                                  IRubyObject system_id) {
        Element placeHolder = doc.createElement("dtd_placeholder");
        XmlDtd dtd = new XmlDtd(ruby, placeHolder);
        dtd.name = name;
        dtd.pubId = external_id;
        dtd.sysId = system_id;
        return dtd;
    }


    /**
     * Create an unparented element that contains DTD declarations
     * parsed from the internal subset attached as user data to
     * <code>doc</code>.  The attached dtd must be the tree from
     * NekoDTD. The owner document of the returned tree will be
     * <code>doc</doc>.
     *
     * NekoDTD parser returns a new document node containing elements
     * representing the dtd declarations. The plan is to get the root
     * element and adopt it into the correct document, stipping the
     * Document provided by NekoDTD.
     *
     */
    public static XmlDtd newFromInternalSubset(Ruby ruby, Document doc) {
        Object dtdTree_ = doc.getUserData(XmlDocument.DTD_RAW_DOCUMENT);
        if (dtdTree_ == null)
            return new XmlDtd(ruby);

        Node dtdTree = (Node) dtdTree_;
        Node dtd = getInternalSubset(dtdTree);
        if (dtd == null) {
            return new XmlDtd(ruby);
        } else {
            // Import the node into doc so it has the correct owner document.
            dtd = doc.importNode(dtd, true);
            return new XmlDtd(ruby, dtd);
        }
    }

    public static IRubyObject newFromExternalSubset(Ruby ruby, Document doc) {
        Object dtdTree_ = doc.getUserData(XmlDocument.DTD_RAW_DOCUMENT);
        if (dtdTree_ == null) {
            return ruby.getNil();
        }

        Node dtdTree = (Node) dtdTree_;
        Node dtd = getExternalSubset(dtdTree);
        if (dtd == null) {
            return ruby.getNil();
        } else if (!dtd.hasChildNodes()) {
            return ruby.getNil();
        } else {
            // Import the node into doc so it has the correct owner document.
            dtd = doc.importNode(dtd, true);
            return new XmlDtd(ruby, dtd);
        }
    }

    /*
     * <code>dtd</code> is the document node of a NekoDTD tree.
     * NekoDTD tree looks like this:
     *
     * <code><pre>
     * [#document: null]
     *   [#comment: ...]
     *   [#comment: ...]
     *   [dtd: null]   // a DocumentType; isDTD(node) => false
     *   [dtd: null]   // root of dtd, an Element node; isDTD(node) => true
     *     ... decls, content models, etc. ...
     *     [externalSubset: null] pubid="the pubid" sysid="the sysid"
     *       ... external subset decls, etc. ...
     * </pre></code>
     */
    protected static Node getInternalSubset(Node dtdTree) {
        Node root;
        for (root = dtdTree.getFirstChild(); ; root = root.getNextSibling()) {
            if (root == null)
                return null;
            else if (isDTD(root))
                return root;      // we have second dtd which is root
        }
    }

    protected static Node getExternalSubset(Node dtdTree) {
        Node dtd = getInternalSubset(dtdTree);
        if (dtd == null) return null;
        for (Node ext = dtd.getFirstChild(); ; ext = ext.getNextSibling()) {
            if (ext == null)
                return null;
            else if (isExternalSubset(ext))
                return ext;
        }
    }

    /**
     * This overrides the #attributes method defined in
     * lib/nokogiri/xml/node.rb.
     */
    @JRubyMethod
    public IRubyObject attributes(ThreadContext context) {
        if (attributes == null) extractDecls(context);

        return attributes;
    }

    @JRubyMethod
    public IRubyObject elements(ThreadContext context) {
        if (elements == null) extractDecls(context);

        return elements;
    }

    @JRubyMethod
    public IRubyObject entities(ThreadContext context) {
        if (entities == null) extractDecls(context);

        return entities;
    }

    @JRubyMethod
    public IRubyObject notations(ThreadContext context) {
        if (notations == null) extractDecls(context);

        return notations;
    }

    /**
     * Our "node" object is as-returned by NekoDTD.  The actual
     * "children" that we're interested in (Attribute declarations,
     * etc.) are a few layers deep.
     */
    @Override
    @JRubyMethod
    public IRubyObject children(ThreadContext context) {
        if (children == null) extractDecls(context);

        return children;
    }

    /**
     * Returns the name of the dtd.
     */
    @Override
    @JRubyMethod
    public IRubyObject node_name(ThreadContext context) {
        return name;
    }

    @Override
    @JRubyMethod(name = "node_name=")
    public IRubyObject node_name_set(ThreadContext context, IRubyObject name) {
        throw context.getRuntime()
            .newRuntimeError("cannot change name of DTD");
    }

    @JRubyMethod
    public IRubyObject system_id(ThreadContext context) {
        return sysId;
    }

    @JRubyMethod
    public IRubyObject external_id(ThreadContext context) {
        return pubId;
    }
    
    @JRubyMethod
    public IRubyObject validate(ThreadContext context, IRubyObject doc) {
        RubyArray errors = RubyArray.newArray(context.getRuntime());
        if (doc instanceof XmlDocument) {
          errors = (RubyArray) ((XmlDocument)doc).getInstanceVariable("@errors");
        }
        return errors;
    }

    public static boolean nameEquals(Node node, QName name) {
        return name.localpart.equals(node.getNodeName());
    }

    public static boolean isExternalSubset(Node node) {
        return nameEquals(node, DTDConfiguration.E_EXTERNAL_SUBSET);
    }

    /**
     * Checks instanceof Element so we return false for a DocumentType
     * node (NekoDTD uses Element for all its nodes).
     */
    public static boolean isDTD(Node node) {
        return (node instanceof Element &&
                nameEquals(node, DTDConfiguration.E_DTD));
    }

    public static boolean isAttributeDecl(Node node) {
        return nameEquals(node, DTDConfiguration.E_ATTRIBUTE_DECL);
    }

    public static boolean isElementDecl(Node node) {
        return nameEquals(node, DTDConfiguration.E_ELEMENT_DECL);
    }

    public static boolean isEntityDecl(Node node) {
        return (nameEquals(node, DTDConfiguration.E_INTERNAL_ENTITY_DECL) ||
                nameEquals(node, DTDConfiguration.E_UNPARSED_ENTITY_DECL));
    }

    public static boolean isNotationDecl(Node node) {
        return nameEquals(node, DTDConfiguration.E_NOTATION_DECL);
    }

    public static boolean isContentModel(Node node) {
        return nameEquals(node, DTDConfiguration.E_CONTENT_MODEL);
    }

    /**
     * Recursively extract various DTD declarations and store them in
     * the various collections.
     */
    protected void extractDecls(ThreadContext context) {
        Ruby runtime = context.getRuntime();

        // initialize data structures
        allDecls = RubyArray.newArray(runtime);
        attributes = RubyHash.newHash(runtime);
        elements = RubyHash.newHash(runtime);
        entities = RubyHash.newHash(runtime);
        notations = RubyHash.newHash(runtime);
        contentModels = RubyHash.newHash(runtime);
        children = runtime.getNil();

        // recursively extract decls
        if (node == null) return; // leave all the decl hash's empty
        extractDecls(context, node.getFirstChild());

        // convert allDecls to a NodeSet
        children =
            new XmlNodeSet(runtime,
                           getNokogiriClass(runtime, "Nokogiri::XML::NodeSet"),
                           allDecls);

        // add attribute decls as attributes to the matching element decl
        RubyArray keys = attributes.keys();
        for (int i = 0; i < keys.getLength(); ++i) {
            IRubyObject akey = keys.entry(i);
            IRubyObject val;

            val = attributes.op_aref(context, akey);
            if (val.isNil()) continue;
            XmlAttributeDecl attrDecl = (XmlAttributeDecl) val;
            IRubyObject ekey = attrDecl.element_name(context);
            val = elements.op_aref(context, ekey);
            if (val.isNil()) continue;
            XmlElementDecl elemDecl = (XmlElementDecl) val;

            elemDecl.appendAttrDecl(attrDecl);
        }

        // add content models to the matching element decl
        keys = contentModels.keys();
        for (int i = 0; i < keys.getLength(); ++i) {
            IRubyObject key = keys.entry(i);
            IRubyObject cm = contentModels.op_aref(context, key);

            IRubyObject elem = elements.op_aref(context, key);
            if (elem.isNil()) continue;
            if (((XmlElementDecl)elem).isEmpty()) continue;
            ((XmlElementDecl) elem).setContentModel(cm);
        }
    }

    /**
     * The <code>node</code> is either the first child of the root dtd
     * node (as returned by getInternalSubset()) or the first child of
     * the external subset node (as returned by getExternalSubset()).
     *
     * This recursive function will not descend into an
     * 'externalSubset' node, thus for an internal subset it only
     * extracts nodes in the internal subset, and for an external
     * subset it extracts everything and assumess <code>node</code>
     * and all children are part of the external subset.
     */
    protected void extractDecls(ThreadContext context, Node node) {
        while (node != null) {
            if (isExternalSubset(node)) {
                return;
            } else if (isAttributeDecl(node)) {
                XmlAttributeDecl decl = (XmlAttributeDecl)
                    XmlAttributeDecl.create(context, node);
                attributes.op_aset(context, decl.attribute_name(context), decl);
                allDecls.append(decl);
            } else if (isElementDecl(node)) {
                XmlElementDecl decl = (XmlElementDecl)
                    XmlElementDecl.create(context, node);
                elements.op_aset(context, decl.element_name(context), decl);
                allDecls.append(decl);
            } else if (isEntityDecl(node)) {
                XmlEntityDecl decl = (XmlEntityDecl)
                    XmlEntityDecl.create(context, node);
                entities.op_aset(context, decl.node_name(context), decl);
                allDecls.append(decl);
            } else if (isNotationDecl(node)) {
                XmlNode tmp = (XmlNode)
                    NokogiriHelpers.constructNode(context.getRuntime(), node);
                IRubyObject decl = invoke(context, notationClass, "new",
                                          tmp.getAttribute(context, "name"),
                                          tmp.getAttribute(context, "pubid"),
                                          tmp.getAttribute(context, "sysid"));
                notations.op_aset(context,
                                  tmp.getAttribute(context, "name"), decl);
                allDecls.append(decl);
            } else if (isContentModel(node)) {
                XmlElementContent cm =
                    new XmlElementContent(context.getRuntime(),
                                          (XmlDocument) document(context),
                                          node);
                contentModels.op_aset(context, cm.element_name(context), cm);
            } else {
                // recurse
                extractDecls(context, node.getFirstChild());
            }

            node = node.getNextSibling();
        }
    }
    
    public void saveContent(ThreadContext context, SaveContext ctx) {
        ctx.append("<!DOCTYPE " + name + " ");
        if (pubId != null) {
            ctx.append("PUBLIC \"" + pubId + "\" \"" + sysId + "\">");
        } else if (sysId != null) {
            ctx.append("SYSTEM " + sysId);
        }
    }

}
