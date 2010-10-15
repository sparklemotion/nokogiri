package nokogiri;

import static nokogiri.internals.NokogiriHelpers.rubyStringToString;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.w3c.dom.Node;

/**
 *
 * @author sergio
 * @author Patrick Mahoney <pat@polycrystal.org>
 */
@JRubyClass(name="Nokogiri::XML::EntityReference", parent="Nokogiri::XML::Node")
public class XmlEntityReference extends XmlNode{

    public XmlEntityReference(Ruby ruby, RubyClass klazz) {
        super(ruby, klazz);
    }

    public XmlEntityReference(Ruby ruby, RubyClass klass, Node node) {
        super(ruby, klass, node);
    }

    protected void init(ThreadContext context, IRubyObject[] args) {
        if (args.length < 2) {
            throw getRuntime().newArgumentError(args.length, 2);
        }

        IRubyObject doc = args[0];
        IRubyObject name = args[1];

        Document document = ((XmlNode) doc).getOwnerDocument();
        Node node = document.createEntityReference(rubyStringToString(name));
        setNode(context, node);
    }

}
