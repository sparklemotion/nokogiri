package nokogiri.internals;

import nokogiri.XmlNode;

import org.apache.xerces.dom.DeferredEntityImpl;
import org.jruby.Ruby;
import org.jruby.runtime.ThreadContext;
import org.w3c.dom.Node;

/**
 * Implementation for ENTITY declaration of DTD
 * 
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class XmlEntityDeclImpl extends XmlNodeImpl {
    private String declaration = null;

    public XmlEntityDeclImpl(Ruby ruby, Node node) {
        super(ruby, node);
    }

    @Override
    protected int getNokogiriNodeTypeInternal() { return 17; }

    @Override
    public void saveContent(ThreadContext context, XmlNode current, SaveContext ctx) {
        ctx.append(declaration);
    }

    @Override
    public void saveContentAsHtml(ThreadContext context, XmlNode current, SaveContext ctx) {
        saveContent(context, current, ctx);
    }
    
    public void setDeclaration(String declaration) {
        this.declaration = declaration;
    }
}
