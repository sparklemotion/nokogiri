package nokogiri.internals;

import nokogiri.HtmlDocument;
import nokogiri.XmlDocument;
import nokogiri.XmlNode;
import nokogiri.XmlNodeSet;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.runtime.ThreadContext;
import org.w3c.dom.Document;
import org.w3c.dom.DocumentType;
import org.w3c.dom.Node;

/**
 *
 * @author sergio
 */
public class HtmlDocumentImpl extends XmlDocumentImpl {

    public HtmlDocumentImpl(Ruby ruby, Node node) {
        super(ruby, node);
    }
    
    @Override
    public XmlNode dup_impl(ThreadContext context, XmlDocument current, boolean deep, RubyClass klazz) {
        Document newDoc = (Document) current.getDocument().cloneNode(deep);

        return new HtmlDocument(context.getRuntime(), klazz, newDoc);
    }

    @Override
    protected int getNokogiriNodeTypeInternal() { return 13; }

    @Override
    public void saveContent(ThreadContext context, XmlNode document, SaveContext ctx) {
        Document doc = (Document) document.getNode();
        DocumentType dtd = doc.getDoctype();

        if(dtd != null) {
            ctx.append("<!DOCTYPE ");
            ctx.append(dtd.getName());
            if(dtd.getPublicId() != null) {
                ctx.append(" PUBLIC ");
                ctx.appendQuoted(dtd.getPublicId());
                if(dtd.getSystemId() != null) {
                    ctx.append(" ");
                    ctx.appendQuoted(dtd.getSystemId());
                }
            } else if(dtd.getSystemId() != null) {
                ctx.append(" SYSTEM ");
                ctx.appendQuoted(dtd.getSystemId());
            }
            ctx.append(">\n");
        }

        this.saveNodeListContentAsHtml(context,
                (XmlNodeSet) this.children(context, document), ctx);
        
        ctx.append("\n");
    }

    @Override
    public void saveContentAsHtml(ThreadContext context, XmlNode node, SaveContext ctx) {
        this.saveContent(context, node, ctx);
    }
}
