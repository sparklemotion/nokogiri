package nokogiri.internals;

import nokogiri.XmlDocument;
import nokogiri.XmlNode;
import org.jruby.Ruby;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
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
    public Node cloneNode(ThreadContext context, XmlNode current, boolean deep) {
        return ((XmlDocument) current).getDocument().cloneNode(deep);
    }

    @Override
    public IRubyObject encoding(ThreadContext context, XmlDocument current) {
        if(this.encoding == null) {
            this.encoding = context.getRuntime().getNil();
        }

        return this.encoding;
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
        current.getDocument().appendChild(XmlNode.getNodeFromXmlNode(context, root));
        current.setInternalNode(XmlNodeImpl.getImplForNode(context.getRuntime(), current.getDocument()));
    }

}
