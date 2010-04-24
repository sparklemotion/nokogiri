package nokogiri.internals;

import java.util.ArrayList;
import java.util.List;
import org.apache.xerces.xni.parser.XMLParseException;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;

/**
 *
 * @author sergio
 */
public class NokogiriStrictErrorHandler extends NokogiriErrorHandler{

    @Override
    public List<IRubyObject> getErrorsReadyForRuby(ThreadContext context){
        return new ArrayList<IRubyObject>();
    }

    public void warning(SAXParseException spex) throws SAXException {
        throw spex;
    }

    public void error(SAXParseException spex) throws SAXException {
        throw spex;
    }

    public void fatalError(SAXParseException spex) throws SAXException {
        throw spex;
    }

    public void error(String domain, String key, XMLParseException e)
        throws XMLParseException {
        throw e;
    }

    public void fatalError(String domain, String key, XMLParseException e)
        throws XMLParseException {
        throw e;
    }

    public void warning(String domain, String key, XMLParseException e)
        throws XMLParseException {
        throw e;
    }

}
