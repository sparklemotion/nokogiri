package nokogiri.internals;

import java.util.ArrayList;
import java.util.List;

import org.apache.xerces.xni.parser.XMLErrorHandler;
import org.xml.sax.ErrorHandler;

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
  protected final List<Exception> errors;
  protected boolean noerror;
  protected boolean nowarning;

  public
  NokogiriErrorHandler(boolean noerror, boolean nowarning)
  {
    this.errors = new ArrayList<Exception>(4);
    this.noerror = noerror;
    this.nowarning = nowarning;
  }

  List<Exception>
  getErrors() { return errors; }

  public void
  addError(Exception ex) { errors.add(ex); }

  protected boolean
  usesNekoHtml(String domain)
  {
    return "http://cyberneko.org/html".equals(domain);
  }

}
