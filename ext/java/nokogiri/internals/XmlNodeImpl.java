package nokogiri.internals;

import nokogiri.*;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyString;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;

import static nokogiri.internals.NokogiriHelpers.isNamespace;

/**
 *
 * @author sergio
 */
public class XmlNodeImpl {

    protected IRubyObject content, doc, name, namespace, namespace_definitions;

    private Node node;

    private static final IRubyObject DEFAULT_CONTENT = null;
    private static final IRubyObject DEFAULT_DOC = null;
    private static final IRubyObject DEFAULT_NAME = null;
    private static final IRubyObject DEFAULT_NAMESPACE = null;
    private static final IRubyObject DEFAULT_NAMESPACE_DEFINITIONS = null;

    public XmlNodeImpl(Ruby ruby, Node node) {
        this.node = node;
    }

    public IRubyObject children(ThreadContext context, XmlNode current) {
        XmlNodeSet result = new XmlNodeSet(context.getRuntime(), current.getNode().getChildNodes());
        result.setDocument(this.getDocument(context));
        return result;
    }

    public IRubyObject getContent(ThreadContext context) {
        if(this.content == DEFAULT_CONTENT) {
            String textContent = this.node.getTextContent();
            this.content = (textContent == null) ? methods().getNullContent(context) :
                context.getRuntime().newString(textContent);
        }

        return this.content;
    }

    public XmlDocument getDocument(ThreadContext context) {
        if(this.doc == DEFAULT_DOC) {
            this.doc = NokogiriHelpers.getCachedNodeOrCreate(context.getRuntime(),
                    this.node.getOwnerDocument());
        }

        return (XmlDocument) this.doc;
    }

    public IRubyObject getNamespace(ThreadContext context) {
        if(this.namespace == DEFAULT_NAMESPACE) {
            this.namespace = new XmlNamespace(context.getRuntime(), this.node.getPrefix(),
                                this.node.lookupNamespaceURI(this.node.getPrefix()));
            if(((XmlNamespace) this.namespace).isEmpty()) {
                this.namespace = context.getRuntime().getNil();
            }
        }

        return this.namespace;
    }

    public Node getNode() {
        return this.node;
    }

    public RubyString getNodeName(ThreadContext context) {
        if(this.name == DEFAULT_NAME) {
            this.name = context.getRuntime().newString(NokogiriHelpers.getNodeName(this.node));
        }

        return (RubyString) this.name;
    }

    public RubyArray getNsDefinitions(Ruby ruby) {
        if(this.namespace_definitions == DEFAULT_NAMESPACE_DEFINITIONS) {
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

    public XmlNodeImpl methods() {
        return this;
    }

    public void resetContent() {
        this.content = DEFAULT_CONTENT;
    }

    public void resetDocument() {
        this.doc = DEFAULT_DOC;
    }

    public void resetName() {
        this.name = DEFAULT_NAME;
    }

    public void resetNamespace() {
        this.namespace = DEFAULT_NAMESPACE;
    }

    public void resetNamespaceDefinitions() {
        this.namespace_definitions = DEFAULT_NAMESPACE_DEFINITIONS;
    }

    public void setContent(IRubyObject content) {
        this.content = content;
    }

    public void setDocument(IRubyObject doc) {
        this.doc = doc;
    }

    public void setName(IRubyObject name) {
        this.name = name;
    }

    public void setNamespace(IRubyObject ns) {
        this.namespace = ns;
    }

    public void setNamespaceDefinitions(IRubyObject namespace_definitions) {
        this.namespace_definitions = namespace_definitions;
    }

    public void setNode(Node node) {
        this.node = node;
    }

    /*
     * Specific implementation of methods.
     */

    public void add_child(ThreadContext context, XmlNode current, XmlNode child) {

        Node appended = child.getNode();

        if(child.document(context) != current.document(context)) {
            ((XmlDocument) current.document(context)).getDocument().adoptNode(appended);
            child.setDocument(current.document(context));
        } else if(appended.getParentNode() != null) {
            child.unlink(context);
        }

        if(appended.getNodeType() == Node.TEXT_NODE) {
            RubyArray children = ((XmlNodeSet) current.children(context)).convertToArray();
            if(!children.isEmpty()) {
                XmlNode last = (XmlNode) children.last();
                XmlNode.coalesceTextNodes(context, last, child);
                return;
            }
        }

        try{
            current.getNode().appendChild(appended);
        } catch (Exception ex) {
            throw context.getRuntime().newRuntimeError(ex.toString());
        }

        child.relink_namespace(context);
        
        current.post_add_child(context, current, child);
    }

    public void add_namespace_definitions(ThreadContext context, XmlNode current, XmlNamespace ns, String prefix, String href) {}

    public IRubyObject blank_p(ThreadContext context, XmlNode node) {
        return context.getRuntime().getFalse();
    }

    public Node cloneNode(ThreadContext context, XmlNode current, boolean deep) {
        return current.getNode().cloneNode(deep);
    }

    public IRubyObject get(ThreadContext context, XmlNode current, IRubyObject key) {
        return context.getRuntime().getNil();
    }

    public IRubyObject getNokogiriNodeType(ThreadContext context) {
        return context.getRuntime().newFixnum(this.getNokogiriNodeTypeInternal());
    }

    protected int getNokogiriNodeTypeInternal(){ return 0; }

    public IRubyObject getNullContent(ThreadContext context) {
        return context.getRuntime().newString();
    }

    protected boolean isBlankChar(char a) {
        return Character.isWhitespace(a);
    }

    protected boolean isBlankNode(ThreadContext context, XmlNode node) {
        RubyString cont = node.content(context).convertToString();
        if(cont.isEmpty()) return false;

        String content = cont.asJavaString();

        char[] cur = content.toCharArray();

        for(int i=0; i < cur.length; i++) {
            if(!isBlankChar(cur[i])) return false;
        }

        return true;
    }

    public boolean isComment() { return false; }

    public boolean isElement() { return false; }

    public boolean isProcessingInstruction() { return false; }

    public IRubyObject key_p(ThreadContext context, XmlNode current, IRubyObject k) {
        return context.getRuntime().getFalse();
    }

    public void node_name_set(ThreadContext context, XmlNode current, IRubyObject nodeName) {}

    public void op_aset(ThreadContext context, XmlNode current, IRubyObject index, IRubyObject val) {}

    public void post_add_child(ThreadContext context, XmlNode current, XmlNode child) { }

    public void remove_attribute(ThreadContext context, XmlNode current, IRubyObject name) {}

    public void relink_namespace(ThreadContext context, XmlNode current) {}

    protected void saveNodeListContent(ThreadContext context, XmlNodeSet list, SaveContext ctx) {
        this.saveNodeListContent(context, (RubyArray) list.to_a(context), ctx);
    }

    protected void saveNodeListContent(ThreadContext context, RubyArray array, SaveContext ctx) {
        int length = array.getLength();

        boolean formatIndentation = ctx.format() && ctx.indentString()!=null;

        for(int i = 0; i < length; i++) {
            XmlNode cur = (XmlNode) array.aref(context.getRuntime().newFixnum(i));

            if(formatIndentation &&
                    (cur.isElement() || cur.isComment() || cur.isProcessingInstruction())) {
                ctx.append(ctx.getCurrentIndentString());
            }

            cur.saveContent(context, ctx);

            if(ctx.format()) ctx.append("\n");
        }
    }

    protected void saveNodeListContentAsHtml(ThreadContext context, XmlNodeSet list, SaveContext ctx) {
        this.saveNodeListContentAsHtml(context, (RubyArray) list.to_a(context), ctx);
    }

    protected void saveNodeListContentAsHtml(ThreadContext context, RubyArray array, SaveContext ctx) {
        int length = array.getLength();

        boolean formatIndentation = ctx.format() && ctx.indentString()!=null;

        for(int i = 0; i < length; i++) {
            XmlNode cur = (XmlNode) array.aref(context.getRuntime().newFixnum(i));

            cur.saveContentAsHtml(context, ctx);

            if(ctx.format()) ctx.append("\n");
        }
    }

    public void saveContent(ThreadContext context, XmlNode cur, SaveContext ctx) {}

    public void saveContentAsHtml(ThreadContext context, XmlNode cur, SaveContext ctx) {}

    public void unlink(ThreadContext context, XmlNode current) {
        Node currentNode = current.getNode();
        if(currentNode.getParentNode() == null) {
            throw context.getRuntime().newRuntimeError("TYPE: "+currentNode.getNodeType()+ " PARENT NULL");
        } else {
            currentNode.getParentNode().removeChild(currentNode);
        }
    }

    public static XmlNodeImpl getImplForNode(Ruby ruby, Node node) {
        if(node == null) return new XmlNodeImpl(ruby, node);
        switch(node.getNodeType()) {
            case Node.ATTRIBUTE_NODE: return new XmlAttrImpl(ruby, node);
            case Node.CDATA_SECTION_NODE: return new XmlCdataImpl(ruby, node);
            case Node.COMMENT_NODE: return new XmlCommentImpl(ruby, node);
            case Node.DOCUMENT_FRAGMENT_NODE: return new XmlDocumentFragmentImpl(ruby, node);
            case Node.DOCUMENT_NODE: return new XmlDocumentImpl(ruby, ((Document) node));
            case Node.ELEMENT_NODE: return new XmlElementImpl(ruby, node);
            case Node.ENTITY_REFERENCE_NODE: return new XmlEntityReferenceImpl(ruby, node);
            case Node.PROCESSING_INSTRUCTION_NODE: return new XmlProcessingInstructionImpl(ruby, node);
            case Node.TEXT_NODE : return new XmlTextImpl(ruby, node);
            default: return new XmlNodeImpl(ruby, node);
        }
    }
}
