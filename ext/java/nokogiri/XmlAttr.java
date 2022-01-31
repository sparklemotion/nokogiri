package nokogiri;

import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;
import static nokogiri.internals.NokogiriHelpers.rubyStringToString;
import nokogiri.internals.NokogiriHelpers;
import nokogiri.internals.SaveContextVisitor;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Attr;
import org.w3c.dom.Element;
import org.w3c.dom.Node;

/**
 * Class for Nokogiri::XML::Attr
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */
@JRubyClass(name = "Nokogiri::XML::Attr", parent = "Nokogiri::XML::Node")
public class XmlAttr extends XmlNode
{
  private static final long serialVersionUID = 1L;

  public static final String[] HTML_BOOLEAN_ATTRS = {
    "checked", "compact", "declare", "defer", "disabled", "ismap",
    "multiple", "nohref", "noresize", "noshade", "nowrap", "readonly",
    "selected"
  };

  public
  XmlAttr(Ruby ruby, Node attr)
  {
    super(ruby, getNokogiriClass(ruby, "Nokogiri::XML::Attr"), attr);
  }

  public
  XmlAttr(Ruby ruby, RubyClass rubyClass)
  {
    super(ruby, rubyClass);
  }

  public
  XmlAttr(Ruby ruby, RubyClass rubyClass, Node attr)
  {
    super(ruby, rubyClass, attr);
  }

  @Override
  protected void
  init(ThreadContext context, IRubyObject[] args)
  {
    if (args.length < 2) {
      throw context.runtime.newArgumentError(args.length, 2);
    }

    IRubyObject doc = args[0];
    IRubyObject content = args[1];

    if (!(doc instanceof XmlDocument)) {
      throw context.runtime.newArgumentError("document must be an instance of Nokogiri::XML::Document");
    }

    XmlDocument xmlDoc = (XmlDocument)doc;
    String str = rubyStringToString(content);
    Node attr = xmlDoc.getDocument().createAttribute(str);
    setNode(context.runtime, attr);
  }


  // this method is called from XmlNode.setNode()
  // if the node is attribute, and its name has prefix "xml"
  // the default namespace should be registered for this attribute
  void
  setNamespaceIfNecessary(Ruby runtime)
  {
    if ("xml".equals(node.getPrefix())) {
      XmlNamespace.createDefaultNamespace(runtime, node);
    }
  }

  @Override
  @JRubyMethod(name = {"content", "value", "to_s"})
  public IRubyObject
  content(ThreadContext context)
  {
    if (content != null && !content.isNil()) { return content; }
    if (node == null) { return context.getRuntime().getNil(); }
    String attrValue = ((Attr)node).getValue();
    if (attrValue == null) { return context.getRuntime().getNil(); }
    return RubyString.newString(context.getRuntime(), attrValue);
  }

  @JRubyMethod(name = {"value=", "content="})
  public IRubyObject
  value_set(ThreadContext context, IRubyObject content)
  {
    Attr attr = (Attr) node;
    if (content != null && !content.isNil()) {
      attr.setValue(rubyStringToString(XmlNode.encode_special_chars(context, content)));
    }
    setContent(content);
    return content;
  }

  @Override
  protected IRubyObject
  getNodeName(ThreadContext context)
  {
    if (name != null) { return name; }

    String attrName = ((Attr) node).getName();
    if (attrName == null) { return context.nil; }

    if (node.getNamespaceURI() != null && !(document(context.runtime) instanceof Html4Document)) {
      attrName = NokogiriHelpers.getLocalPart(attrName);
      if (attrName == null) { return context.nil; }
    }

    return name = RubyString.newString(context.runtime, attrName);
  }

  @Override
  public void
  accept(ThreadContext context, SaveContextVisitor visitor)
  {
    visitor.enter((Attr)node);
    visitor.leave((Attr)node);
  }

  private boolean
  isHtml(ThreadContext context)
  {
    return document(context).getMetaClass().isKindOfModule(getNokogiriClass(context.getRuntime(),
           "Nokogiri::HTML4::Document"));
  }

  @Override
  public IRubyObject
  unlink(ThreadContext context)
  {
    Attr attr = (Attr) node;
    Element parent = attr.getOwnerElement();
    parent.removeAttributeNode(attr);

    return this;
  }

}
