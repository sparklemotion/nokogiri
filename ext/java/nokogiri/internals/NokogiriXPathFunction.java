package nokogiri.internals;

import java.util.List;

import javax.xml.xpath.XPathFunction;
import javax.xml.xpath.XPathFunctionException;
import javax.xml.namespace.QName;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyBoolean;
import org.jruby.RubyFixnum;
import org.jruby.RubyFloat;
import org.jruby.RubyInteger;
import org.jruby.RubyString;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.Helpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.NodeList;

import nokogiri.XmlNode;
import nokogiri.XmlNodeSet;

import static nokogiri.internals.NokogiriHelpers.nodeListToRubyArray;

/**
 * Xpath function handler.
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class NokogiriXPathFunction implements XPathFunction
{

  private final IRubyObject handler;
  private final QName name;
  private final int arity;

  public static NokogiriXPathFunction
  create(IRubyObject handler, QName name, int arity)
  {
    return new NokogiriXPathFunction(handler, name, arity);
  }

  private
  NokogiriXPathFunction(IRubyObject handler, QName name, int arity)
  {
    this.handler = handler;
    this.name = name;
    this.arity = arity;
  }

  public Object
  evaluate(List<?> args) throws XPathFunctionException
  {
    if (args.size() != this.arity) {
      throw new XPathFunctionException("arity does not match");
    }

    if (name.getNamespaceURI().equals(NokogiriNamespaceContext.NOKOGIRI_BUILTIN_URI)) {
      if (name.getLocalPart().equals("css-class")) {
        return builtinCssClass(args);
      }
    }

    if (this.handler.isNil()) {
      throw new XPathFunctionException("no custom function handler declared for '" + name + "'");
    }

    final Ruby runtime = this.handler.getRuntime();
    ThreadContext context = runtime.getCurrentContext();
    IRubyObject result = Helpers.invoke(context, this.handler, this.name.getLocalPart(),
                                        fromObjectToRubyArgs(runtime, args));
    return fromRubyToObject(runtime, result);
  }

  private static IRubyObject[]
  fromObjectToRubyArgs(final Ruby runtime, List<?> args)
  {
    IRubyObject[] newArgs = new IRubyObject[args.size()];
    for (int i = 0; i < args.size(); i++) {
      newArgs[i] = fromObjectToRuby(runtime, args.get(i));
    }
    return newArgs;
  }

  private static IRubyObject
  fromObjectToRuby(final Ruby runtime, Object obj)
  {
    // argument object type is one of NodeList, String, Boolean, or Double.
    if (obj instanceof NodeList) {
      IRubyObject[] nodes = nodeListToRubyArray(runtime, (NodeList) obj);
      return XmlNodeSet.newNodeSet(runtime, nodes);
    }
    return JavaUtil.convertJavaToUsableRubyObject(runtime, obj);
  }

  private static Object
  fromRubyToObject(final Ruby runtime, IRubyObject obj)
  {
    if (obj instanceof RubyString) { return obj.asJavaString(); }
    if (obj instanceof RubyBoolean) { return obj.toJava(Boolean.class); }
    if (obj instanceof RubyFloat) { return obj.toJava(Double.class); }
    if (obj instanceof RubyInteger) {
      if (obj instanceof RubyFixnum) { return RubyFixnum.fix2long(obj); }
      return obj.toJava(java.math.BigInteger.class);
    }
    if (obj instanceof XmlNodeSet) { return obj; }
    if (obj instanceof RubyArray) {
      return XmlNodeSet.newNodeSet(runtime, ((RubyArray) obj).toJavaArray());
    }
    /*if (o instanceof XmlNode)*/ return ((XmlNode) obj).getNode();
  }

  private static boolean
  builtinCssClass(List<?> args) throws XPathFunctionException
  {
    if (args.size() != 2) {
      throw new XPathFunctionException("builtin function nokogiri:css-class takes two arguments");
    }

    String hay = args.get(0).toString();
    String needle = args.get(1).toString();

    if (needle.length() == 0) {
      return true;
    }

    int j = 0;
    int j_lim = hay.length() - needle.length();
    while (j <= j_lim) {
      int k;
      for (k = 0; k < needle.length(); k++) {
        if (needle.charAt(k) != hay.charAt(j + k)) {
          break;
        }
      }
      if (k == needle.length()) {
        if ((hay.length() == (j + k)) || isWhitespace(hay.charAt(j + k))) {
          return true ;
        }
      }

      /* advance str to whitespace */
      while (j <= j_lim && !isWhitespace(hay.charAt(j))) {
        j++;
      }

      /* advance str to start of next word or end of string */
      while (j <= j_lim && isWhitespace(hay.charAt(j))) {
        j++;
      }
    }

    return false;
  }

  private static boolean
  isWhitespace(char subject)
  {
    // see libxml2's xmlIsBlank_ch()
    return ((subject == 0x09) || (subject == 0x0A) || (subject == 0x0D) || (subject == 0x20));
  }
}
