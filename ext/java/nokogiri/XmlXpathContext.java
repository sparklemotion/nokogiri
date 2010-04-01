package nokogiri;

import java.util.Set;

import nokogiri.internals.NokogiriNamespaceContext;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathExpression;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;
import nokogiri.internals.NokogiriXPathFunctionResolver;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

public class XmlXpathContext extends RubyObject {
    private XmlNode context;
    private XPath xpath;

    public XmlXpathContext(Ruby ruby, RubyClass rubyClass, XmlNode context) {
        super(ruby, rubyClass);
        this.context = context;
        this.xpath = XPathFactory.newInstance().newXPath();
        this.xpath.setNamespaceContext(new NokogiriNamespaceContext());
    }

    @JRubyMethod(name = "new", meta = true)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject node) {
        XmlNode xmlNode = (XmlNode)node;
        return new XmlXpathContext(context.getRuntime(), (RubyClass)cls, xmlNode);
    }

    @JRubyMethod
    public IRubyObject evaluate(ThreadContext context, IRubyObject expr, IRubyObject handler) {
        String src = expr.convertToString().asJavaString();
        try {
            if(!handler.isNil()) {
            	if (!isContainsPrefix(src)) {
                    Set<String> methodNames = handler.getMetaClass().getMethods().keySet();
                    for (String name : methodNames) {
                        src = src.replaceAll(name, NokogiriNamespaceContext.NOKOGIRI_PREFIX+":"+name);
                    }
                }
                xpath.setXPathFunctionResolver(new NokogiriXPathFunctionResolver(handler));
            }
            XPathExpression xpathExpression = xpath.compile(src);
            return new XmlXpath(context.getRuntime(), (RubyClass)context.getRuntime().getClassFromPath("Nokogiri::XML::XPath"), xpathExpression, this.context);
        } catch (XPathExpressionException xpee) {
            throw new RaiseException(XmlSyntaxError.getXPathSyntaxError(context, xpee));
        }
    }
    
    private boolean isContainsPrefix(String str) {
        Set<String> prefixes = ((NokogiriNamespaceContext)xpath.getNamespaceContext()).getAllPrefixes();
        for (String prefix : prefixes) {
            if (str.contains(prefix + ":")) {
                return true;
            }
        }
        return false;
    }


    @JRubyMethod
    public IRubyObject evaluate(ThreadContext context, IRubyObject expr) {
        return this.evaluate(context, expr, context.getRuntime().getNil());
    }

    @JRubyMethod
    public IRubyObject register_ns(ThreadContext context, IRubyObject prefix, IRubyObject uri) {
        ((NokogiriNamespaceContext) this.xpath.getNamespaceContext()).registerNamespace(prefix.convertToString().asJavaString(), uri.convertToString().asJavaString());
        return this;
    }
}
