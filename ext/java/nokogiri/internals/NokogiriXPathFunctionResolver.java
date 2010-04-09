package nokogiri.internals;

import javax.xml.namespace.QName;
import javax.xml.xpath.XPathFunction;
import javax.xml.xpath.XPathFunctionResolver;
import org.jruby.runtime.builtin.IRubyObject;

/**
 *
 * @author sergio
 */
public class NokogiriXPathFunctionResolver implements XPathFunctionResolver {

    private IRubyObject handler;
    
    public NokogiriXPathFunctionResolver(IRubyObject handler) {
        this.handler = handler;
    }

    public XPathFunction resolveFunction(QName name, int arity) {
        return new NokogiriXPathFunction(this.handler, name.getLocalPart(), arity);
    }
}
