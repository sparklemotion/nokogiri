package nokogiri.internals;

import java.io.IOException;
import java.io.InputStream;
import javax.xml.parsers.ParserConfigurationException;
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
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

import static nokogiri.internals.NokogiriHelpers.isNamespace;

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

    public HtmlDomParserContext(Ruby runtime, long options) {
        super(runtime, options);
    }

    @Override
    protected void initParser(Ruby runtime) {
        XMLParserConfiguration config = new HTMLConfiguration();
        XMLDocumentFilter removeNSAttrsFilter = new RemoveNSAttrsFilter();
        XMLDocumentFilter[] filters = { removeNSAttrsFilter };

        config.setErrorHandler(this.errorHandler);
        parser = new DOMParser(config);

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
                    context.getRuntime().getClassFromPath("Nokogiri::XML::Document"),
                    args);
    }

    @Override
    protected XmlDocument wrapDocument(ThreadContext context,
                                       RubyClass klass,
                                       Document doc) {
        return new HtmlDocument(context.getRuntime(), klass, doc);
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
}
