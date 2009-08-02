package nokogiri;

import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpression;
import javax.xml.xpath.XPathExpressionException;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

public class XmlXpath extends RubyObject {
    private XPathExpression xpath;
    private Node context;
    private XmlNode contextNode;

    public XmlXpath(Ruby ruby, RubyClass rubyClass, XPathExpression xpath, XmlNode context) {
        super(ruby, rubyClass);
        this.xpath = xpath;

        this.contextNode = context;

        //TODO: Refactor.
        if(context.getNode() instanceof Document) {
            this.context = context.getNode();
        } else {
            this.context = context.getNode().getParentNode();
        }
    }

    @JRubyMethod(name = "node_set")
    public IRubyObject node_set(ThreadContext context) {
        try {
            NodeList nodes = (NodeList)xpath.evaluate(this.context, XPathConstants.NODESET);
            XmlNodeSet result = new XmlNodeSet(context.getRuntime(), nodes);
            result.relink_namespace(context);
            return result;
        } catch (XPathExpressionException xpee) {
            throw new RaiseException(XmlSyntaxError.getXPathSyntaxError(context));
        }
    }
}