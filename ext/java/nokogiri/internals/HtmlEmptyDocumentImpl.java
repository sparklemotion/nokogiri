package nokogiri.internals;

import nokogiri.XmlDocument;
import org.jruby.Ruby;
import org.jruby.runtime.ThreadContext;
import org.w3c.dom.Node;

/**
 *
 * @author sergio
 */
public class HtmlEmptyDocumentImpl extends XmlEmptyDocumentImpl{

    public HtmlEmptyDocumentImpl(Ruby ruby, Node node) {
        super(ruby, node);
    }

    @Override
    protected void changeInternalNode(ThreadContext context, XmlDocument doc) {
        doc.setInternalNode(new HtmlDocumentImpl(context.getRuntime(), doc.getDocument()));
    }
}
