package nokogiri.internals;

import java.io.IOException;
import java.io.InputStream;
import java.io.StringReader;
import javax.xml.parsers.ParserConfigurationException;
import nokogiri.XmlDocument;
import org.apache.xerces.xni.Augmentations;
import org.apache.xerces.xni.QName;
import org.apache.xerces.xni.XMLAttributes;
import org.apache.xerces.xni.XNIException;
import org.apache.xerces.xni.parser.XMLDocumentFilter;
import org.cyberneko.html.filters.DefaultFilter;
import org.cyberneko.html.parsers.DOMParser;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

/**
 *
 * @author sergio
 */
public class HtmlParseOptions extends ParseOptions{

    public HtmlParseOptions(IRubyObject options) {
        super(options);
    }

    public HtmlParseOptions(long options) {
        super(options);
    }

    @Override
    protected XmlDocument getNewEmptyDocument(ThreadContext context) {
        IRubyObject[] args = new IRubyObject[0];
        return (XmlDocument) XmlDocument.rbNew(context,
                    context.getRuntime().getClassFromPath("Nokogiri::XML::Document"),
                    args);
    }

    @Override
    public Document parse(InputSource input)
            throws ParserConfigurationException, SAXException, IOException {
        DOMParser parser = new DOMParser();
        parser.setProperty("http://cyberneko.org/html/properties/filters",
              new XMLDocumentFilter[] { new DefaultFilter() {
                  @Override
                  public void startElement(QName element, XMLAttributes attrs,
                                         Augmentations augs) throws XNIException {
                  element.uri = null;
                  super.startElement(element, attrs, augs);
                }
              }});

        parser.parse(input);
        return parser.getDocument();
    }

    @Override
    public Document parse(InputStream input)
            throws ParserConfigurationException, SAXException, IOException {
        return this.parse(new InputSource(input));
    }

    @Override
    public Document parse(String input)
            throws ParserConfigurationException, SAXException, IOException {
        StringReader sr = new StringReader(input);
        return this.parse(new InputSource(sr));
    }
}
