package nokogiri.internals;

import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;
import static nokogiri.internals.NokogiriHelpers.isNamespace;
import nokogiri.HtmlDocument;
import nokogiri.XmlDocument;

import org.apache.xerces.parsers.DOMParser;
import org.apache.xerces.xni.Augmentations;
import org.apache.xerces.xni.QName;
import org.apache.xerces.xni.XMLAttributes;
import org.apache.xerces.xni.XNIException;
import org.apache.xerces.xni.parser.XMLDocumentFilter;
import org.apache.xerces.xni.parser.XMLParserConfiguration;
import org.cyberneko.html.HTMLConfiguration;
import org.cyberneko.html.filters.DefaultFilter;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;

/**
 *
 * @author sergio
 */
public class HtmlDomParserContext extends XmlDomParserContext {
    protected static final String PROPERTY_FILTERS =
        "http://cyberneko.org/html/properties/filters";
    protected static final String PROPERTY_ELEM_NAMES =
        "http://cyberneko.org/html/properties/names/elems";
    protected static final String PROPERTY_ATTRS_NAMES =
        "http://cyberneko.org/html/properties/names/attrs";
    protected static final String FEATURE_DOCUMENT_FRAGMENT =
        "http://cyberneko.org/html/features/balance-tags/document-fragment";
    protected static final String FEATURE_REPORT_ERRORS =
        "http://cyberneko.org/html/features/report-errors";

    public HtmlDomParserContext(Ruby runtime, IRubyObject options) {
        super(runtime, options);
    }
    
    public HtmlDomParserContext(Ruby runtime, IRubyObject encoding, IRubyObject options) {
        super(runtime, encoding, options);
    }

    @Override
    protected void initErrorHandler() {
        if (continuesOnError()) {
            errorHandler = new NokogiriNonStrictErrorHandler4NekoHtml();
        } else if (options.noError) {
            errorHandler = new NokogiriNonStrictErrorHandler4NekoHtml(options.noError);
        } else {
            errorHandler = new NokogiriStrictErrorHandler();
        }
    }

    @Override
    protected void initParser(Ruby runtime) {
        XMLParserConfiguration config = new HTMLConfiguration();
        XMLDocumentFilter removeNSAttrsFilter = new RemoveNSAttrsFilter();
        XMLDocumentFilter elementValidityCheckFilter = new ElementValidityCheckFilter(errorHandler);
        //XMLDocumentFilter[] filters = { removeNSAttrsFilter};
        XMLDocumentFilter[] filters = { removeNSAttrsFilter,  elementValidityCheckFilter};

        config.setErrorHandler(this.errorHandler);
        parser = new DOMParser(config);

        setProperty("http://cyberneko.org/html/properties/default-encoding", java_encoding);
        setProperty(PROPERTY_ELEM_NAMES, "lower");
        setProperty(PROPERTY_ATTRS_NAMES, "lower");
        setFeature(FEATURE_REPORT_ERRORS, true);
        setFeature("http://xml.org/sax/features/namespaces", false);
        setProperty(PROPERTY_FILTERS, filters);
    }

    /**
     * Enable NekoHTML feature for balancing tags in a document
     * fragment.
     */
    public void enableDocumentFragment() {
        setFeature(FEATURE_DOCUMENT_FRAGMENT, true);
    }

    @Override
    protected XmlDocument getNewEmptyDocument(ThreadContext context) {
        IRubyObject[] args = new IRubyObject[0];
        return (XmlDocument) XmlDocument.rbNew(context,
                    getNokogiriClass(context.getRuntime(), "Nokogiri::XML::Document"),
                    args);
    }

    @Override
    protected XmlDocument wrapDocument(ThreadContext context,
                                       RubyClass klass,
                                       Document doc) {
        HtmlDocument htmlDocument = new HtmlDocument(context.getRuntime(), klass, doc);
        htmlDocument.setEncoding(ruby_encoding);
        return htmlDocument;
    }

    /**
     * Filter to strip out attributes that pertain to XML namespaces.
     *
     * @author sergio
     * @author Patrick Mahoney <pat@polycrystal.org>
     */
    public static class RemoveNSAttrsFilter extends DefaultFilter {
        @Override
        public void startElement(QName element, XMLAttributes attrs,
                                 Augmentations augs) throws XNIException {
            int i;
            for (i = 0; i < attrs.getLength(); ++i) {
                if (isNamespace(attrs.getQName(i))) {
                    attrs.removeAttributeAt(i);
                    --i;
                }
            }

            element.uri = null;
            super.startElement(element, attrs, augs);
        }
    }
    
    public static class ElementValidityCheckFilter extends DefaultFilter {
        private NokogiriErrorHandler errorHandler;
        
        private ElementValidityCheckFilter(NokogiriErrorHandler errorHandler) {
            this.errorHandler = errorHandler;
        }
        
        // element names from xhtml1-strict.dtd
        private static String[][] element_names = {
                {"a", "abbr", "acronym", "address", "area"},
                {"b", "base", "basefont", "bdo", "big", "blockquote", "body", "br", "button"},
                {"caption", "cite", "code", "col", "colgroup"},
                {"dd", "del", "dfn", "div", "dl", "dt"},
                {"em"},
                {"fieldset", "font", "form", "frame", "frameset"},
                {}, // g
                {"h1", "h2", "h3", "h4", "h5", "h6", "head", "hr", "html"},
                {"i", "iframe", "img", "input", "ins"},
                {}, // j
                {"kbd"},
                {"label", "legend", "li", "link"},
                {"map", "meta"},
                {"noframes", "noscript"},
                {"object", "ol", "optgroup", "option"},
                {"p", "param", "pre"},
                {"q"},
                {}, // r
                {"s", "samp", "script", "select", "small", "span", "strike", "strong", "style", "sub", "sup"},
                {"table", "tbody", "td", "textarea", "tfoot", "th", "thead", "title", "tr", "tt"},
                {"u", "ul"},
                {"var"},
                {}, // w
                {}, // x
                {}, // y
                {}  // z
        };
        
        private boolean isValid(String testee) {
            char[] c = testee.toCharArray();
            int index = new Integer(c[0]) - 97;
            for (int i=0; i<element_names[index].length; i++) {
                if (testee.equals(element_names[index][i])) {
                    return true;
                }
            }
            return false;
        }
        
        @Override
        public void startElement(QName name, XMLAttributes attrs, Augmentations augs) throws XNIException {
            if (!isValid(name.rawname)) {
                errorHandler.addError(new Exception("Tag " + name.rawname + " invalid"));
            }
            super.startElement(name, attrs, augs);
        }
    }
}
