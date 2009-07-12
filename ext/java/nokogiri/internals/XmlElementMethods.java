package nokogiri.internals;

import nokogiri.XmlNamespace;
import nokogiri.XmlNode;
import org.jruby.Ruby;
import org.jruby.RubyString;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Attr;
import org.w3c.dom.Element;
import org.w3c.dom.NamedNodeMap;

/**
 *
 * @author sergio
 */
public class XmlElementMethods extends XmlNodeMethods{

    @Override
    public void add_namespace_definitions(ThreadContext context, XmlNode current, XmlNamespace ns, String prefix, String href) {
        Element e = (Element) current.getNode();
        e.setAttribute(prefix, href);

        current.updateNodeNamespaceIfNecessary(context, ns);
    }

    @Override
    public IRubyObject get(ThreadContext context, XmlNode current, IRubyObject key) {
        String keyString = key.convertToString().asJavaString();
        Element element = (Element) current.getNode();
        String value = element.getAttribute(keyString);
        if(!value.equals("")){
            return RubyString.newString(context.getRuntime(), value);
        }
        return context.getRuntime().getNil();
    }

    @Override
    public IRubyObject key_p(ThreadContext context, XmlNode current, IRubyObject k) {
        Ruby ruby = context.getRuntime();
        String key = k.convertToString().asJavaString();
        Element element = (Element)current.getNode();
        return ruby.newBoolean(element.hasAttribute(key));
    }

    @Override
    public void node_name_set(ThreadContext context, XmlNode current, IRubyObject nodeName) {
        String newName = nodeName.convertToString().asJavaString();
        current.getNode().getOwnerDocument().renameNode(current.getNode(), null, newName);
        current.setName(nodeName);
    }

    @Override
    public void op_aset(ThreadContext context, XmlNode current, IRubyObject index, IRubyObject val) {
        String key = index.convertToString().asJavaString();
        String value = val.convertToString().asJavaString();
        Element element = (Element)current.getNode();
        element.setAttribute(key, value);
    }

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
