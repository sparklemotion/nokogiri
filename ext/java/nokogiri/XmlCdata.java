package nokogiri;

import static nokogiri.internals.NokogiriHelpers.rubyStringToString;

import nokogiri.internals.SaveContextVisitor;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.CDATASection;
import org.w3c.dom.Document;
import org.w3c.dom.Node;

/**
 * Class for Nokogiri::XML::CDATA
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */

@JRubyClass(name = "Nokogiri::XML::CDATA", parent = "Nokogiri::XML::Text")
public class XmlCdata extends XmlText
{
  public
  XmlCdata(Ruby ruby, RubyClass rubyClass)
  {
    super(ruby, rubyClass);
  }

  public
  XmlCdata(Ruby ruby, RubyClass rubyClass, Node node)
  {
    super(ruby, rubyClass, node);
  }

  @Override
  protected void
  init(ThreadContext context, IRubyObject[] args)
  {
    if (args.length < 2) {
      throw getRuntime().newArgumentError(args.length, 2);
    }
    IRubyObject doc = args[0];
    content = args[1];
    Document document = ((XmlNode) doc).getOwnerDocument();
    Node node = document.createCDATASection(rubyStringToString(content));
    setNode(context.runtime, node);
  }

  @Override
  public void
  accept(ThreadContext context, SaveContextVisitor visitor)
  {
    visitor.enter((CDATASection)node);
    visitor.leave((CDATASection)node);
  }
}
