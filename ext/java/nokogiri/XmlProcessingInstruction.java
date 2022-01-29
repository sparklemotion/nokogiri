package nokogiri;

import static nokogiri.internals.NokogiriHelpers.rubyStringToString;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Helpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.ProcessingInstruction;

import nokogiri.internals.SaveContextVisitor;

/**
 * Class for Nokogiri::XML::ProcessingInstruction
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */
@JRubyClass(name = "Nokogiri::XML::ProcessingInstruction", parent = "Nokogiri::XML::Node")
public class XmlProcessingInstruction extends XmlNode
{
  private static final long serialVersionUID = 1L;

  public
  XmlProcessingInstruction(Ruby ruby, RubyClass klazz)
  {
    super(ruby, klazz);
  }

  public
  XmlProcessingInstruction(Ruby ruby, RubyClass klazz, Node node)
  {
    super(ruby, klazz, node);
  }

  @JRubyMethod(name = "new", meta = true, rest = true, required = 3)
  public static IRubyObject
  rbNew(ThreadContext context,
        IRubyObject klazz,
        IRubyObject[] args)
  {

    IRubyObject doc = args[0];
    IRubyObject target = args[1];
    IRubyObject data = args[2];

    Document document = ((XmlNode) doc).getOwnerDocument();
    Node node =
      document.createProcessingInstruction(rubyStringToString(target),
                                           rubyStringToString(data));
    XmlProcessingInstruction self =
      new XmlProcessingInstruction(context.getRuntime(),
                                   (RubyClass) klazz,
                                   node);

    Helpers.invoke(context, self, "initialize", args);

    // TODO: if_block_given.

    return self;
  }

  @Override
  public boolean
  isProcessingInstruction() { return true; }

  @Override
  public void
  accept(ThreadContext context, SaveContextVisitor visitor)
  {
    visitor.enter((ProcessingInstruction)node);
    visitor.leave((ProcessingInstruction)node);
  }
}
