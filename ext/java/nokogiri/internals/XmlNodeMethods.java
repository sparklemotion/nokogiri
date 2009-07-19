package nokogiri.internals;

import nokogiri.XmlNamespace;
import nokogiri.XmlNode;
import nokogiri.XmlNodeSet;
import org.jruby.RubyArray;
import org.jruby.RubyString;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Node;

/**
 *
 * @author sergio
 */
public class XmlNodeMethods {

    public void add_child(ThreadContext context, XmlNode current, XmlNode child) {

        Node appended = child.getNode();

        if(child.document(context) != current.document(context)) {
            current.getNode().getOwnerDocument().adoptNode(appended);
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
    }

    public void add_namespace_definitions(ThreadContext context, XmlNode current, XmlNamespace ns, String prefix, String href) {}

    public IRubyObject blank_p(ThreadContext context, XmlNode node) {
        return context.getRuntime().getFalse();
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

    public void saveContent(ThreadContext context, XmlNode cur, SaveContext ctx) {}

    public void unlink(ThreadContext context, XmlNode current) {
        Node currentNode = current.getNode();
        if(currentNode.getParentNode() == null) {
            throw context.getRuntime().newRuntimeError("TYPE: "+currentNode.getNodeType()+ " PARENT NULL");
        } else {
            currentNode.getParentNode().removeChild(currentNode);
        }
    }

    public static XmlNodeMethods getMethodsForNode(Node node) {
        if(node == null) return new XmlNodeMethods();
        switch(node.getNodeType()) {
            case Node.ATTRIBUTE_NODE: return new XmlAttrMethods();
            case Node.CDATA_SECTION_NODE: return new XmlCdataMethods();
            case Node.COMMENT_NODE: return new XmlCommentMethods();
            case Node.DOCUMENT_FRAGMENT_NODE: return new XmlDocumentFragmentMethods();
            case Node.DOCUMENT_NODE: return new XmlDocumentMethods();
            case Node.ELEMENT_NODE: return new XmlElementMethods();
            case Node.PROCESSING_INSTRUCTION_NODE: return new XmlProcessingInstructionMethods();
            case Node.TEXT_NODE : return new XmlTextMethods();
            default: return new XmlNodeMethods();
        }
    }
}
