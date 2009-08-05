package nokogiri.internals;

import nokogiri.HtmlDocument;
import nokogiri.XmlDocument;
import nokogiri.XmlNode;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.runtime.ThreadContext;
import org.w3c.dom.Document;
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
}
