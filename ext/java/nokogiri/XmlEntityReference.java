package nokogiri;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.w3c.dom.Node;

import static nokogiri.internals.NokogiriHelpers.rubyStringToString;

/**
 *
 * @author sergio
 * @author Patrick Mahoney <pat@polycrystal.org>
 */
public class XmlEntityReference extends XmlNode{

    public XmlEntityReference(Ruby ruby, RubyClass klazz) {
        super(ruby, klazz);
    }

    public XmlEntityReference(Ruby ruby, RubyClass klass, Node node) {
        super(ruby, klass, node);
    }

    @JRubyMethod(name="new", meta=true)
    public static IRubyObject rbNew(ThreadContext context,
                                    IRubyObject klass,
                                    IRubyObject doc,
                                    IRubyObject name) {
        Document document = ((XmlNode) doc).getOwnerDocument();
        Node node = document.createEntityReference(rubyStringToString(name));
        XmlEntityReference self = new XmlEntityReference(context.getRuntime(),
                                                         (RubyClass) klass,
                                                         node);

        RuntimeHelpers.invoke(context, self, "initialize", doc, name);

        // TODO: if_block_given.

        return self;
    }

}
