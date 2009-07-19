package nokogiri.internals;

import nokogiri.XmlNode;
import org.jruby.runtime.ThreadContext;

/**
 *
 * @author sergio
 */
public class XmlCommentMethods extends XmlNodeMethods{

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
