package nokogiri;

import static nokogiri.internals.NokogiriHelpers.rubyStringToString;
import nokogiri.internals.SaveContext;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.w3c.dom.Node;

/**
 *
 * @author sergio
 */
@JRubyClass(name="Nokogiri::XML::ProcessingInstruction", parent="Nokogiri::XML::Node")
public class XmlProcessingInstruction extends XmlNode {

    public XmlProcessingInstruction(Ruby ruby, RubyClass klass, Node node) {
        super(ruby, klass, node);
    }

    @JRubyMethod(name="new", meta=true, rest=true, required=3)
    public static IRubyObject rbNew(ThreadContext context,
                                    IRubyObject klass,
                                    IRubyObject[] args) {

        IRubyObject doc = args[0];
        IRubyObject target = args[1];
        IRubyObject data = args[2];

        Document document = ((XmlNode) doc).getOwnerDocument();
        Node node =
            document.createProcessingInstruction(rubyStringToString(target),
                                                 rubyStringToString(data));
        XmlProcessingInstruction self =
            new XmlProcessingInstruction(context.getRuntime(),
                                         (RubyClass) klass,
                                         node);

        RuntimeHelpers.invoke(context, self, "initialize", args);

        // TODO: if_block_given.

        return self;
    }

    @Override
    public boolean isProcessingInstruction() { return true; }

    @Override
    public void saveContent(ThreadContext context, SaveContext ctx) {
        ctx.append("<?");
        ctx.append(node_name(context).convertToString().asJavaString());
        IRubyObject content = content(context);
        if(!content.isNil()) {
            if (ctx.asHtml()) ctx.append(" ");
            ctx.append(content.convertToString().asJavaString());
        }
        if (ctx.asHtml())
            ctx.append(">");
        else
            ctx.append("?>");
    }

}
