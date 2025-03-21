package nokogiri;

import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

/**
 * Class for Nokogiri::XML::DocumentFragment
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */
@JRubyClass(name = "Nokogiri::XML::DocumentFragment", parent = "Nokogiri::XML::Node")
public class XmlDocumentFragment extends XmlNode
{
  private static final long serialVersionUID = 1L;

  // unused
  @Deprecated
  public
  XmlDocumentFragment(Ruby ruby)
  {
    this(ruby, getNokogiriClass(ruby, "Nokogiri::XML::DocumentFragment"));
  }

  public
  XmlDocumentFragment(Ruby ruby, RubyClass klazz)
  {
    super(ruby, klazz);
  }

  @JRubyMethod(name = "native_new", meta = true)
  public static IRubyObject
  rbNew(ThreadContext context, IRubyObject cls, IRubyObject value)
  {
    if (!(value instanceof XmlDocument)) {
      throw context.runtime.newArgumentError("first parameter must be a Nokogiri::XML::Document instance");
    }

    XmlDocument doc = (XmlDocument) value;

    XmlDocumentFragment fragment = (XmlDocumentFragment) NokogiriService.XML_DOCUMENT_FRAGMENT_ALLOCATOR.allocate(
                                     context.runtime, (RubyClass)cls);
    fragment.setDocument(context, doc);
    fragment.setNode(context.runtime, doc.getDocument().createDocumentFragment());

    return fragment;
  }

  @Override
  public void
  relink_namespace(ThreadContext context)
  {
    relink_namespace(context, getChildren());
  }
}
