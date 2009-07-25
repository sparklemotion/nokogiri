package nokogiri.internals;

import java.util.ArrayList;
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

}
