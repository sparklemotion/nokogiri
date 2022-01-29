package nokogiri;

import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.xml.transform.TransformerException;

import org.apache.xml.dtm.DTM;
import org.apache.xpath.XPath;
import org.apache.xpath.XPathContext;
import org.apache.xpath.jaxp.JAXPPrefixResolver;
import org.apache.xpath.jaxp.JAXPVariableStack;
import org.apache.xpath.objects.XObject;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.SafePropertyAccessor;
import org.w3c.dom.Node;

import nokogiri.internals.NokogiriNamespaceContext;
import nokogiri.internals.NokogiriXPathFunctionResolver;
import nokogiri.internals.NokogiriXPathVariableResolver;

import static nokogiri.internals.NokogiriHelpers.nodeListToRubyArray;

/**
 * Class for Nokogiri::XML::XpathContext
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 * @author John Shahid <jvshahid@gmail.com>
 */
@JRubyClass(name = "Nokogiri::XML::XPathContext")
public class XmlXpathContext extends RubyObject
{
  private static final long serialVersionUID = 1L;

  static
  {
    final String DTMManager = "org.apache.xml.dtm.DTMManager";
    if (SafePropertyAccessor.getProperty(DTMManager) == null) {
      try { // use patched "org.apache.xml.dtm.ref.DTMManagerDefault"
        System.setProperty(DTMManager, nokogiri.internals.XalanDTMManagerPatch.class.getName());
      } catch (SecurityException ex) { /* no-op - will work although might be slower */ }
    }
  }

  /**
   * user-data key for (cached) {@link XPathContext}
   */
  public static final String XPATH_CONTEXT = "CACHED_XPATH_CONTEXT";

  private XmlNode context;

  public
  XmlXpathContext(Ruby runtime, RubyClass klass)
  {
    super(runtime, klass);
  }

  public
  XmlXpathContext(Ruby runtime, RubyClass klass, XmlNode node)
  {
    this(runtime, klass);
    initNode(node);
  }

  private void
  initNode(XmlNode node)
  {
    context = node;
  }

  @JRubyMethod(name = "new", meta = true)
  public static IRubyObject
  rbNew(ThreadContext context, IRubyObject klazz, IRubyObject node)
  {
    try {
      return new XmlXpathContext(context.runtime, (RubyClass) klazz, (XmlNode) node);
    } catch (IllegalArgumentException e) {
      throw context.getRuntime().newRuntimeError(e.getMessage());
    }
  }


  // see https://en.wikipedia.org/wiki/QName
  private static final String NameStartCharStr =
    "[_A-Za-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]"
    ;
  private static final String NameCharStr = "[-\\.0-9\u00B7\u0300-\u036F\u203F-\u2040]|" + NameStartCharStr ;
  private static final String NCNameStr = "(?:" + NameStartCharStr + ")(?:" + NameCharStr + ")*";
  private static final String XPathFunctionCaptureStr = "(" + NCNameStr + "(?=\\())";
  private static final Pattern XPathFunctionCaptureRE = Pattern.compile(XPathFunctionCaptureStr);

  @JRubyMethod
  public IRubyObject
  evaluate(ThreadContext context, IRubyObject rbQuery, IRubyObject handler)
  {
    String query = rbQuery.convertToString().asJavaString();

    if (!handler.isNil() && !isContainsPrefix(query)) {
      //
      //  The user has passed in a handler, but isn't using the `nokogiri:` prefix as
      //  instructed in JRuby land, so let's try to be clever and rewrite the query, inserting
      //  the nokogiri namespace where appropriate.
      //
      StringBuilder namespacedQuery = new StringBuilder();
      int jchar = 0;

      // Find the methods on the handler object
      Set<String> methodNames = handler.getMetaClass().getMethods().keySet();

      // Find the function calls in the xpath query
      Matcher xpathFunctionCalls = XPathFunctionCaptureRE.matcher(query);

      while (xpathFunctionCalls.find()) {
        namespacedQuery.append(query.subSequence(jchar, xpathFunctionCalls.start()));
        jchar = xpathFunctionCalls.start();

        if (methodNames.contains(xpathFunctionCalls.group())) {
          namespacedQuery.append(NokogiriNamespaceContext.NOKOGIRI_PREFIX);
          namespacedQuery.append(":");
        }

        namespacedQuery.append(query.subSequence(xpathFunctionCalls.start(), xpathFunctionCalls.end()));
        jchar = xpathFunctionCalls.end();
      }

      if (jchar < query.length() - 1) {
        namespacedQuery.append(query.subSequence(jchar, query.length()));
      }
      query = namespacedQuery.toString();
    }

    return node_set(context, query, handler);
  }

  @JRubyMethod
  public IRubyObject
  evaluate(ThreadContext context, IRubyObject expr)
  {
    return this.evaluate(context, expr, context.getRuntime().getNil());
  }

  private final NokogiriNamespaceContext nsContext = NokogiriNamespaceContext.create();

  @JRubyMethod
  public IRubyObject
  register_ns(IRubyObject prefix, IRubyObject uri)
  {
    nsContext.registerNamespace(prefix.asJavaString(), uri.asJavaString());
    return this;
  }

  private NokogiriXPathVariableResolver variableResolver; // binds (if any)

  @JRubyMethod
  public IRubyObject
  register_variable(IRubyObject name, IRubyObject value)
  {
    NokogiriXPathVariableResolver variableResolver = this.variableResolver;
    if (variableResolver == null) {
      variableResolver = NokogiriXPathVariableResolver.create();
      this.variableResolver = variableResolver;
    }
    variableResolver.registerVariable(name.asJavaString(), value.asJavaString());
    return this;
  }

  private IRubyObject
  node_set(ThreadContext context, String expr, IRubyObject handler)
  {
    final NokogiriXPathFunctionResolver fnResolver = NokogiriXPathFunctionResolver.create(handler);
    try {
      return tryGetNodeSet(context, expr, fnResolver);
    } catch (TransformerException ex) {
      throw XmlSyntaxError.createXMLXPathSyntaxError(context.runtime,
          (expr + ": " + ex.toString()),
          ex).toThrowable();
    }
  }

  private IRubyObject
  tryGetNodeSet(ThreadContext context, String expr, NokogiriXPathFunctionResolver fnResolver) throws TransformerException
  {
    final Node contextNode = this.context.node;

    final JAXPPrefixResolver prefixResolver = new JAXPPrefixResolver(nsContext);
    XPath xpathInternal = new XPath(expr, null, prefixResolver, XPath.SELECT);

    // We always need to have a ContextNode with Xalan XPath implementation
    // To allow simple expression evaluation like 1+1 we are setting
    // dummy Document as Context Node
    final XObject xobj;
    if (contextNode == null) {
      xobj = xpathInternal.execute(getXPathContext(fnResolver), DTM.NULL, prefixResolver);
    } else {
      xobj = xpathInternal.execute(getXPathContext(fnResolver), contextNode, prefixResolver);
    }

    switch (xobj.getType()) {
      case XObject.CLASS_BOOLEAN :
        return context.runtime.newBoolean(xobj.bool());
      case XObject.CLASS_NUMBER :
        return context.runtime.newFloat(xobj.num());
      case XObject.CLASS_NODESET :
        IRubyObject[] nodes = nodeListToRubyArray(context.runtime, xobj.nodelist());
        return XmlNodeSet.newNodeSet(context.runtime, nodes, this.context);
      default :
        return context.runtime.newString(xobj.str());
    }
  }

  private XPathContext
  getXPathContext(final NokogiriXPathFunctionResolver fnResolver)
  {
    Node doc = context.getNode().getOwnerDocument();
    if (doc == null) { doc = context.getNode(); }

    XPathContext xpathContext = (XPathContext) doc.getUserData(XPATH_CONTEXT);

    if (xpathContext == null) {
      xpathContext = newXPathContext(fnResolver);
      if (variableResolver == null) {
        // NOTE: only caching without variables - could be improved by more sophisticated caching
        doc.setUserData(XPATH_CONTEXT, xpathContext, null);
      }
    } else {
      Object owner = xpathContext.getOwnerObject();
      if ((owner == null && fnResolver == null) ||
          (owner instanceof JAXPExtensionsProvider && ((JAXPExtensionsProvider) owner).hasSameResolver(fnResolver))) {
        // can be re-used assuming it has the same variable-stack (for now only cached if no variables)
        if (variableResolver == null) { return xpathContext; }
      }
      xpathContext = newXPathContext(fnResolver); // otherwise we can not use the cached xpath-context
    }

    if (variableResolver != null) {
      xpathContext.setVarStack(new JAXPVariableStack(variableResolver));
    }

    return xpathContext;
  }

  private static XPathContext
  newXPathContext(final NokogiriXPathFunctionResolver functionResolver)
  {
    if (functionResolver == null) { return new XPathContext(false); }
    return new XPathContext(new JAXPExtensionsProvider(functionResolver), false);
  }

  private boolean
  isContainsPrefix(final String str)
  {
    final StringBuilder prefix_ = new StringBuilder();
    for (String prefix : nsContext.getAllPrefixes()) {
      prefix_.setLength(0);
      prefix_.ensureCapacity(prefix.length() + 1);
      prefix_.append(prefix).append(':');
      if (str.contains(prefix_)) {   // prefix + ':'
        return true;
      }
    }
    return false;
  }

  private static final class JAXPExtensionsProvider extends org.apache.xpath.jaxp.JAXPExtensionsProvider
  {

    final NokogiriXPathFunctionResolver resolver;

    JAXPExtensionsProvider(NokogiriXPathFunctionResolver resolver)
    {
      super(resolver, false);
      this.resolver = resolver;
    }

    //@Override
    //public boolean equals(Object obj) {
    //    if (obj instanceof JAXPExtensionsProvider) {
    //        return hasSameResolver(((JAXPExtensionsProvider) obj).resolver);
    //    }
    //    return false;
    //}

    final boolean
    hasSameResolver(final NokogiriXPathFunctionResolver resolver)
    {
      return resolver == this.resolver || resolver != null && (
               resolver.getHandler() == null ? this.resolver.getHandler() == null : (
                 resolver.getHandler() == this.resolver.getHandler()
                 // resolver.getHandler().eql( this.resolver.getHandler() )
               )
             );
    }

  }

}
