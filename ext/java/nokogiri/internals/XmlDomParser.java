package nokogiri.internals;

import java.io.IOException;

import nokogiri.XmlDocument;

import org.apache.xerces.parsers.DOMParser;
import org.apache.xerces.xni.parser.XMLParserConfiguration;
import org.cyberneko.dtd.DTDConfiguration;
import org.w3c.dom.Document;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

/**
 * Sets up a Xerces/XNI DOM Parser for use with Nokogiri.  Uses
 * NekoDTD to parse the DTD into a tree of Nodes.
 *
 * @author Patrick Mahoney <pat@polycrystal.org>
 */
public class XmlDomParser extends DOMParser {
    DOMParser dtd;

    public XmlDomParser() {
        super();

        DTDConfiguration dtdConfig = new DTDConfiguration();
        dtd = new DOMParser(dtdConfig);

        XMLParserConfiguration config = getXMLParserConfiguration();
        config.setDTDHandler(dtdConfig);
        config.setDTDContentModelHandler(dtdConfig);
    }

    @Override
    public void parse(InputSource source) throws SAXException, IOException {
        dtd.reset();
        super.parse(source);
        Document doc = getDocument();
        if (doc == null)
            throw new RuntimeException("null document");

        doc.setUserData(XmlDocument.DTD_RAW_DOCUMENT, dtd.getDocument(),
                        null);
    }
}
