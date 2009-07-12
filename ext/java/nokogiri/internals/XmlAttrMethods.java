package nokogiri.internals;

import nokogiri.XmlNode;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

/**
 *
 * @author sergio
 */
public class XmlAttrMethods extends XmlNodeMethods{

    @Override
    public void node_name_set(ThreadContext context, XmlNode current, IRubyObject nodeName) {
        String newName = nodeName.convertToString().asJavaString();
        current.getNode().getOwnerDocument().renameNode(current.getNode(), null, newName);
        current.setName(nodeName);
    }
}
