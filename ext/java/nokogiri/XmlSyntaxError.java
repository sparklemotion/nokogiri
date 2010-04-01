package nokogiri;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyException;
import org.jruby.RubyModule;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

public class XmlSyntaxError extends RubyException {

    protected Exception exception;

    public XmlSyntaxError(Ruby ruby){
        this(ruby, ((RubyModule) ruby.getModule("Nokogiri").getConstant("XML")).getClass("SyntaxError"));
    }

    public XmlSyntaxError(Ruby ruby, RubyClass rubyClass) {
        super(ruby, rubyClass);
    }

    public XmlSyntaxError(Ruby ruby, Exception ex) {
        this(ruby);
        this.exception = ex;
    }

    public XmlSyntaxError(Ruby ruby, RubyClass rubyClass, Exception ex) {
        this(ruby, rubyClass);
        this.exception = ex;
    }

    public static RubyException getXPathSyntaxError(ThreadContext context) {
        Ruby ruby = context.getRuntime();
        RubyClass klazz = (RubyClass) ruby.getClassFromPath("Nokogiri::XML::XPath::SyntaxError");
        return new XmlSyntaxError(ruby, klazz);
    }

    public static RubyException getXPathSyntaxError(ThreadContext context, Exception ex) {
        Ruby ruby = context.getRuntime();
        RubyClass klazz = (RubyClass) ruby.getClassFromPath("Nokogiri::XML::XPath::SyntaxError");
        return new XmlSyntaxError(ruby, klazz, ex);
    }

    //TODO: Return correct message, domain, etc.

//     @JRubyMethod
//     @Override
//     public IRubyObject message(ThreadContext context) {
//         if(this.exception != null) {
//             return context.getRuntime().newString(this.exception.toString());
//         } else {
//             return context.getRuntime().newString("no message");
//         }
//     }

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
