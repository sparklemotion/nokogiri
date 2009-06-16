package nokogiri;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyException;
import org.jruby.RubyModule;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

public class XmlSyntaxError extends RubyException {

    public XmlSyntaxError(Ruby ruby){
        this(ruby, ((RubyModule) ruby.getModule("Nokogiri").getConstant("XML")).getClass("SyntaxError"));
    }

    public XmlSyntaxError(Ruby ruby, RubyClass rubyClass) {
        super(ruby, rubyClass);
    }

    @JRubyMethod
    public IRubyObject message(ThreadContext context, IRubyObject arg1) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod
    public IRubyObject domain(ThreadContext context, IRubyObject arg) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod
    public IRubyObject code(ThreadContext context, IRubyObject arg) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod
    public IRubyObject level(ThreadContext context, IRubyObject arg) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod
    public IRubyObject file(ThreadContext context, IRubyObject arg) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod
    public IRubyObject line(ThreadContext context, IRubyObject arg) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod
    public IRubyObject str1(ThreadContext context, IRubyObject arg) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod
    public IRubyObject str2(ThreadContext context, IRubyObject arg) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod
    public IRubyObject str3(ThreadContext context, IRubyObject arg) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod
    public IRubyObject int1(ThreadContext context, IRubyObject arg) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod
    public IRubyObject column(ThreadContext context, IRubyObject arg) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }
}