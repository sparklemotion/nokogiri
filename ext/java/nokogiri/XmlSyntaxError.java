package nokogiri;

import static nokogiri.internals.NokogiriHelpers.stringOrNil;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyException;
import org.jruby.RubyModule;
import org.jruby.anno.JRubyClass;
import org.xml.sax.SAXParseException;

@JRubyClass(name="Nokogiri::XML::SyntaxError", parent="Nokogiri::SyntaxError")
public class XmlSyntaxError extends RubyException {

    protected Exception exception;

    public static RubyClass getRubyClass(Ruby ruby) {
        return ((RubyModule) ruby.getModule("Nokogiri").getConstant("XML")).getClass("SyntaxError");
    }

    public XmlSyntaxError(Ruby ruby){
        this(ruby, getRubyClass(ruby));
    }

    public XmlSyntaxError(Ruby ruby, RubyClass rubyClass) {
        super(ruby, rubyClass);
    }

    public XmlSyntaxError(Ruby ruby, Exception ex) {
        this(ruby);
        this.exception = ex;
    }

    public XmlSyntaxError(Ruby ruby, RubyClass rubyClass, Exception ex) {
        super(ruby, rubyClass, ex.getMessage());
        this.exception = ex;
    }

    public static XmlSyntaxError createWarning(Ruby ruby, SAXParseException e) {
        return new XmlSyntaxError(ruby, e, 1);
    }

    public static XmlSyntaxError createError(Ruby ruby, SAXParseException e) {
        return new XmlSyntaxError(ruby, e, 2);
    }

    public static XmlSyntaxError createFatalError(Ruby ruby, SAXParseException e) {
        return new XmlSyntaxError(ruby, e, 3);
    }

    public XmlSyntaxError(Ruby ruby, SAXParseException e, int level) {
        super(ruby, getRubyClass(ruby), e.getMessage());
        this.exception = e;
        setInstanceVariable("@level", ruby.newFixnum(level));
        setInstanceVariable("@line", ruby.newFixnum(e.getLineNumber()));
        setInstanceVariable("@column", ruby.newFixnum(e.getColumnNumber()));
        setInstanceVariable("@file", stringOrNil(ruby, e.getSystemId()));
    }

    public static RubyException createXPathSyntaxError(Ruby runtime, Exception e) {
        RubyClass klazz = (RubyClass)
            runtime.getClassFromPath("Nokogiri::XML::XPath::SyntaxError");
        return new XmlSyntaxError(runtime, klazz, e);
    }

    // public static RubyException getXPathSyntaxError(ThreadContext context, Exception ex) {
    //     Ruby ruby = context.getRuntime();
    //     RubyClass klazz = (RubyClass) ruby.getClassFromPath("Nokogiri::XML::XPath::SyntaxError");
    //     return new XmlSyntaxError(ruby, klazz, ex);
    // }

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

}
