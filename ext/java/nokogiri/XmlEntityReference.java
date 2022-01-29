package nokogiri;

import static nokogiri.internals.NokogiriHelpers.getCachedNodeOrCreate;
import static nokogiri.internals.NokogiriHelpers.rubyStringToString;
import nokogiri.internals.SaveContextVisitor;

import org.apache.xerces.dom.CoreDocumentImpl;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.w3c.dom.Node;

/**
 * Class for Nokogiri::XML::EntityReference
 *
 * @author sergio
 * @author Patrick Mahoney <pat@polycrystal.org>
 * @author Yoko Harada <yokolet@gmail.com>
 */
@JRubyClass(name = "Nokogiri::XML::EntityReference", parent = "Nokogiri::XML::Node")
public class XmlEntityReference extends XmlNode
{
  private static final long serialVersionUID = 1L;

  public
  XmlEntityReference(Ruby ruby, RubyClass klazz)
  {
    super(ruby, klazz);
  }

  public
  XmlEntityReference(Ruby ruby, RubyClass klass, Node node)
  {
    super(ruby, klass, node);
  }

  protected void
  init(ThreadContext context, IRubyObject[] args)
  {
    if (args.length < 2) {
      throw context.runtime.newArgumentError(args.length, 2);
    }

    IRubyObject doc = args[0];
    IRubyObject name = args[1];

    Document document = ((XmlNode) doc).getOwnerDocument();
    // FIXME: disable error checking as a workaround for #719. this depends on the internals of Xerces.
    CoreDocumentImpl internalDocument = (CoreDocumentImpl) document;
    boolean oldErrorChecking = internalDocument.getErrorChecking();
    internalDocument.setErrorChecking(false);
    Node node = document.createEntityReference(rubyStringToString(name));
    internalDocument.setErrorChecking(oldErrorChecking);
    setNode(context.runtime, node);
  }

  @Override
  public void
  accept(ThreadContext context, SaveContextVisitor visitor)
  {
    visitor.enter(node);
    Node child = node.getFirstChild();
    while (child != null) {
      IRubyObject nokoNode = getCachedNodeOrCreate(context.getRuntime(), child);
      if (nokoNode instanceof XmlNode) {
        XmlNode cur = (XmlNode) nokoNode;
        cur.accept(context, visitor);
      } else if (nokoNode instanceof XmlNamespace) {
        XmlNamespace cur = (XmlNamespace) nokoNode;
        cur.accept(context, visitor);
      }
      child = child.getNextSibling();
    }
    visitor.leave(node);
  }
}
