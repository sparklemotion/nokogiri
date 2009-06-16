package nokogiri;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

public class XsltStylesheet extends RubyObject {
    public XsltStylesheet(Ruby ruby, RubyClass rubyClass) {
        super(ruby, rubyClass);
    }

    @JRubyMethod(meta = true)
    public static IRubyObject parse_stylesheet_doc(ThreadContext context, IRubyObject cls, IRubyObject doc) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod
    public IRubyObject serialize(ThreadContext context, IRubyObject doc) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod(rest = true)
    public IRubyObject apply_to(ThreadContext context, IRubyObject[] args) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }
}