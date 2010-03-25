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
    private String declaration = null;

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
        ctx.append(declaration);
    }

    @Override
    public void saveContentAsHtml(ThreadContext context, XmlNode current, SaveContext ctx) {
        saveContent(context, current,ctx);
    }

    public void setDeclaration(String declaration) {
        this.declaration = declaration;
    }
}
