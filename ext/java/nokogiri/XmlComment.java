package nokogiri;

import static nokogiri.internals.NokogiriHelpers.rubyStringToString;
import nokogiri.internals.SaveContextVisitor;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Comment;
import org.w3c.dom.Document;
import org.w3c.dom.Node;

/**
 * Class for Nokogiri::XML::Comment
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */
@JRubyClass(name = "Nokogiri::XML::Comment", parent = "Nokogiri::XML::CharacterData")
public class XmlComment extends XmlNode
{
  private static final long serialVersionUID = 1L;

  public
  XmlComment(Ruby ruby, RubyClass rubyClass, Node node)
  {
    super(ruby, rubyClass, node);
  }

  public
  XmlComment(Ruby runtime, RubyClass klass)
  {
    super(runtime, klass);
  }

  @Override
  protected void
  init(ThreadContext context, IRubyObject[] args)
  {
    if (args.length < 2) {
      throw getRuntime().newArgumentError(args.length, 2);
    }

    IRubyObject doc = args[0];
    IRubyObject text = args[1];

    XmlDocument xmlDoc;
    if (doc instanceof XmlDocument) {
      xmlDoc = (XmlDocument) doc;

    } else if (doc instanceof XmlNode) {
      XmlNode xmlNode = (XmlNode) doc;
      xmlDoc = (XmlDocument)xmlNode.document(context);
    } else {
      throw getRuntime().newArgumentError("first argument must be a XML::Document or XML::Node");
    }
    if (xmlDoc != null) {
      Document document = xmlDoc.getDocument();
      Node node = document.createComment(rubyStringToString(text));
      setNode(context.runtime, node);
    }
  }

  @Override
  public boolean
  isComment() { return true; }

  @Override
  public void
  accept(ThreadContext context, SaveContextVisitor visitor)
  {
    visitor.enter((Comment)node);
    visitor.leave((Comment)node);
  }
}
