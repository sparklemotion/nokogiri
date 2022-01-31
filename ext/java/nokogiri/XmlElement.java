package nokogiri;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Element;
import org.w3c.dom.Node;

import nokogiri.internals.SaveContextVisitor;

/**
 * Class for Nokogiri::XML::Element
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gamil.com>
 */
@JRubyClass(name = "Nokogiri::XML::Element", parent = "Nokogiri::XML::Node")
public class XmlElement extends XmlNode
{
  private static final long serialVersionUID = 1L;

  public
  XmlElement(Ruby runtime, RubyClass klazz)
  {
    super(runtime, klazz);
  }

  public
  XmlElement(Ruby runtime, RubyClass klazz, Node element)
  {
    super(runtime, klazz, element);
  }

  @Override
  public void
  accept(ThreadContext context, SaveContextVisitor visitor)
  {
    visitor.enter((Element) node);
    acceptChildren(context, getChildren(), visitor);
    visitor.leave((Element) node);
  }
}
