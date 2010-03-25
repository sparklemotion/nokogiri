package nokogiri;

import nokogiri.internals.XmlAttributeDeclImpl;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Node;

/**
 * ATTLIST declaration of DTD
 * 
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class XmlAttributeDecl extends XmlNode implements XmlDtdDeclaration {
    private Node parent;

    public XmlAttributeDecl(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }

    public XmlAttributeDecl(Ruby runtime, RubyClass klazz, Node attribute, Node parent) {
        super(runtime, klazz, attribute);
        this.parent = parent;
        internalNode = new XmlAttributeDeclImpl(runtime, attribute);
    }
    
    public Node getParent() {
        return parent;
    }

    @JRubyMethod(name="default")
    public IRubyObject op_default(ThreadContext context) {
        return ((XmlAttributeDeclImpl)internalNode).getDefault(context);
    }
    
    public void setDeclaration(String declaration) {
        ((XmlAttributeDeclImpl)internalNode).setDeclaration(declaration);
    }
}
