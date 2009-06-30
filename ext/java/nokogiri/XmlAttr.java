package nokogiri;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Attr;
import org.w3c.dom.Element;
import org.w3c.dom.Node;

public class XmlAttr extends XmlNode{

    public XmlAttr(Ruby ruby, Node attr){
        super(ruby, ((RubyModule) ruby.getModule("Nokogiri").getConstant("XML")).getClass("Attr"), attr);
    }

    public XmlAttr(Ruby ruby, RubyClass rubyClass) {
        super(ruby, rubyClass);
    }

    public XmlAttr(Ruby ruby, RubyClass rubyClass, Node attr){
        super(ruby, rubyClass, attr);
    }

    @JRubyMethod(name="new", meta=true)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject doc, IRubyObject content){
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod(name="value=")
    public IRubyObject value_set(ThreadContext context, IRubyObject content){
        throw context.getRuntime().newNotImplementedError("not implemented");
    }
}
