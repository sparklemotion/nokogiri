/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package nokogiri;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.runtime.ThreadContext;
import org.w3c.dom.Attr;
import org.w3c.dom.Element;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

/**
 *
 * @author sergio
 */
public class XmlElement extends XmlNode {

    public XmlElement(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }

    public XmlElement(Ruby runtime, RubyClass klazz, Node element) {
        super(runtime, klazz, element);
    }

    @Override
    protected void relink_namespace(ThreadContext context) {
        String qName = this.node.getNodeName();
        if(this.node.getPrefix() == null) {
            qName = ":" + qName;
        }
        Element newElement = this.node.getOwnerDocument().createElementNS(
                this.node.lookupNamespaceURI(this.node.getPrefix())
                , qName);

        NamedNodeMap attrs = this.node.getAttributes();
        for(int i = 0; i < attrs.getLength(); i++) {
            newElement.setAttributeNodeNS((Attr) attrs.item(i));
        }

        NodeList children = this.node.getChildNodes();
        for(int i = 0; i < children.getLength(); i++) {
            newElement.appendChild(children.item(i));
        }

        this.node = newElement;
        this.node.getOwnerDocument().replaceChild(this.node, newElement);

        super.relink_namespace(context);
    }
}
