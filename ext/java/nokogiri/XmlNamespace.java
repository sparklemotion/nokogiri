/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package nokogiri;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Node;

import static nokogiri.NokogiriHelpers.getLocalName;

/**
 *
 * @author serabe
 */
public class XmlNamespace extends RubyObject {

    private IRubyObject prefix;
    private IRubyObject href;

    public XmlNamespace(Ruby ruby, RubyClass klazz) {
        super(ruby, klazz);
    }

    public XmlNamespace(Ruby ruby, RubyClass klazz, String prefix, String href) {
        super(ruby, klazz);
        this.prefix = (prefix == null) ? ruby.getNil() : ruby.newString(prefix);
        this.href = (href == null) ? ruby.getNil() : ruby.newString(href);
    }

    public static XmlNamespace fromNode(Ruby ruby, Node node) {
        String localName = getLocalName(node.getNodeName());
        return new XmlNamespace(ruby,
                    (RubyClass) ruby.getClassFromPath("Nokogiri::XML::Namespace"),
                    localName, node.getNodeValue());
    }

    @JRubyMethod
    public IRubyObject href(ThreadContext context) {
        return this.href;
    }

    @JRubyMethod
    public IRubyObject prefix(ThreadContext context) {
        return this.prefix;
    }
}
