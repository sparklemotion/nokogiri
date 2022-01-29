package nokogiri;

import static nokogiri.internals.NokogiriHelpers.getLocalPart;
import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;
import static nokogiri.internals.NokogiriHelpers.getPrefix;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Node;

/**
 * DTD element declaration.
 *
 * @author Patrick Mahoney <pat@polycrystal.org>
 * @author Yoko Harada <yokolet@gmail.com>
 */
@JRubyClass(name = "Nokogiri::XML::ElementDecl", parent = "Nokogiri::XML::Node")
public class XmlElementDecl extends XmlNode
{
  private static final long serialVersionUID = 1L;

  RubyArray<?> attrDecls;
  IRubyObject contentModel;

  public
  XmlElementDecl(Ruby runtime, RubyClass klazz)
  {
    super(runtime, klazz);
    attrDecls = RubyArray.newArray(runtime);
    contentModel = runtime.getNil();
  }

  /**
   * Initialize based on an elementDecl node from a NekoDTD parsed DTD.
   */
  public
  XmlElementDecl(Ruby ruby, RubyClass klass, Node elemDeclNode)
  {
    super(ruby, klass, elemDeclNode);
  }

  @Override // gets called from constructor ^^^
  public void
  setNode(Ruby runtime, Node node)
  {
    super.setNode(runtime, node);
    attrDecls = RubyArray.newArray(runtime);
    contentModel = runtime.getNil();
  }

  static XmlElementDecl
  create(ThreadContext context, Node elemDeclNode)
  {
    return new XmlElementDecl(context.runtime,
                              getNokogiriClass(context.runtime, "Nokogiri::XML::ElementDecl"),
                              elemDeclNode
                             );
  }

  public IRubyObject
  element_name(ThreadContext context)
  {
    return getAttribute(context, "ename");
  }

  public void
  setContentModel(IRubyObject cm)
  {
    contentModel = cm;
  }

  @Override
  @JRubyMethod
  public IRubyObject
  content(ThreadContext context)
  {
    return contentModel;
  }

  public boolean
  isEmpty()
  {
    return "EMPTY".equals(getAttribute("model"));
  }

  @JRubyMethod
  public IRubyObject
  prefix(ThreadContext context)
  {
    String enamePrefix = getPrefix(getAttribute("ename"));
    if (enamePrefix == null) { return context.nil; }
    return context.runtime.newString(enamePrefix);
  }

  /**
   * Returns the local part of the element name.
   */
  @Override
  @JRubyMethod
  public IRubyObject
  node_name(ThreadContext context)
  {
    String ename = getLocalPart(getAttribute("ename"));
    return context.runtime.newString(ename);
  }

  @Override
  @JRubyMethod(name = "node_name=")
  public IRubyObject
  node_name_set(ThreadContext context, IRubyObject name)
  {
    throw context.runtime.newRuntimeError("cannot change name of DTD decl");
  }

  @Override
  @JRubyMethod
  public IRubyObject
  attribute_nodes(ThreadContext context)
  {
    return attrDecls;
  }

  @Override
  @JRubyMethod
  public IRubyObject
  attribute(ThreadContext context, IRubyObject name)
  {
    throw context.runtime.newRuntimeError("attribute by name not implemented");
  }

  public void
  appendAttrDecl(XmlAttributeDecl decl)
  {
    attrDecls.append(decl);
  }

  @JRubyMethod
  public IRubyObject
  element_type(ThreadContext context)
  {
    return context.runtime.newFixnum(node.getNodeType());
  }
}
