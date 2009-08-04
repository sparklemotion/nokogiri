package nokogiri.internals;

import org.jruby.Ruby;
import org.jruby.runtime.builtin.IRubyObject;
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
    protected int getNokogiriNodeTypeInternal() { return 13; }
}
