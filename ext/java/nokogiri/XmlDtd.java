package nokogiri;

import nokogiri.internals.XmlDocumentTypeImpl;

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
        return ((XmlDocumentTypeImpl)internalNode).getAttributes(context);
    }

    @JRubyMethod
    public IRubyObject elements(ThreadContext context) {
        return ((XmlDocumentTypeImpl)internalNode).getElements(context);
    }

    @JRubyMethod
    public IRubyObject entities(ThreadContext context) {
        return ((XmlDocumentTypeImpl)internalNode).getEntities(context);
    }

    @JRubyMethod
    public IRubyObject notations(ThreadContext context) {
        return ((XmlDocumentTypeImpl)internalNode).getNotations(context);
    }
    
    @JRubyMethod
    public IRubyObject system_id(ThreadContext context) {
         return ((XmlDocumentTypeImpl)internalNode).getSystemId(context);
    }
    
    @JRubyMethod
    public IRubyObject external_id(ThreadContext context) {
         return ((XmlDocumentTypeImpl)internalNode).getPublicId(context);
    }
}