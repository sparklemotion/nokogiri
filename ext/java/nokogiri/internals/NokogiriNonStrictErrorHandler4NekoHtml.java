package nokogiri.internals;

import org.apache.xerces.xni.parser.XMLParseException;
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
 * base on the given fragment won't be created. This is why warnings are eliminated.
 * 
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class NokogiriNonStrictErrorHandler4NekoHtml extends NokogiriErrorHandler {
    private boolean noerror;
    
    public NokogiriNonStrictErrorHandler4NekoHtml() {
        this.noerror = false;
    }
    
    public NokogiriNonStrictErrorHandler4NekoHtml(boolean noerror) {
        this.noerror = noerror;
    }

    public void warning(SAXParseException ex) throws SAXException {
        //noop. NekoHtml adds too many warnings.
    }

    public void error(SAXParseException ex) throws SAXException {
        if (!noerror) this.errors.add(ex);
    }

    public void fatalError(SAXParseException ex) throws SAXException {
        this.errors.add(ex);
    }

    public void error(String domain, String key, XMLParseException e) {
        if (!noerror) addError(e);
    }

    public void fatalError(String domain, String key, XMLParseException e) {
        addError(e);
    }

    public void warning(String domain, String key, XMLParseException e) {
        //noop. NekoHtml adds too many warnings.
    }

}
