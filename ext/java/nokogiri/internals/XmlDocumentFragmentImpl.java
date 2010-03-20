package nokogiri.internals;

import nokogiri.XmlNode;
import nokogiri.XmlNodeSet;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.runtime.ThreadContext;
import org.w3c.dom.Node;

/**
 *
 * @author sergio
 */
public class XmlDocumentFragmentImpl extends XmlNodeImpl {

    public XmlDocumentFragmentImpl(Ruby ruby, Node node) {
        super(ruby, node);
    }

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
 
    public void use_super_add_child(ThreadContext context, XmlNode current, XmlNode child) {
        super.add_child(context, current, child);
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
