package nokogiri.internals;

import org.apache.xerces.xni.parser.XMLParseException;
import org.jruby.Ruby;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;

/**
 * Non-strict error handler for NekoHtml.
 *
 * NekoHtml adds too many warnings, which makes later processing hard. For example,
 * Nokogiri wants to know whether number of errors have been increased or not to judge
 * availability of creating NodeSet from a given fragment. When the fragment nodes
 * are to be created from HTML document, which means NekoHtml is used, always errors
 * increases. As a result, even though the given fragment is correct HTML, NodeSet
 * base on the given fragment won't be created. This is why all warnings are eliminated.
 *
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class NokogiriNonStrictErrorHandler4NekoHtml extends NokogiriErrorHandler
{

  public
  NokogiriNonStrictErrorHandler4NekoHtml(Ruby runtime, boolean nowarning)
  {
    super(runtime, false, nowarning);
  }

  public
  NokogiriNonStrictErrorHandler4NekoHtml(Ruby runtime, boolean noerror, boolean nowarning)
  {
    super(runtime, noerror, nowarning);
  }

  public void
  warning(SAXParseException ex) throws SAXException
  {
    //noop. NekoHtml adds too many warnings.
  }

  public void
  error(SAXParseException ex) throws SAXException
  {
    addError(ex);
  }

  public void
  fatalError(SAXParseException ex) throws SAXException
  {
    addError(ex);
  }

  /**
   * Implementation of org.apache.xerces.xni.parser.XMLErrorHandler. This method
   * is invoked during parsing fired by HtmlDomParserContext and is a NekoHtml requirement.
   *
   * @param domain The domain of the error. The domain can be any string but is
   *               suggested to be a valid URI. The domain can be used to conveniently
   *               specify a web site location of the relevant specification or
   *               document pertaining to this warning.
   * @param key The error key. This key can be any string and is implementation
   *            dependent.
   * @param e Exception.
   */
  public void
  error(String domain, String key, XMLParseException e)
  {
    addError(e);
  }

  /**
   * Implementation of org.apache.xerces.xni.parser.XMLErrorHandler. This method
   * is invoked during parsing fired by HtmlDomParserContext and is a NekoHtml requirement.
   *
   * @param domain The domain of the fatal error. The domain can be any string but is
   *               suggested to be a valid URI. The domain can be used to conveniently
   *               specify a web site location of the relevant specification or
   *               document pertaining to this warning.
   * @param key The fatal error key. This key can be any string and is implementation
   *            dependent.
   * @param e Exception.
   */
  public void
  fatalError(String domain, String key, XMLParseException e)
  {
    addError(e);
  }

  /**
   * Implementation of org.apache.xerces.xni.parser.XMLErrorHandler. This method
   * is invoked during parsing fired by HtmlDomParserContext and is a NekoHtml requirement.
   *
   * @param domain The domain of the warning. The domain can be any string but is
   *               suggested to be a valid URI. The domain can be used to conveniently
   *               specify a web site location of the relevant specification or
   *               document pertaining to this warning.
   * @param key The warning key. This key can be any string and is implementation
   *            dependent.
   * @param e Exception.
   */
  public void
  warning(String domain, String key, XMLParseException e)
  {
    addError(e);
  }

}
