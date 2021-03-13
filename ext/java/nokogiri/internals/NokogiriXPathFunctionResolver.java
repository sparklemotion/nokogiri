package nokogiri.internals;

import javax.xml.namespace.QName;
import javax.xml.xpath.XPathFunction;
import javax.xml.xpath.XPathFunctionResolver;

import org.jruby.runtime.builtin.IRubyObject;

/**
 * Xpath function resolver class, which is used in XmlXpathContext.
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */
public final class NokogiriXPathFunctionResolver implements XPathFunctionResolver
{

  private IRubyObject handler;

  public static NokogiriXPathFunctionResolver
  create(IRubyObject handler)
  {
    NokogiriXPathFunctionResolver freshResolver = new NokogiriXPathFunctionResolver();
    if (!handler.isNil()) {
      freshResolver.setHandler(handler);
    }
    return freshResolver;
  }

  private
  NokogiriXPathFunctionResolver() {}

  public final IRubyObject
  getHandler()
  {
    return handler;
  }

  public void
  setHandler(IRubyObject handler)
  {
    this.handler = handler;
  }

  public XPathFunction
  resolveFunction(QName name, int arity)
  {
    return NokogiriXPathFunction.create(handler, name, arity);
  }
}
