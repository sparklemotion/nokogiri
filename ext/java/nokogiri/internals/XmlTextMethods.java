/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package nokogiri.internals;

import nokogiri.XmlNode;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

/**
 *
 * @author sergio
 */
public class XmlTextMethods extends XmlNodeMethods {

    @Override
    public IRubyObject blank_p(ThreadContext context, XmlNode node) {
        return context.getRuntime().newBoolean(this.isBlankNode(context, node));
    }

    @Override
    protected int getNokogiriNodeTypeInternal() { return 3; }

    @Override
    public void saveContent(ThreadContext context, XmlNode current, SaveContext ctx) {
        ctx.append(ctx.getCurrentIndentString());
        ctx.append(current.content(context).convertToString().asJavaString());
    }
}
