package nokogiri.internals;

import org.apache.xerces.xni.parser.XMLParseException;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;

/**
 *
 * @author sergio
 */
public class NokogiriNonStrictErrorHandler extends NokogiriErrorHandler{

    public void warning(SAXParseException ex) throws SAXException {
        this.errors.add(ex);
    }

    public void error(SAXParseException ex) throws SAXException {
        this.errors.add(ex);
    }

    public void fatalError(SAXParseException ex) throws SAXException {
        this.errors.add(ex);
    }

    public void error(String domain, String key, XMLParseException e) {
        addError(e);
    }

    public void fatalError(String domain, String key, XMLParseException e) {
        addError(e);
    }

    public void warning(String domain, String key, XMLParseException e) {
        addError(e);
    }

}
