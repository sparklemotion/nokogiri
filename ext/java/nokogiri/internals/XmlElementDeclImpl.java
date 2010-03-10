package nokogiri.internals;

import nokogiri.XmlNode;

import org.apache.xerces.dom.DeferredElementDefinitionImpl;
import org.jruby.Ruby;
import org.jruby.runtime.ThreadContext;
import org.w3c.dom.Node;

/**
 * Implementation for ELEMENT declaration of DTD
 * 
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class XmlElementDeclImpl extends XmlNodeImpl {

    public XmlElementDeclImpl(Ruby ruby, Node node) {
        super(ruby, node);
    }

    @Override
    protected int getNokogiriNodeTypeInternal() { return 15; }

    @Override
    public void saveContent(ThreadContext context, XmlNode current, SaveContext ctx) {
        DeferredElementDefinitionImpl element = (DeferredElementDefinitionImpl)current.getNode();
        ctx.append("<!ELEMENT ");
        ctx.append(element.getNodeName());
        ctx.append(" ");
        if (element.getTextContent() != null) {
            ctx.append("\"" + element.getTextContent() + "\"");
        }
        ctx.append(">");
    }

    @Override
    public void saveContentAsHtml(ThreadContext context, XmlNode current, SaveContext ctx) {
        saveContent(context, current, ctx);
    }

}
