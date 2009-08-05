package nokogiri.internals;

import nokogiri.XmlDocument;
import nokogiri.XmlNode;
import nokogiri.XmlNodeSet;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.w3c.dom.Node;

/**
 *
 * @author sergio
 */
public class XmlEmptyDocumentImpl extends XmlDocumentImpl{

    public XmlEmptyDocumentImpl(Ruby ruby, Node node) {
        super(ruby, node);
    }

    @Override
    public IRubyObject children(ThreadContext context, XmlNode current) {
        return XmlNodeSet.newEmptyNodeSet(context);
    }

    @Override
    public Node cloneNode(ThreadContext context, XmlNode current, boolean deep) {
        return ((XmlDocument) current).getDocument().cloneNode(deep);
    }

    @Override
    public XmlNode dup_impl(ThreadContext context, XmlDocument current, boolean deep, RubyClass klazz) {
        return (XmlNode) XmlDocument.rbNew(context, klazz, new IRubyObject[0]);
    }

    @Override
    public IRubyObject encoding(ThreadContext context, XmlDocument current) {
        if(this.encoding == null) {
            this.encoding = context.getRuntime().getNil();
        }

        return this.encoding;
    }

    @Override
    public void post_add_child(ThreadContext context, XmlNode current, XmlNode child) {
        this.changeInternalNode(context, (XmlDocument) current);
    }

    @Override
    public IRubyObject root(ThreadContext context, XmlDocument current) {
        if(this.root == null) {
            this.root = context.getRuntime().getNil();
        }
        return root;
    }

    @Override
    public void root_set(ThreadContext context, XmlDocument current, IRubyObject root) {
        Document document = current.getDocument();
        Node node = XmlNode.getNodeFromXmlNode(context, root);
        if(!document.equals(node.getOwnerDocument())) {
            document.adoptNode(node);
        }
        document.appendChild(node);
        changeInternalNode(context, current);
    }

    protected void changeInternalNode(ThreadContext context, XmlDocument doc) {
        doc.setInternalNode(XmlNodeImpl.getImplForNode(context.getRuntime(), doc.getDocument()));
    }
}
