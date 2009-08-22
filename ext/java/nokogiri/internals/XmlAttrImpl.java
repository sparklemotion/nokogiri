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

    private String serializeAttrTextContent(String s) {
        char[] c = s.toCharArray();
        StringBuffer buffer = new StringBuffer(c.length);

        for(int i = 0; i < c.length; i++) {
            switch(c[i]){
                case '\n': buffer.append("&#10;"); break;
                case '\r': buffer.append("&#13;"); break;
                case '\t': buffer.append("&#9;"); break;
                case '"': buffer.append("&quot;"); break;
                case '<': buffer.append("&lt;"); break;
                case '>': buffer.append("&gt;"); break;
                case '&': buffer.append("&amp;"); break;
                default: buffer.append(c[i]);
            }
        }

        return buffer.toString();
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
        ctx.append(serializeAttrTextContent(attr.getValue()));
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
                ctx.append("\"");
                ctx.append(serializeAttrTextContent(attr.getValue()));
                ctx.append("\"");
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
