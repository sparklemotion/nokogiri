/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package nokogiri;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Element;
import org.w3c.dom.Node;

/**
 *
 * @author sergio
 */
public class XmlElement extends XmlNode {

    public XmlElement(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }

    public XmlElement(Ruby runtime, RubyClass klazz, Node element) {
        super(runtime, klazz, element);
    }

    @Override
    @JRubyMethod
    public IRubyObject add_namespace_definition(ThreadContext context, IRubyObject prefix, IRubyObject href) {
        Element e = (Element) this.node;

        String pref = "xmlns";
        
        if(!prefix.isNil()) {
            pref += ":"+prefix.convertToString().asJavaString();
        }

        e.setAttribute(pref, href.convertToString().asJavaString());

        return super.add_namespace_definition(context, prefix, href);
    }
}
