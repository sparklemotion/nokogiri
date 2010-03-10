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

    public XmlEntityDeclImpl(Ruby ruby, Node node) {
        super(ruby, node);
    }

    @Override
    protected int getNokogiriNodeTypeInternal() { return 17; }

    @Override
    public void saveContent(ThreadContext context, XmlNode current, SaveContext ctx) {
        DeferredEntityImpl entity = (DeferredEntityImpl)current.getNode();
        ctx.append("<!ENTITY ");
        ctx.append(entity.getNodeName());
        ctx.append(" ");
        if (entity.getPublicId() != null) {
            ctx.append("PUBLIC ");
            ctx.append(entity.getPublicId());
        } else if (entity.getSystemId() != null) {
            ctx.append("SYSTEM ");
            ctx.append(entity.getSystemId());
        }
        if (entity.getTextContent() != null) {
            ctx.append("\"" + entity.getTextContent() + "\"");
        }
        ctx.append(">");
    }

    @Override
    public void saveContentAsHtml(ThreadContext context, XmlNode current, SaveContext ctx) {
        saveContent(context, current, ctx);
    }

}
