package nokogiri.internals;

import nokogiri.XmlNode;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Attr;
import org.w3c.dom.Element;

/**
 *
 * @author sergio
 */
public class XmlAttrMethods extends XmlNodeMethods{

    @Override
    protected int getNokogiriNodeTypeInternal() { return 2; }

    @Override
    public void node_name_set(ThreadContext context, XmlNode current, IRubyObject nodeName) {
        String newName = nodeName.convertToString().asJavaString();
        current.getNode().getOwnerDocument().renameNode(current.getNode(), null, newName);
        current.setName(nodeName);
    }

    @Override
    public void saveContent(ThreadContext context, XmlNode current, SaveContext ctx) {
        Attr attr = (Attr) current.getNode();
        ctx.append(" ");
        ctx.append(attr.getNodeName());
        ctx.append("=\"");
        ctx.append(attr.getValue());
        ctx.append("\"");
    }

    @Override
    public void unlink(ThreadContext context, XmlNode current) {
        Attr attr = (Attr) current.getNode();
        Element parent = attr.getOwnerElement();
        parent.removeAttributeNode(attr);
    }
}
