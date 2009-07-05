package nokogiri;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Node;

public class XmlDtd extends XmlNode {
    public XmlDtd(Ruby ruby, RubyClass rubyClass) {
        super(ruby, rubyClass);
    }

    public XmlDtd(Ruby ruby, RubyClass rubyClass, Node node) {
        super(ruby, rubyClass, node);
    }

    @Override
    @JRubyMethod
    public IRubyObject attributes(ThreadContext context) {
        return context.getRuntime().getNil();
    }

    @JRubyMethod
    public IRubyObject elements(ThreadContext context) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod
    public IRubyObject entities(ThreadContext context) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod
    public IRubyObject notations(ThreadContext context) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }
}