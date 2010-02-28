package nokogiri.internals;

import nokogiri.XmlAttr;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyString;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;
import org.xml.sax.ext.DefaultHandler2;

import java.util.logging.Logger;

/**
 *
 * @author sergio
 */
public class NokogiriHandler extends DefaultHandler2 {

    private static Logger LOGGER = Logger.getLogger(NokogiriHandler.class.getName());

    boolean inCDATA = false;

    private Ruby ruby;
    private IRubyObject object;
    private boolean namespaceDefined = false;

    public NokogiriHandler(Ruby ruby, IRubyObject object) {
        this.ruby = ruby;
        this.object = object;
    }

    @Override
    public void startDocument() throws SAXException {
        call("start_document");
    }

    @Override
    public void endDocument() throws SAXException {
        call("end_document");
    }

    /**
     * @return true if an XML namespace has been defined in the document, false otherwise.
     */
    private boolean isNamespaceDefined() {
        // Determining the namespace is important because we only want
        // start_element_namespace to be called if we have an 'xmlns' somewhere in the
        // document, even if the attribute or element is defined with foo:bar.
        return namespaceDefined;
    }

    private void inspectElementForNamespace(String qName, Attributes attrs) {
        LOGGER.fine("inspectElementForNamespace: qName = " + qName + ", attrs = " + attrs.toString());
        if (qName.equals("xmlns") || qName.startsWith("xmlns:")) {
           namespaceDefined = true;   
        }

        for (int i = 0; i < attrs.getLength(); i++) {
            if (attrs.getQName(i).startsWith("xmlns")) {
                namespaceDefined = true;
                break;
            }
        }
    }

    /*
     * This has to call either "start_element" or "start_element_namespace" depending on whether there
     *  are any namespace attributes.
     */
    @Override
    public void startElement(String uri, String localName, String qName, Attributes attrs) throws SAXException {
        int attributeLength = attrs.getLength();
        RubyArray rubyAttributes = RubyArray.newArray(ruby, attributeLength);

        inspectElementForNamespace(qName, attrs);

        if (attributeLength > 0) {
            // We expect attr to have "attr.prefix"
            // We expect attr to have "attr.localname"
            // We expect attr to have "attr.uri"
            for (int i = 0; i < attributeLength; i++) {
                String u = attrs.getURI(i);
                String q = attrs.getQName(i);
                String n = attrs.getLocalName(i);
                String v = attrs.getValue(i);
                //System.out.println("qName = " + q + ", localName = " + n + ", uri = " + u + "other uri = " + uri);
                XmlSaxAttribute attr = new XmlSaxAttribute(ruby, u, q, n, v);
                rubyAttributes.add(attr);
            }

            call("start_element_namespace", ruby.newString(qName), rubyAttributes);
        } else {
            call("start_element", ruby.newString(qName), rubyAttributes);
        }
    }
    
    @Override
    public void endElement(String uri, String localName, String qName) throws SAXException {
        call("end_element", ruby.newString(qName));
    }

    @Override
    public void characters(char[] ch, int start, int length) throws SAXException {
        String target = inCDATA ? "cdata_block" : "characters";
        call(target, ruby.newString(new String(ch, start, length)));
    }

    @Override
    public void comment(char[] ch, int start, int length) throws SAXException {
        call("comment", ruby.newString(new String(ch, start, length)));
    }

    @Override
    public void startCDATA() throws SAXException {
        inCDATA = true;
    }

    @Override
    public void endCDATA() throws SAXException {
        inCDATA = false;
    }

    @Override
    public void error(SAXParseException saxpe) {
        call("error", ruby.newString(saxpe.getMessage()));
    }

    @Override
    public void fatalError(SAXParseException saxpe) throws SAXException
    {
        call("error", ruby.newString(saxpe.getMessage()));
    }

    @Override
    public void warning(SAXParseException saxpe) {
        call("warning", ruby.newString(saxpe.getMessage()));
    }

    private void call(String methodName) {
        ThreadContext context = ruby.getCurrentContext();
        RuntimeHelpers.invoke(context, document(context), methodName);
    }

    private void call(String methodName, IRubyObject argument) {
        ThreadContext context = ruby.getCurrentContext();
        RuntimeHelpers.invoke(context, document(context), methodName, argument);
    }

    private void call(String methodName, IRubyObject arg1, IRubyObject arg2) {
        ThreadContext context = ruby.getCurrentContext();
        RuntimeHelpers.invoke(context, document(context), methodName, arg1, arg2);
    }

    private IRubyObject document(ThreadContext context){
		return RuntimeHelpers.invoke(context, this.object, "document");
    }

    /*
     * This is a "temporary" class to fix the test in test_parser.rb which expect attributes
     * to have attr.prefix and attr.localname defined.
     *
     * TODO: Review to see if this class can be eliminated or refactored.
     */
    public static final class XmlSaxAttribute {
        private Ruby ruby;
        private String uri;
        private String qName;
        private String localName;
        private String value;
        
        public XmlSaxAttribute(Ruby ruby, String uri, String qName, String localName, String value) {
            this.ruby = ruby;
            this.uri = uri;
            this.qName = qName;
            this.localName = localName;
            this.value = value;
        }

        public RubyString getQName() {
            return ruby.newString(this.qName);
        }

        public RubyString getPrefix() {
            int pos = this.qName.indexOf(':');
            String prefix;
            if (pos > 0) {
                prefix = this.qName.substring(0, pos);
            } else {
                prefix = this.qName;
            }
            return ruby.newString(prefix);
        }

        public RubyString getLocalname() {
            return ruby.newString(this.localName);
        }

        public RubyString getValue() {
            return ruby.newString(this.value);
        }

        public RubyString getUri() {
            return ruby.newString(this.uri);
        }
    }
}
