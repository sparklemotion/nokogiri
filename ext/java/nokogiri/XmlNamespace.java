package nokogiri;

import static nokogiri.internals.NokogiriHelpers.getLocalNameForNamespace;
import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;
import nokogiri.internals.SaveContext;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Node;

/**
 *
 * @author serabe
 */
@JRubyClass(name="Nokogiri::XML::Namespace")
public class XmlNamespace extends RubyObject {

    private IRubyObject prefix;
    private IRubyObject href;

    public XmlNamespace(Ruby ruby, RubyClass klazz) {
        super(ruby, klazz);
    }

    public XmlNamespace(Ruby ruby, String prefix, String href) {
        this(ruby, getNokogiriClass(ruby, "Nokogiri::XML::Namespace"), prefix, href);
    }

    public XmlNamespace(Ruby ruby, RubyClass klazz, String prefix, String href) {
        super(ruby, klazz);
        this.prefix = (prefix == null) ? ruby.getNil() : ruby.newString(prefix);
        this.href = (href == null) ? ruby.getNil() : ruby.newString(href);
    }

    public XmlNamespace(Ruby ruby, IRubyObject prefix, IRubyObject href) {
        this(ruby, getNokogiriClass(ruby, "Nokogiri::XML::Namespace"), prefix, href);
    }

    public XmlNamespace(Ruby ruby, RubyClass klazz, IRubyObject prefix, IRubyObject href) {
        super(ruby, klazz);
        this.prefix = prefix;
        this.href = href;
    }

    public static XmlNamespace fromNode(Ruby ruby, Node node) {
        String localName = getLocalNameForNamespace(node.getNodeName());

        return new XmlNamespace(ruby, getNokogiriClass(ruby, "Nokogiri::XML::Namespace"), localName, node.getNodeValue());
    }

    public boolean isEmpty() {
        return this.prefix.isNil() && this.href.isNil();
    }

    public void setDocument(IRubyObject doc) {
        this.setInstanceVariable("@document", doc);
    }

    @JRubyMethod
    public IRubyObject href(ThreadContext context) {
        return this.href;
    }

    @JRubyMethod
    public IRubyObject prefix(ThreadContext context) {
        return this.prefix;
    }
    
    public void saveContent(ThreadContext context, SaveContext ctx) {
        ctx.append(" " + prefix + "=\"" + href + "\"");
    }
}
