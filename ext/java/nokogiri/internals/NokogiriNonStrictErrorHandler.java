package nokogiri.internals;

import org.apache.xerces.xni.parser.XMLParseException;
import org.jruby.Ruby;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;

/**
 * Error Handler for XML document when recover is true (default).
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class NokogiriNonStrictErrorHandler extends NokogiriErrorHandler
{
  public
  NokogiriNonStrictErrorHandler(Ruby runtime, boolean noerror, boolean nowarning)
  {
    super(runtime, noerror, nowarning);
  }

  public void
  warning(SAXParseException ex) throws SAXException
  {
    addError(ex);
  }

  public void
  error(SAXParseException ex) throws SAXException
  {
    addError(ex);
  }

  public void
  fatalError(SAXParseException ex) throws SAXException
  {
    // fix #837
    // Xerces won't skip the reference entity (and other invalid) constructs
    // found in the prolog, instead it will keep calling this method and we'll
    // keep inserting the error in the document errors array until we run
    // out of memory
    addError(ex);
    String message = ex.getMessage();

    // The problem with Xerces is that some errors will cause the
    // parser not to advance the reader and it will keep reporting
    // the same error over and over, which will cause the parser
    // to enter an infinite loop unless we throw the exception.
    if (message != null && isFatal(message)) {
      throw ex;
    }
  }

  public void
  error(String domain, String key, XMLParseException e)
  {
    addError(e);
  }

  public void
  fatalError(String domain, String key, XMLParseException e)
  {
    addError(e);
  }

  public void
  warning(String domain, String key, XMLParseException e)
  {
    addError(e);
  }

  /*
   * Determine whether this is a fatal error that should cause
   * the parsing to stop, or an error that can be ignored.
   */
  private static boolean
  isFatal(String msg)
  {
    String msgLowerCase = msg.toLowerCase();
    return
      msgLowerCase.contains("in prolog") ||
      msgLowerCase.contains("limit") ||
      msgLowerCase.contains("preceding the root element must be well-formed") ||
      msgLowerCase.contains("following the root element must be well-formed");
  }
}
