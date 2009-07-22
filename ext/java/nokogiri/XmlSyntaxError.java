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

    //TODO: Return correct message, domain, etc.

    @JRubyMethod
    @Override
    public IRubyObject message(ThreadContext context) {
        return context.getRuntime().getNil();
    }

    @JRubyMethod
    public IRubyObject domain(ThreadContext context) {
        return context.getRuntime().getNil();
    }

    @JRubyMethod
    public IRubyObject code(ThreadContext context) {
        return context.getRuntime().getNil();
    }

    @JRubyMethod
    public IRubyObject level(ThreadContext context) {
        return context.getRuntime().getNil();
    }

    @JRubyMethod
    public IRubyObject file(ThreadContext context) {
        return context.getRuntime().getNil();
    }

    @JRubyMethod
    public IRubyObject line(ThreadContext context) {
        return context.getRuntime().getNil();
    }

    @JRubyMethod
    public IRubyObject str1(ThreadContext context) {
        return context.getRuntime().getNil();
    }

    @JRubyMethod
    public IRubyObject str2(ThreadContext context) {
        return context.getRuntime().getNil();
    }

    @JRubyMethod
    public IRubyObject str3(ThreadContext context) {
        return context.getRuntime().getNil();
    }

    @JRubyMethod
    public IRubyObject int1(ThreadContext context) {
        return context.getRuntime().getNil();
    }

    @JRubyMethod
    public IRubyObject column(ThreadContext context) {
        return context.getRuntime().getNil();
    }
}