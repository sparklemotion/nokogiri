package nokogiri.internals;

import nokogiri.XmlNode;
import org.jruby.Ruby;
import org.jruby.runtime.ThreadContext;
import org.w3c.dom.Node;

/**
 *
 * @author sergio
 */
public class XmlCommentImpl extends XmlNodeImpl {

    public XmlCommentImpl(Ruby ruby, Node node) {
        super(ruby, node);
    }

    @Override
    protected int getNokogiriNodeTypeInternal() { return 8; }

    @Override
    public boolean isComment() { return true; }

    @Override
    public void saveContent(ThreadContext context, XmlNode current, SaveContext ctx) {
        ctx.append("<!--");
        ctx.append(current.content(context).convertToString().asJavaString());
        ctx.append("-->");
    }
}
