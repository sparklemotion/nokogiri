package nokogiri;

import static nokogiri.internals.NokogiriHelpers.stringOrNil;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyException;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.xml.sax.SAXParseException;

/**
 * Class for Nokogiri::XML::SyntaxError
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */
@JRubyClass(name = "Nokogiri::XML::SyntaxError", parent = "Nokogiri::SyntaxError")
public class XmlSyntaxError extends RubyException
{
  private static final long serialVersionUID = 1L;

  private Exception exception;
  private boolean messageSet; // whether a custom error message was set

  public
  XmlSyntaxError(Ruby runtime, RubyClass klazz)
  {
    super(runtime, klazz);
  }

  public
  XmlSyntaxError(Ruby runtime, RubyClass rubyClass, Exception ex)
  {
    super(runtime, rubyClass, ex.getMessage());
    this.exception = ex;
  }

  public
  XmlSyntaxError(Ruby runtime, RubyClass rubyClass, String message, Exception ex)
  {
    super(runtime, rubyClass, message);
    this.exception = ex;
    this.messageSet = true;
  }

  public static XmlSyntaxError
  createXMLSyntaxError(final Ruby runtime)
  {
    RubyClass klazz = (RubyClass) runtime.getClassFromPath("Nokogiri::XML::SyntaxError");
    return new XmlSyntaxError(runtime, klazz);
  }

  public static XmlSyntaxError
  createXMLSyntaxError(final Ruby runtime, final Exception ex)
  {
    RubyClass klazz = (RubyClass) runtime.getClassFromPath("Nokogiri::XML::SyntaxError");
    return new XmlSyntaxError(runtime, klazz, ex);
  }

  public static XmlSyntaxError
  createHTMLSyntaxError(final Ruby runtime)
  {
    RubyClass klazz = (RubyClass) runtime.getClassFromPath("Nokogiri::HTML4::SyntaxError");
    return new XmlSyntaxError(runtime, klazz);
  }

  public static RubyException
  createXMLXPathSyntaxError(final Ruby runtime, final String msg, final Exception ex)
  {
    RubyClass klazz = (RubyClass) runtime.getClassFromPath("Nokogiri::XML::XPath::SyntaxError");
    return new XmlSyntaxError(runtime, klazz, msg, ex);
  }

  public static XmlSyntaxError
  createWarning(Ruby runtime, SAXParseException e)
  {
    XmlSyntaxError xmlSyntaxError = createXMLSyntaxError(runtime);
    xmlSyntaxError.setException(runtime, e, 1);
    return xmlSyntaxError;
  }

  public static XmlSyntaxError
  createError(Ruby runtime, SAXParseException e)
  {
    XmlSyntaxError xmlSyntaxError = createXMLSyntaxError(runtime);
    xmlSyntaxError.setException(runtime, e, 2);
    return xmlSyntaxError;
  }

  public static XmlSyntaxError
  createFatalError(Ruby runtime, SAXParseException e)
  {
    XmlSyntaxError xmlSyntaxError = createXMLSyntaxError(runtime);
    xmlSyntaxError.setException(runtime, e, 3);
    return xmlSyntaxError;
  }

  public void
  setException(Exception exception)
  {
    this.exception = exception;
  }

  public void
  setException(Ruby runtime, SAXParseException exception, int level)
  {
    this.exception = exception;
    setInstanceVariable("@level", runtime.newFixnum(level));
    setInstanceVariable("@line", runtime.newFixnum(exception.getLineNumber()));
    setInstanceVariable("@column", runtime.newFixnum(exception.getColumnNumber()));
    setInstanceVariable("@file", stringOrNil(runtime, exception.getSystemId()));
  }

  @JRubyMethod(name = "to_s")
  @Override
  public IRubyObject
  to_s(ThreadContext context)
  {
    RubyString msg = msg(context.runtime);
    return msg != null ? msg : super.to_s(context).asString();
  }

  private RubyString
  msg(final Ruby runtime)
  {
    if (exception != null && exception.getMessage() != null) {
      if (messageSet) { return null; }
      return runtime.newString(exception.getMessage());
    }
    return null;
  }

}
