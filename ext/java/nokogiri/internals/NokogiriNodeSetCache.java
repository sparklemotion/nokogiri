package nokogiri.internals;

import java.util.Hashtable;
import nokogiri.XmlNode;
import nokogiri.XmlNodeSet;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.runtime.ThreadContext;
import org.w3c.dom.NodeList;

/**
 *
 * @author sergio
 */
public class NokogiriNodeSetCache {

    private Hashtable<RubyArray,XmlNodeSet> cache;


    public NokogiriNodeSetCache() {
        this.cache = new Hashtable<RubyArray, XmlNodeSet>();
    }

    public XmlNodeSet get(ThreadContext context, NodeList nodes) {
        Ruby ruby = context.getRuntime();
        RubyArray n = RubyArray.newArray(ruby, nodes.getLength());
        for(int i = 0; i < nodes.getLength(); i++) {
            n.append(NokogiriHelpers.getCachedNodeOrCreate(ruby, nodes.item(i)));
        }

        return get(context, n);
    }

    public XmlNodeSet get(ThreadContext context, RubyArray nodes) {
        if(!this.cache.containsKey(nodes)) {
            Ruby ruby = context.getRuntime();
            XmlNodeSet newNodeSet = new XmlNodeSet(ruby,
                    (RubyClass) ruby.getClassFromPath("Nokogiri::XML::NodeSet"),
                    nodes);
            this.cache.put(nodes, newNodeSet);
            return newNodeSet;
        } else {
            return this.cache.get(nodes);
        }
    }
}
