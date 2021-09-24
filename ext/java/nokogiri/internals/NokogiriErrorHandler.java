package nokogiri.internals;

import nokogiri.XmlSyntaxError;
import org.apache.xerces.xni.parser.XMLErrorHandler;
import org.jruby.Ruby;
import org.jruby.RubyException;
import org.jruby.exceptions.RaiseException;
import org.xml.sax.ErrorHandler;

import java.util.ArrayList;
import java.util.List;

/**
 * Super class of error handlers.
 *
 * XMLErrorHandler is used by nokogiri.internals.HtmlDomParserContext since NekoHtml
 * uses this type of the error handler.
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */
public abstract class NokogiriErrorHandler implements ErrorHandler, XMLErrorHandler
{
  private final Ruby runtime;
  protected final List<RubyException> errors;
  protected boolean noerror;
  protected boolean nowarning;

  public
  NokogiriErrorHandler(Ruby runtime, boolean noerror, boolean nowarning)
  {
    this.runtime = runtime;
    this.errors = new ArrayList<RubyException>(4);
    this.noerror = noerror;
    this.nowarning = nowarning;
  }

  public List<RubyException>
  getErrors() { return errors; }

  public void
  addError(Exception ex)
  {
    addError(XmlSyntaxError.createXMLSyntaxError(runtime, ex));
  }

  public void
  addError(RubyException ex)
  {
    errors.add(ex);
  }

  public void
  addError(RaiseException ex)
  {
    addError(ex.getException());
  }

  protected boolean
  usesNekoHtml(String domain)
  {
    return "http://cyberneko.org/html".equals(domain);
  }

}
