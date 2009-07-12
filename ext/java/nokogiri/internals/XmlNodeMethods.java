package nokogiri.internals;

import nokogiri.XmlNamespace;
import nokogiri.XmlNode;
import nokogiri.XmlNodeSet;
import org.jruby.RubyArray;
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

    public IRubyObject get(ThreadContext context, XmlNode current, IRubyObject key) {
        return context.getRuntime().getNil();
    }

    public IRubyObject key_p(ThreadContext context, XmlNode current, IRubyObject k) {
        return context.getRuntime().getFalse();
    }

    public void node_name_set(ThreadContext context, XmlNode aThis, IRubyObject nodeName) {}

    public void op_aset(ThreadContext context, XmlNode current, IRubyObject index, IRubyObject val) {}

    public void remove_attribute(ThreadContext context, XmlNode current, IRubyObject name) {}

    public void relink_namespace(ThreadContext context, XmlNode current) {}

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
            case Node.DOCUMENT_FRAGMENT_NODE: return new XmlDocumentFragmentMethods();
            case Node.ELEMENT_NODE: return new XmlElementMethods();
            default: return new XmlNodeMethods();
        }
    }
}
