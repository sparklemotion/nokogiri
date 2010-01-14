package nokogiri.internals;

import nokogiri.XmlSyntaxError;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.xml.sax.ErrorHandler;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;

/**
 *
 * @author sergio
 */
public class SchemaErrorHandler implements ErrorHandler{
    private RubyArray errors;
    private Ruby ruby;

    public SchemaErrorHandler(Ruby ruby, RubyArray array) {
        this.ruby = ruby;
        this.errors = array;
    }

    public void warning(SAXParseException ex) throws SAXException {
        this.errors.append(new XmlSyntaxError(ruby, ex));
    }

    public void error(SAXParseException ex) throws SAXException {
        this.errors.append(new XmlSyntaxError(ruby, ex));
    }

    public void fatalError(SAXParseException ex) throws SAXException {
        throw ex;
    }

}
