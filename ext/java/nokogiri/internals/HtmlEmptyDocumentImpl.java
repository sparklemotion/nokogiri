package nokogiri.internals;

import nokogiri.HtmlDocument;
import nokogiri.XmlDocument;
import nokogiri.XmlNode;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
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

    @Override
    public XmlNode dup_impl(ThreadContext context, XmlDocument current, boolean deep, RubyClass klazz) {
        return (XmlNode) HtmlDocument.rbNew(context, klazz, new IRubyObject[0]);
    }
}
