package nokogiri;

import nokogiri.internals.NokogiriHelpers;
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
        if(!(doc instanceof XmlDocument)) {
            throw context.getRuntime().newArgumentError("document must be an instance of Nokogiri::XML::Document");
        }

        XmlDocument xmlDoc = (XmlDocument)doc;

        return new XmlAttr(context.getRuntime(),
                xmlDoc.getDocument().createAttribute(content.convertToString().asJavaString()));
    }

    @JRubyMethod(name="value=")
    public IRubyObject value_set(ThreadContext context, IRubyObject content){
        Attr current = (Attr) node();
        current.setValue(this.encode_special_chars(context, content).convertToString().asJavaString());
        this.internalNode.setContent(content);
        return content;
    }
}
