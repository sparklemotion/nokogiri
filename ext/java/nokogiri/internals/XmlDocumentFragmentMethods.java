package nokogiri.internals;

import nokogiri.XmlNode;
import nokogiri.XmlNodeSet;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.runtime.ThreadContext;

/**
 *
 * @author sergio
 */
public class XmlDocumentFragmentMethods extends XmlNodeMethods{

    @Override
    public void add_child(ThreadContext context, XmlNode current, XmlNode child) {
        // Some magic for DocumentFragment
        
        Ruby ruby = context.getRuntime();
        XmlNodeSet children = (XmlNodeSet) child.children(context);

        long length = children.length();

        RubyArray childrenArray = children.convertToArray();

        if(length != 0) {
            for(int i = 0; i < length; i++) {
                XmlNode item = (XmlNode) ((XmlNode) childrenArray.aref(ruby.newFixnum(i))).dup(context);
                current.add_child(context, item);
            }
        }
    }

    @Override
    protected int getNokogiriNodeTypeInternal() { return 11; }

    @Override
    public void relink_namespace(ThreadContext context, XmlNode current) {
        ((XmlNodeSet) current.children(context)).relink_namespace(context);
    }

    @Override
    public void saveContent(ThreadContext context, XmlNode current, SaveContext ctx) {
        this.saveNodeListContent(context, (XmlNodeSet) current.children(context), ctx);
    }
}
