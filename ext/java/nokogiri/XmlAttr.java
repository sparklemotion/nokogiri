package nokogiri;

import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;
import static nokogiri.internals.NokogiriHelpers.rubyStringToString;
import nokogiri.internals.NokogiriHelpers;
import nokogiri.internals.SaveContext;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Attr;
import org.w3c.dom.Element;
import org.w3c.dom.Node;

@JRubyClass(name="Nokogiri::XML::Attr", parent="Nokogiri::XML::Node")
public class XmlAttr extends XmlNode{

    public static final String[] HTML_BOOLEAN_ATTRS = {
        "checked", "compact", "declare", "defer", "disabled", "ismap",
        "multiple", "nohref", "noresize", "noshade", "nowrap", "readonly",
        "selected"
    };

    public XmlAttr(Ruby ruby, Node attr){
        super(ruby, getNokogiriClass(ruby, "Nokogiri::XML::Attr"), attr);
    }

    public XmlAttr(Ruby ruby, RubyClass rubyClass) {
        super(ruby, rubyClass);
    }

    public XmlAttr(Ruby ruby, RubyClass rubyClass, Node attr){
        super(ruby, rubyClass, attr);
    }

    @Override
    protected void init(ThreadContext context, IRubyObject[] args) {
        if (args.length < 2) {
            throw getRuntime().newArgumentError(args.length, 2);
        }

        IRubyObject doc = args[0];
        IRubyObject content = args[1];

        if(!(doc instanceof XmlDocument)) {
            final String msg =
                "document must be an instance of Nokogiri::XML::Document";
            throw getRuntime().newArgumentError(msg);
        }

        XmlDocument xmlDoc = (XmlDocument)doc;
        String str = rubyStringToString(content);
        Node attr = xmlDoc.getDocument().createAttribute(str);
        setNode(context, attr);
    }

    public boolean isHtmlBooleanAttr() {
        String name = node.getNodeName().toLowerCase();

        for(String s : HTML_BOOLEAN_ATTRS) {
            if(s.equals(name)) return true;
        }

        return false;
    }


    private String serializeAttrTextContent(String s) {
        if (s == null) return "";

        char[] c = s.toCharArray();
        StringBuffer buffer = new StringBuffer(c.length);

        for(int i = 0; i < c.length; i++) {
            switch(c[i]){
            case '\n': buffer.append("&#10;"); break;
            case '\r': buffer.append("&#13;"); break;
            case '\t': buffer.append("&#9;"); break;
          //case '"': buffer.append("&quot;"); break;
          // TODO: is replacing '"' with '%22' always correct?
            case '"': buffer.append("%22"); break;
            case '<': buffer.append("&lt;"); break;
            case '>': buffer.append("&gt;"); break;
            case '&': buffer.append("&amp;"); break;
            default: buffer.append(c[i]);
            }
        }

        return buffer.toString();
    }

    @Override
    @JRubyMethod(name = {"content", "value", "to_s"})
    public IRubyObject content(ThreadContext context) {
        if (content != null && !content.isNil()) return content;
        if (node == null) return context.getRuntime().getNil();
        String attrValue = ((Attr)node).getValue();
        if (attrValue == null) return context.getRuntime().getNil();
        return JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), attrValue);
    }
    
    @JRubyMethod(name = {"value=", "content="})
    public IRubyObject value_set(ThreadContext context, IRubyObject content){
        Attr attr = (Attr) node;
        attr.setValue((String)XmlNode.encode_special_chars(context, content).toJava(String.class));
        setContent(content);
        return content;
    }

    @Override
    protected IRubyObject getNodeName(ThreadContext context) {
        if (name != null) return name;
        String attrName = ((Attr)node).getName();
        attrName = NokogiriHelpers.getLocalPart(attrName);
        return attrName == null ? context.getRuntime().getNil() : RubyString.newString(context.getRuntime(), attrName);
    }

    @Override
    public void saveContent(ThreadContext context, SaveContext ctx) {
        Attr attr = (Attr) node;

        ctx.maybeSpace();
        ctx.append(attr.getName());

        if (!ctx.asHtml() || !isHtmlBooleanAttr()) {
            ctx.append("=");
            ctx.append("\"");
            ctx.append(serializeAttrTextContent(attr.getValue()));
            ctx.append("\"");
        }
    }

    @Override
    public IRubyObject unlink(ThreadContext context) {
        Attr attr = (Attr) node;
        Element parent = attr.getOwnerElement();
        parent.removeAttributeNode(attr);

        return this;
    }

}
