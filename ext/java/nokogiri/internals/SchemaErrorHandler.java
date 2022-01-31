package nokogiri.internals;

import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;
import nokogiri.NokogiriService;
import nokogiri.XmlSyntaxError;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.xml.sax.ErrorHandler;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;

/**
 * Error handler for Relax and W3C XML Schema.
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class SchemaErrorHandler implements ErrorHandler
{

  private final Ruby runtime;
  final RubyArray<?> errors;

  public
  SchemaErrorHandler(Ruby ruby, RubyArray<?> array)
  {
    this.runtime = ruby;
    this.errors = array;
  }

  public void
  warning(SAXParseException ex) throws SAXException
  {
    errors.append(XmlSyntaxError.createWarning(runtime, ex));
  }

  public void
  error(SAXParseException ex) throws SAXException
  {
    errors.append(XmlSyntaxError.createError(runtime, ex));
  }

  public void
  fatalError(SAXParseException ex) throws SAXException
  {
    throw ex;
  }

}
