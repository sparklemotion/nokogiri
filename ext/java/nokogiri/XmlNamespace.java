package nokogiri;

import static nokogiri.internals.NokogiriHelpers.getCachedNodeOrCreate;
import static nokogiri.internals.NokogiriHelpers.getLocalNameForNamespace;
import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;
import nokogiri.internals.SaveContextVisitor;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Attr;
import org.w3c.dom.Document;
import org.w3c.dom.Node;

/**
 * Class for Nokogiri::XML::Namespace
 *
 * @author serabe
 * @author Yoko Harada <yokolet@gmail.com>
 */
@JRubyClass(name = "Nokogiri::XML::Namespace")
public class XmlNamespace extends RubyObject
{
  private static final long serialVersionUID = 1L;

  private Attr attr;
  private transient IRubyObject prefixRuby;
  private transient IRubyObject hrefRuby;
  private String prefix;
  private String href;

  public
  XmlNamespace(Ruby runtime, RubyClass klazz)
  {
    super(runtime, klazz);
  }

  XmlNamespace(Ruby runtime, Attr attr, String prefix, String href, IRubyObject document)
  {
    this(runtime, attr, prefix, null, href, null, document);
  }

  private
  XmlNamespace(Ruby runtime, Attr attr, String prefix, IRubyObject prefixRuby,
               String href, IRubyObject hrefRuby, IRubyObject document)
  {
    super(runtime, getNokogiriClass(runtime, "Nokogiri::XML::Namespace"));

    this.attr = attr;
    this.prefix = prefix;
    this.href = href;
    this.prefixRuby = prefixRuby;
    this.hrefRuby = hrefRuby;
    setInstanceVariable("@document", document);
  }

  public Node
  getNode()
  {
    return attr;
  }

  public String
  getPrefix()
  {
    return prefix;
  }

  boolean
  hasPrefix(String prefix)
  {
    return prefix == null ? this.prefix == null : prefix.equals(this.prefix);
  }

  public String
  getHref()
  {
    return href;
  }

  public static XmlNamespace
  createFromAttr(Ruby runtime, Attr attr)
  {
    String prefixStr = getLocalNameForNamespace(attr.getName(), null);
    IRubyObject prefix = prefixStr == null ? runtime.getNil() : null;
    String hrefStr = attr.getValue();
    // check namespace cache
    XmlDocument xmlDocument = (XmlDocument) getCachedNodeOrCreate(runtime, attr.getOwnerDocument());
    XmlNamespace namespace = xmlDocument.getNamespaceCache().get(prefixStr, hrefStr);
    if (namespace != null) { return namespace; }

    namespace = new XmlNamespace(runtime, attr, prefixStr, prefix, hrefStr, null, xmlDocument);
    xmlDocument.getNamespaceCache().put(namespace, attr.getOwnerElement());
    return namespace;
  }

  static XmlNamespace
  createImpl(Node owner, IRubyObject prefix, String prefixStr, IRubyObject href, String hrefStr)
  {
    final Ruby runtime = prefix.getRuntime();

    Document document = owner.getOwnerDocument();
    XmlDocument xmlDocument = (XmlDocument) getCachedNodeOrCreate(runtime, document);

    assert xmlDocument.getNamespaceCache().get(prefixStr, hrefStr) == null;

    // creating XmlNamespace instance
    String attrName = "xmlns";
    if (prefixStr != null && !prefixStr.isEmpty()) { attrName = attrName + ':' + prefixStr; }

    Attr attrNode = document.createAttribute(attrName);
    attrNode.setNodeValue(hrefStr);

    XmlNamespace namespace = new XmlNamespace(runtime, attrNode, prefixStr, prefix, hrefStr, href, xmlDocument);
    xmlDocument.getNamespaceCache().put(namespace, owner);
    return namespace;
  }

  // owner should be an Attr node
  public static XmlNamespace
  createDefaultNamespace(Ruby runtime, Node owner)
  {
    String prefixStr = owner.getPrefix();
    String hrefStr = owner.getNamespaceURI();
    // check namespace cache
    XmlDocument xmlDocument = (XmlDocument) getCachedNodeOrCreate(runtime, owner.getOwnerDocument());
    XmlNamespace namespace = xmlDocument.getNamespaceCache().get(prefixStr, hrefStr);
    if (namespace != null) { return namespace; }

    namespace = new XmlNamespace(runtime, (Attr) owner, prefixStr, hrefStr, xmlDocument);
    xmlDocument.getNamespaceCache().put(namespace, owner);
    return namespace;
  }

  /**
   * Create and return a copy of this object.
   *
   * @return a clone of this object
   */
  @Override
  public Object
  clone() throws CloneNotSupportedException
  {
    return super.clone();
  }

  public boolean
  isEmpty()
  {
    return prefix == null && href == null;
  }

  @JRubyMethod
  public IRubyObject
  href(ThreadContext context)
  {
    if (hrefRuby == null) {
      if (href == null) { return hrefRuby = context.nil; }
      return hrefRuby = context.runtime.newString(href);
    }
    return hrefRuby;
  }

  @JRubyMethod
  public IRubyObject
  prefix(ThreadContext context)
  {
    if (prefixRuby == null) {
      if (prefix == null) { return prefixRuby = context.nil; }
      return prefixRuby = context.runtime.newString(prefix);
    }
    return prefixRuby;
  }

  public void
  accept(ThreadContext context, SaveContextVisitor visitor)
  {
    String prefix = this.prefix;
    if (prefix == null) { prefix = ""; }
    String href = this.href;
    if (href == null) { href = ""; }
    String string = ' ' + prefix + '=' + '"' + href + '"';
    visitor.enter(string);
    visitor.leave(string);
    // is below better?
    //visitor.enter(attr);
    //visitor.leave(attr);
  }
}
