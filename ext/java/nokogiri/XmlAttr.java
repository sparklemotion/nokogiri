package nokogiri;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

public class XmlAttr extends XmlNode{

    public XmlAttr(Ruby ruby, RubyClass rubyClass){
        super(ruby, rubyClass);
    }

    @JRubyMethod(name="new", meta=true)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject doc, IRubyObject content){
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod(name="value=")
    public static IRubyObject value_set(ThreadContext context, IRubyObject content){
        throw context.getRuntime().newNotImplementedError("not implemented");
    }
}
