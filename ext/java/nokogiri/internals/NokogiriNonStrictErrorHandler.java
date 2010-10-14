package nokogiri.internals;

import org.apache.xerces.xni.parser.XMLParseException;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;

/**
 * Error Handler for XML document when recover is true (default).
 * 
 * @author sergio
 */
public class NokogiriNonStrictErrorHandler extends NokogiriErrorHandler{
    public NokogiriNonStrictErrorHandler(boolean noerror, boolean nowarning) {
        super(noerror, nowarning);
    }

    public void warning(SAXParseException ex) throws SAXException {
        errors.add(ex);
    }

    public void error(SAXParseException ex) throws SAXException {
        errors.add(ex);
    }

    public void fatalError(SAXParseException ex) throws SAXException {
        errors.add(ex);
    }

    public void error(String domain, String key, XMLParseException e) {
        errors.add(e);
    }

    public void fatalError(String domain, String key, XMLParseException e) {
        errors.add(e);
    }

    public void warning(String domain, String key, XMLParseException e) {
        errors.add(e);
    }

}
