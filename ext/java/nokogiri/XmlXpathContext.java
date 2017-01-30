/**
 * (The MIT License)
 *
 * Copyright (c) 2008 - 2014:
 *
 * * {Aaron Patterson}[http://tenderlovemaking.com]
 * * {Mike Dalessio}[http://mike.daless.io]
 * * {Charles Nutter}[http://blog.headius.com]
 * * {Sergio Arbeo}[http://www.serabe.com]
 * * {Patrick Mahoney}[http://polycrystal.org]
 * * {Yoko Harada}[http://yokolet.blogspot.com]
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * 'Software'), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

package nokogiri;

import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;

import java.util.Set;

import javax.xml.transform.TransformerException;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;

import nokogiri.internals.NokogiriNamespaceContext;
import nokogiri.internals.NokogiriXPathFunctionResolver;
import nokogiri.internals.NokogiriXPathVariableResolver;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import org.apache.xml.dtm.DTM;
import org.apache.xml.utils.PrefixResolver;
import org.apache.xpath.XPathContext;
import org.apache.xpath.jaxp.JAXPExtensionsProvider;
import org.apache.xpath.jaxp.JAXPPrefixResolver;
import org.apache.xpath.jaxp.JAXPVariableStack;
import org.apache.xpath.objects.XObject;

/**
 * Class for Nokogiri::XML::XpathContext
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 * @author John Shahid <jvshahid@gmail.com>
 */
@JRubyClass(name="Nokogiri::XML::XPathContext")
public class XmlXpathContext extends RubyObject {

    /**
     * user-data key for (cached) {@link XPathContext}
     */
    public static final String XPATH_CONTEXT = "CACHED_XPATH_CONTEXT";

    private XmlNode context;
    private final NokogiriXPathFunctionResolver functionResolver;
    private final NokogiriXPathVariableResolver variableResolver;
    private PrefixResolver prefixResolver;
    private XPathContext xpathSupport = null;
    private NokogiriNamespaceContext nsContext;

    public XmlXpathContext(Ruby runtime, RubyClass rubyClass) {
        super(runtime, rubyClass);
        functionResolver = NokogiriXPathFunctionResolver.create(runtime.getNil());
        variableResolver = NokogiriXPathVariableResolver.create();
    }

    private void setNode(XmlNode node) {
        Node doc = node.getNode().getOwnerDocument();
        if (doc == null) {
            doc = node.getNode();
        }
        xpathSupport = (XPathContext) doc.getUserData(XPATH_CONTEXT);

        if (xpathSupport == null) {
            JAXPExtensionsProvider jep = getProviderInstance();
            xpathSupport = new XPathContext(jep);
            xpathSupport.setVarStack(new JAXPVariableStack(variableResolver));
            doc.setUserData(XPATH_CONTEXT, xpathSupport, null);
        }

        context = node;
        nsContext = NokogiriNamespaceContext.create();
        prefixResolver = new JAXPPrefixResolver(nsContext);
    }

    private JAXPExtensionsProvider getProviderInstance() {
        return new JAXPExtensionsProvider(functionResolver, false);
    }

    /**
     * Create and return a copy of this object.
     *
     * @return a clone of this object
     */
    @Override
    public Object clone() throws CloneNotSupportedException {
        return super.clone();
    }

    @JRubyMethod(name = "new", meta = true)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject klazz, IRubyObject node) {
        XmlNode xmlNode = (XmlNode)node;
        XmlXpathContext xmlXpathContext = (XmlXpathContext) NokogiriService.XML_XPATHCONTEXT_ALLOCATOR.allocate(context.getRuntime(), (RubyClass)klazz);
        XPathFactory.newInstance().newXPath();
        try {
            xmlXpathContext.setNode(xmlNode);
        }
        catch (IllegalArgumentException e) {
            throw context.getRuntime().newRuntimeError(e.getMessage());
        }
        return xmlXpathContext;
    }

    @JRubyMethod
    public IRubyObject evaluate(ThreadContext context, IRubyObject expr, IRubyObject handler) {
        functionResolver.setHandler(handler);

        String src = expr.convertToString().asJavaString();
        if (!handler.isNil()) {
            if (!isContainsPrefix(src)) {
                StringBuilder replacement = new StringBuilder();
                Set<String> methodNames = handler.getMetaClass().getMethods().keySet();
                final String PREFIX = NokogiriNamespaceContext.NOKOGIRI_PREFIX;
                for (String name : methodNames) {
                    replacement.setLength(0);
                    replacement.ensureCapacity(PREFIX.length() + 1 + name.length());
                    replacement.append(PREFIX).append(':').append(name);
                    src = src.replace(name, replacement); // replace(name, NOKOGIRI_PREFIX + ':' + name)
                }
            }
        }
        return node_set(context, src);
    }

    @JRubyMethod
    public IRubyObject evaluate(ThreadContext context, IRubyObject expr) {
        return this.evaluate(context, expr, context.getRuntime().getNil());
    }

    @JRubyMethod
    public IRubyObject register_ns(ThreadContext context, IRubyObject prefix, IRubyObject uri) {
        nsContext.registerNamespace((String)prefix.toJava(String.class), (String)uri.toJava(String.class));
        return this;
    }

    @JRubyMethod
    public IRubyObject register_variable(ThreadContext context, IRubyObject name, IRubyObject value) {
        variableResolver.registerVariable((String)name.toJava(String.class), (String)value.toJava(String.class));
        return this;
    }

    protected IRubyObject node_set(ThreadContext context, String expr) {
        try {
            return tryGetNodeSet(context, expr);
        }
        catch (XPathExpressionException ex) {
            throw new RaiseException(XmlSyntaxError.createXMLXPathSyntaxError(context.runtime, ex)); // Nokogiri::XML::XPath::SyntaxError
        }
    }

    private IRubyObject tryGetNodeSet(ThreadContext thread_context, String expr) throws XPathExpressionException {
        Node contextNode = context.node;

        try {
          org.apache.xpath.XPath xpathInternal = new org.apache.xpath.XPath (expr, null,
                      prefixResolver, org.apache.xpath.XPath.SELECT );

          // We always need to have a ContextNode with Xalan XPath implementation
          // To allow simple expression evaluation like 1+1 we are setting
          // dummy Document as Context Node
          final XObject xobj;
          if ( contextNode == null )
              xobj = xpathInternal.execute(xpathSupport, DTM.NULL, prefixResolver);
          else
              xobj = xpathInternal.execute(xpathSupport, contextNode, prefixResolver);

          switch (xobj.getType()) {
          case XObject.CLASS_BOOLEAN:
            return thread_context.getRuntime().newBoolean(xobj.bool());
          case XObject.CLASS_NUMBER:
            return thread_context.getRuntime().newFloat(xobj.num());
          case XObject.CLASS_NODESET:
            NodeList nodeList = xobj.nodelist();
            XmlNodeSet xmlNodeSet = (XmlNodeSet) NokogiriService.XML_NODESET_ALLOCATOR.allocate(getRuntime(), getNokogiriClass(getRuntime(), "Nokogiri::XML::NodeSet"));
            xmlNodeSet.setNodeList(nodeList);
            xmlNodeSet.initialize(thread_context.getRuntime(), context);
            return xmlNodeSet;
          default:
            return thread_context.getRuntime().newString(xobj.str());
          }
        } catch(TransformerException ex) {
          throw new XPathExpressionException(expr);
        }
    }

    private boolean isContainsPrefix(final String str) {
        final StringBuilder prefix_ = new StringBuilder();
        for ( String prefix : nsContext.getAllPrefixes() ) {
            prefix_.setLength(0);
            prefix_.ensureCapacity(prefix.length() + 1);
            prefix_.append(prefix).append(':');
            if ( str.contains(prefix_) ) { // prefix + ':'
                return true;
            }
        }
        return false;
    }

}
