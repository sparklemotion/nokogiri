package nokogiri.internals;

import nokogiri.XmlNode;
import org.jruby.Ruby;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Node;

/**
 *
 * @author sergio
 */
public class XmlTextImpl extends XmlNodeImpl {

    public XmlTextImpl(Ruby ruby, Node node) {
        super(ruby, node);
    }

    @Override
    public IRubyObject blank_p(ThreadContext context, XmlNode node) {
        return context.getRuntime().newBoolean(this.isBlankNode(context, node));
    }

    @Override
    protected int getNokogiriNodeTypeInternal() { return 3; }

    @Override
    public void saveContent(ThreadContext context, XmlNode current, SaveContext ctx) {
        if(ctx.format()) {
            ctx.append(ctx.getCurrentIndentString());
        }
        ctx.append(current.content(context).convertToString().asJavaString());
    }

    @Override
    public void saveContentAsHtml(ThreadContext context, XmlNode current, SaveContext ctx) {
        ctx.append(current.content(context).convertToString().asJavaString());
    }
}
