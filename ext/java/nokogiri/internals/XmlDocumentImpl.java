package nokogiri.internals;

import nokogiri.XmlDocument;
import nokogiri.XmlNode;
import org.jruby.Ruby;
import org.jruby.runtime.ThreadContext;
import org.w3c.dom.Document;
import org.w3c.dom.Node;

/**
 *
 * @author sergio
 */
public class XmlDocumentImpl extends XmlNodeImpl{

    public XmlDocumentImpl(Ruby ruby, Node node) {
        super(ruby, node);
    }

    @Override
    protected int getNokogiriNodeTypeInternal() { return 10; }

    @Override
    public void relink_namespace(ThreadContext context, XmlNode current) {
        XmlDocument cur = (XmlDocument) current;
        ((XmlNode) cur.root(context)).relink_namespace(context);
    }

    @Override
    public void saveContent(ThreadContext context, XmlNode node, SaveContext ctx) {
        XmlDocument cur = (XmlDocument) node;
        Document curDoc = cur.getDocument();

        if(!ctx.noDecl()) {
            
            ctx.append("<?xml version=\"");
            ctx.append(curDoc.getXmlVersion());
            ctx.append("\"");
//            if(!cur.encoding(context).isNil()) {
//                ctx.append(" encoding=");
//                ctx.append(cur.encoding(context).asJavaString());
//            }

            String encoding = ctx.getEncoding();

            if(encoding == null &&
                    !cur.encoding(context).isNil()) {
                encoding = cur.encoding(context).convertToString().asJavaString();
            }

            if(encoding != null) {
                ctx.append(" encoding=\"");
                ctx.append(encoding);
                ctx.append("\"");
            }

            ctx.append(" standalone=\"");
            ctx.append(curDoc.getXmlStandalone() ? "yes" : "no");
            ctx.append("\"?>\n");
        }

        XmlNode root = (XmlNode) cur.root(context);
        root.saveContent(context, ctx);
        ctx.append("\n");
    }

}
