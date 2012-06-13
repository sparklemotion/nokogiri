/**
 * (The MIT License)
 *
 * Copyright (c) 2008 - 2011:
 *
 * * {Aaron Patterson}[http://tenderlovemaking.com]
 * * {Mike Dalessio}[http://mike.daless.io]
 * * {Charles Nutter}[http://blog.headius.com]
 * * {Sergio Arbeo}[http://www.serabe.com]
 * * {Patrick Mahoney}[http://polycrystal.org]
 * * {Yoko Harada}[http://yokolet.blogspot.com]
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * 'Software'), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

package nokogiri.internals;

import java.io.IOException;

import nokogiri.XmlDocument;
import nokogiri.internals.ParserContext.Options;

import org.apache.xerces.parsers.DOMParser;
import org.apache.xerces.parsers.XIncludeParserConfiguration;
import org.apache.xerces.xni.XMLResourceIdentifier;
import org.apache.xerces.xni.XNIException;
import org.apache.xerces.xni.parser.XMLEntityResolver;
import org.apache.xerces.xni.parser.XMLInputSource;
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
    ParserContext.Options options;

    public XmlDomParser(ParserContext.Options options) {
        super();
        this.options = options;

        DTDConfiguration dtdConfig = new DTDConfiguration();
        dtd = new DOMParser(dtdConfig);

        XMLParserConfiguration config;
        if (options.xInclude) {
            config = new XIncludeParserConfiguration();
        } else {
            config = getXMLParserConfiguration();
        }
        config.setDTDHandler(dtdConfig);
        config.setDTDContentModelHandler(dtdConfig);
    }

    @Override
    public void parse(InputSource source) throws SAXException, IOException {
        dtd.reset();
        if (options.xInclude) {
            super.setEntityResolver(new NokogiriXInlcudeEntityResolver(source));
        }
        super.parse(source);
        Document doc = getDocument();
        if (doc == null)
            throw new RuntimeException("null document");

        doc.setUserData(XmlDocument.DTD_RAW_DOCUMENT, dtd.getDocument(), null);
    }
    
    private class NokogiriXInlcudeEntityResolver implements org.xml.sax.EntityResolver {
        InputSource source;
        private NokogiriXInlcudeEntityResolver(InputSource source) {
            this.source = source;
        }

        @Override
        public InputSource resolveEntity(String publicId, String systemId)
                throws SAXException, IOException {
            if (systemId != null) source.setSystemId(systemId);
            if (publicId != null) source.setPublicId(publicId);
            return source;
        }
    }
}
