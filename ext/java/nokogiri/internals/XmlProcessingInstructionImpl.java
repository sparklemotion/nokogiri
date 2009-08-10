/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

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
public class XmlProcessingInstructionImpl extends XmlNodeImpl{

    public XmlProcessingInstructionImpl(Ruby ruby, Node node) {
        super(ruby, node);
    }

    @Override
    protected int getNokogiriNodeTypeInternal() { return 7; }

    @Override
    public boolean isProcessingInstruction() { return true; }

    @Override
    public void saveContent(ThreadContext context, XmlNode current, SaveContext ctx) {
        ctx.append("<?");
        ctx.append(current.node_name(context).convertToString().asJavaString());
        IRubyObject content = current.content(context);
        if(!content.isNil()) {
            ctx.append(content.convertToString().asJavaString());
        }
        ctx.append("?>");
    }

    @Override
    public void saveContentAsHtml(ThreadContext context, XmlNode current, SaveContext ctx) {
        ctx.append("<?");
        ctx.append(current.node_name(context).convertToString().asJavaString());
        IRubyObject content = current.content(context);
        if(!content.isNil()) {
            ctx.append(" ");
            ctx.append(content.convertToString().asJavaString());
        }
        ctx.append(">");
    }

}
