package nokogiri.internals;

import nokogiri.XmlNode;
import org.jruby.runtime.ThreadContext;
import org.w3c.dom.Attr;
import org.w3c.dom.Element;
import org.w3c.dom.NamedNodeMap;

/**
 *
 * @author sergio
 */
public class XmlElementMethods extends XmlNodeMethods{

    @Override
    public void relink_namespace(ThreadContext context, XmlNode node) {
        Element e = (Element) node.getNode();
        e.getOwnerDocument().renameNode(e, e.lookupNamespaceURI(e.getPrefix()), e.getNodeName());

        if(e.hasAttributes()) {
            NamedNodeMap attrs = e.getAttributes();

            for(int i = 0; i < attrs.getLength(); i++) {
                Attr attr = (Attr) attrs.item(i);
                e.getOwnerDocument().renameNode(attr, attr.lookupNamespaceURI(attr.getPrefix()), attr.getNodeName());
            }
        }
    }
}
