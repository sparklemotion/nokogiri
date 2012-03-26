/**
 * (The MIT License)
 *
 * Copyright (c) 2011:
 *
 * * {Koichiro Ohba}[http://twitter.com/koichiroo]
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

import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Iterator;
import javax.xml.namespace.QName;
import javax.xml.stream.XMLStreamConstants;
import javax.xml.stream.XMLStreamException;
import javax.xml.stream.XMLStreamReader;
import javax.xml.stream.util.StreamReaderDelegate;

/**
 *
 * @author Koichiro Ohba <koichiro@meadowy.org>
 */
public class NokogiriXmlStreamReader extends StreamReaderDelegate {

    private int depth;
    private String lang;
    private Deque<XmlBase> xmlBase;

    static class XmlBase {
        private String uri;
        private QName qname;
        XmlBase(QName q, String u) {
            qname = q;
            uri = u;
        }
        String uri() { return uri; }
        QName qname() { return qname; }

        @Override
        public String toString() {
            return qname.toString() + " " + uri;
        }
    }

    public NokogiriXmlStreamReader(XMLStreamReader reader) {
        super(reader);
        depth = 0;
        xmlBase = new ArrayDeque<XmlBase>();
    }

    public int getDepth() {
        return depth;
    }

    public String getXMLBase() {
        if (xmlBase.isEmpty()) return null;
        return xmlBase.peek().uri();
    }

    public String getLang() {
        return lang;
    }

    private void resolveXMLLang() {
        String l = getParent().getAttributeValue("http://www.w3.org/XML/1998/namespace", "lang");
        if (l != null) lang = l;
    }

    private void resolveXMLBase() {
        String v = getParent().getAttributeValue("http://www.w3.org/XML/1998/namespace", "base");
        if (v == null) return;
        if (v.startsWith("http://")) {
            xmlBase.push(new XmlBase(getName(), v));
        } else if (xmlBase.peek() != null) {
            String base = xmlBase.peek().uri();
            if (base.endsWith("/")) {
                xmlBase.push(new XmlBase(getName(), base.concat(v)));
            } else if (v.startsWith("/")) {
                xmlBase.push(new XmlBase(getName(), base.concat(v)));
            } else {
                xmlBase.push(new XmlBase(getName(), base.concat("/").concat(v)));
            }
        }
    }

    private void removeXMLBase() {
        Iterator<XmlBase> i = xmlBase.iterator();
        while (i.hasNext()) {
            XmlBase base = i.next();
            if (getName().equals(base.qname())) {
                i.remove();
            }
        }
    }

    @Override
    public int next() throws XMLStreamException {
        switch (getParent().getEventType()) {
            case XMLStreamConstants.START_ELEMENT:
                depth++;
                break;
            case XMLStreamConstants.END_ELEMENT:
                removeXMLBase();
                break;
        }

        int result = getParent().next();

        switch (result) {
            case XMLStreamConstants.START_ELEMENT:
                resolveXMLLang();
                resolveXMLBase();
                break;
            case XMLStreamConstants.END_ELEMENT:
                depth--;
                break;
        }

        return result;
    }
}