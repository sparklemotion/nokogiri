package nokogiri.internals;

import nokogiri.XmlNode;
import org.jruby.Ruby;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Attr;
import org.w3c.dom.Element;
import org.w3c.dom.Node;

/**
 *
 * @author sergio
 */
public class XmlAttrImpl extends XmlNodeImpl{

    public static final String[] HTML_BOOLEAN_ATTRS = {
        "checked", "compact", "declare", "defer", "disabled", "ismap",
        "multiple", "nohref", "noresize", "noshade", "nowrap", "readonly",
        "selected"
    };

    public XmlAttrImpl(Ruby ruby, Node node) {
        super(ruby, node);
    }

    public boolean isHtmlBooleanAttr() {
        String name = this.getNode().getNodeName().toLowerCase();

        for(String s : HTML_BOOLEAN_ATTRS) {
            if(s.equals(name)) return true;
        }

        return false;
    }

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
    public void saveContentAsHtml(ThreadContext context, XmlNode current, SaveContext ctx) {
        Attr attr = (Attr) current.getNode();
        ctx.append(" ");

        ctx.append(attr.getNodeName());

        if(!this.isHtmlBooleanAttr()) {
            String value = attr.getValue();
            if(value != null) {
                ctx.append("=");
                ctx.append(attr.getValue());
            } else {
                ctx.append("=\"\"");
            }
        }
    }

    @Override
    public void unlink(ThreadContext context, XmlNode current) {
        Attr attr = (Attr) current.getNode();
        Element parent = attr.getOwnerElement();
        parent.removeAttributeNode(attr);
    }
}
