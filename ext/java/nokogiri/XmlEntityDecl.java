package nokogiri;

import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Node;

/**
 * DTD entity declaration.
 *
 * @author Patrick Mahoney <pat@polycrystal.org>
 * @author Yoko Harada <yokolet@gmail.com>
 */
@JRubyClass(name = "Nokogiri::XML::EntityDecl", parent = "Nokogiri::XML::Node")
public class XmlEntityDecl extends XmlNode
{
  private static final long serialVersionUID = 1L;

  public static final int INTERNAL_GENERAL = 1;
  public static final int EXTERNAL_GENERAL_PARSED = 2;
  public static final int EXTERNAL_GENERAL_UNPARSED  = 3;
  public static final int INTERNAL_PARAMETER = 4;
  public static final int EXTERNAL_PARAMETER = 5;
  public static final int INTERNAL_PREDEFINED = 6;

  private IRubyObject entityType;
  private IRubyObject name;
  private IRubyObject external_id;
  private IRubyObject system_id;
  private IRubyObject content;

  XmlEntityDecl(Ruby runtime, RubyClass klass)
  {
    super(runtime, klass);
  }

  /**
   * Initialize based on an entityDecl node from a NekoDTD parsed DTD.
   */
  public
  XmlEntityDecl(Ruby runtime, RubyClass klass, Node entDeclNode)
  {
    super(runtime, klass, entDeclNode);
    entityType = RubyFixnum.newFixnum(runtime, XmlEntityDecl.INTERNAL_GENERAL);
    name = external_id = system_id = content = runtime.getNil();
  }

  public
  XmlEntityDecl(Ruby runtime, RubyClass klass, Node entDeclNode, IRubyObject[] argv)
  {
    super(runtime, klass, entDeclNode);
    name = argv[0];
    entityType = RubyFixnum.newFixnum(runtime, XmlEntityDecl.INTERNAL_GENERAL);
    external_id = system_id = content = runtime.getNil();

    if (argv.length > 1) { entityType = argv[1]; }
    if (argv.length > 4) {
      external_id = argv[2];
      system_id = argv[3];
      content = argv[4];
    }
  }

  static XmlEntityDecl
  create(ThreadContext context, Node entDeclNode)
  {
    return new XmlEntityDecl(context.runtime,
                             getNokogiriClass(context.runtime, "Nokogiri::XML::EntityDecl"),
                             entDeclNode
                            );
  }

  // when entity is created by create_entity method
  static XmlEntityDecl
  create(ThreadContext context, Node entDeclNode, IRubyObject... argv)
  {
    return new XmlEntityDecl(context.runtime,
                             getNokogiriClass(context.runtime, "Nokogiri::XML::EntityDecl"),
                             entDeclNode, argv
                            );
  }

  /**
   * Returns the local part of the element name.
   */
  @Override
  @JRubyMethod
  public IRubyObject
  node_name(ThreadContext context)
  {
    IRubyObject value = getAttribute(context, "name");
    if (value.isNil()) { value = name; }
    return value;
  }

  @Override
  @JRubyMethod(name = "node_name=")
  public IRubyObject
  node_name_set(ThreadContext context, IRubyObject name)
  {
    throw context.runtime.newRuntimeError("cannot change name of DTD decl");
  }

  @JRubyMethod
  public IRubyObject
  content(ThreadContext context)
  {
    IRubyObject value = getAttribute(context, "value");
    if (value.isNil()) { value = content; }
    return value;
  }

  // TODO: what is content vs. original_content?
  @JRubyMethod
  public IRubyObject
  original_content(ThreadContext context)
  {
    return getAttribute(context, "value");
  }

  @JRubyMethod
  public IRubyObject
  system_id(ThreadContext context)
  {
    IRubyObject value = getAttribute(context, "sysid");
    if (value.isNil()) { value = system_id; }
    return value;
  }

  @JRubyMethod
  public IRubyObject
  external_id(ThreadContext context)
  {
    IRubyObject value = getAttribute(context, "pubid");
    if (value.isNil()) { value = external_id; }
    return value;
  }

  @JRubyMethod
  public IRubyObject
  entity_type(ThreadContext context)
  {
    return entityType;
  }
}
