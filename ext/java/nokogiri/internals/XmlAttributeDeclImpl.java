package nokogiri.internals;

import nokogiri.XmlAttributeDecl;
import nokogiri.XmlNode;

import org.apache.xerces.dom.AttrImpl;
import org.jruby.Ruby;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Node;

/**
 * Implementation for ATTLIST declaration of DTD
 * 
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class XmlAttributeDeclImpl extends XmlNodeImpl {

    public XmlAttributeDeclImpl(Ruby ruby, Node node) {
        super(ruby, node);
    }
    
    public IRubyObject getDefault(ThreadContext context) {
        return JavaUtil.convertJavaToRuby(context.getRuntime(), ((AttrImpl)getNode()).getTextContent());
    }

    @Override
    protected int getNokogiriNodeTypeInternal() { return 16; }

    @Override
    public void saveContent(ThreadContext context, XmlNode current, SaveContext ctx) {
        ctx.append("<!ATTLIST ");
        ctx.append(((XmlAttributeDecl)current).getParent().getNodeName());
        ctx.append(" ");
        ctx.append(current.node_name(context).convertToString().asJavaString());
        ctx.append(" ");
        //ctx.append(((DeferredAttrNSImpl)current.getNode()).getSchemaTypeInfo().getTypeName());
        IRubyObject content = current.content(context);
        if(!content.isNil()) {
            ctx.append(content.convertToString().asJavaString());
        }
        ctx.append(">");
    }

    @Override
    public void saveContentAsHtml(ThreadContext context, XmlNode current, SaveContext ctx) {
        saveContent(context, current,ctx);
    }

}
