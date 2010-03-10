package nokogiri;

import org.apache.xerces.dom.DeferredNotationImpl;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyStruct;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Node;

/**
 * NOTATION declaration of DTD
 * 
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class XmlNotation extends RubyStruct {
    private DeferredNotationImpl internalNode;

    public XmlNotation(Ruby runtime, RubyClass klazz, Node node) {
        super(runtime, klazz);
        internalNode = (DeferredNotationImpl) node;
    }
    
    public Node getNode() {
        return internalNode;
    }
    
    @JRubyMethod
    public IRubyObject name(ThreadContext context) {
        return JavaUtil.convertJavaToRuby(context.getRuntime(), internalNode.getNodeName());
    }
    
    @JRubyMethod
    public IRubyObject system_id(ThreadContext context) {
        return JavaUtil.convertJavaToRuby(context.getRuntime(), internalNode.getSystemId());
    }
    
    @JRubyMethod
    public IRubyObject public_id(ThreadContext context) {
        return JavaUtil.convertJavaToRuby(context.getRuntime(), internalNode.getPublicId());
    }
}
