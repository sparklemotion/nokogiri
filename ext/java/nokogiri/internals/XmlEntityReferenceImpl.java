package nokogiri.internals;

import org.jruby.Ruby;
import org.w3c.dom.Node;

/**
 *
 * @author sergio
 */
class XmlEntityReferenceImpl extends XmlNodeImpl {

    public XmlEntityReferenceImpl(Ruby ruby, Node node) {
        super(ruby, node);
    }

}
