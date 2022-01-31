package nokogiri;

import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Element;
import org.w3c.dom.Node;

/**
 * DTD attribute declaration.
 *
 * @author Patrick Mahoney <pat@polycrystal.org>
 */
@JRubyClass(name = "Nokogiri::XML::AttributeDecl", parent = "Nokogiri::XML::Node")
public class XmlAttributeDecl extends XmlNode
{
  private static final long serialVersionUID = 1L;

  public
  XmlAttributeDecl(Ruby ruby, RubyClass klass)
  {
    super(ruby, klass);
    throw ruby.newRuntimeError("node required");
  }

  /**
   * Initialize based on an attributeDecl node from a NekoDTD parsed
   * DTD.
   *
   * Internally, XmlAttributeDecl combines these into a single node.
   */
  public
  XmlAttributeDecl(Ruby ruby, RubyClass klass, Node attrDeclNode)
  {
    super(ruby, klass, attrDeclNode);
  }

  static XmlAttributeDecl
  create(ThreadContext context, Node attrDeclNode)
  {
    return new XmlAttributeDecl(context.runtime,
                                getNokogiriClass(context.runtime, "Nokogiri::XML::AttributeDecl"),
                                attrDeclNode
                               );
  }

  @Override
  @JRubyMethod
  public IRubyObject
  node_name(ThreadContext context)
  {
    return attribute_name(context);
  }

  @Override
  @JRubyMethod(name = "node_name=")
  public IRubyObject
  node_name_set(ThreadContext context, IRubyObject name)
  {
    throw context.runtime.newRuntimeError("cannot change name of DTD decl");
  }

  public IRubyObject
  element_name(ThreadContext context)
  {
    return getAttribute(context, "ename");
  }

  public IRubyObject
  attribute_name(ThreadContext context)
  {
    return getAttribute(context, "aname");
  }

  @JRubyMethod
  public IRubyObject
  attribute_type(ThreadContext context)
  {
    return getAttribute(context, "atype");
  }

  @JRubyMethod(name = "default")
  public IRubyObject
  default_value(ThreadContext context)
  {
    return getAttribute(context, "default");
  }

  /**
   * FIXME: will enumerations all be of the simple (val1|val2|val3)
   * type string?
   */
  @JRubyMethod
  public IRubyObject
  enumeration(ThreadContext context)
  {
    final String atype = ((Element) node).getAttribute("atype");

    if (atype != null && atype.length() != 0 && atype.charAt(0) == '(') {
      // removed enclosing parens
      String valueStr = atype.substring(1, atype.length() - 1);
      String[] values = valueStr.split("\\|");
      RubyArray<?> enumVals = RubyArray.newArray(context.runtime, values.length);
      for (int i = 0; i < values.length; i++) {
        enumVals.append(context.runtime.newString(values[i]));
      }
      return enumVals;
    }

    return context.runtime.newEmptyArray();
  }

}
