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

package nokogiri;

import static nokogiri.internals.NokogiriHelpers.isXmlEscaped;
import static nokogiri.internals.NokogiriHelpers.rubyStringToString;
import static nokogiri.internals.NokogiriHelpers.stringOrNil;
import nokogiri.internals.NokogiriHelpers;
import nokogiri.internals.SaveContext;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.w3c.dom.Node;

/**
 * Class for Nokogiri::XML::Text
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */
@JRubyClass(name="Nokogiri::XML::Text", parent="Nokogiri::XML::CharacterData")
public class XmlText extends XmlNode {

    public XmlText(Ruby runtime, RubyClass rubyClass, Node node) {
        super(runtime, rubyClass, node);
    }

    public XmlText(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }

    @Override
    protected void init(ThreadContext context, IRubyObject[] args) {
        if (args.length < 2) {
            throw getRuntime().newArgumentError(args.length, 2);
        }

        content = args[0];
        IRubyObject xNode = args[1];

        XmlNode xmlNode = asXmlNode(context, xNode);
        XmlDocument xmlDoc = (XmlDocument)xmlNode.document(context);
        doc = xmlDoc;
        Document document = xmlDoc.getDocument();
        // text node content should not be encoded when it is created by Text node.
        // while content should be encoded when it is created by Element node.
        Node node = document.createTextNode(rubyStringToString(content));
        setNode(context, node);
    }
    
    @Override
    protected IRubyObject getNodeName(ThreadContext context) {
        if (name == null) name = context.getRuntime().newString("text");
        return name;
    }
    
    @Override
    @JRubyMethod(name = {"content", "text", "inner_text"})
    public IRubyObject content(ThreadContext context) {
        if (content == null || content.isNil()) {
            return stringOrNil(context.getRuntime(), node.getTextContent());
        } else {
            return content;
        }
    }

    @Override
    public void saveContent(ThreadContext context, SaveContext ctx) {
        String textContent = node.getTextContent();
        
        if (!isXmlEscaped(textContent)) {        
            textContent = NokogiriHelpers.encodeJavaString(textContent);
        }
        if (getEncoding(context, ctx) == null) {
            textContent = encodeStringToHtmlEntity(textContent);
        }
        ctx.append(textContent);
    }
    
    private String getEncoding(ThreadContext context, SaveContext ctx) {
        String encoding  = ctx.getEncoding();
        if (encoding != null) return encoding;
        XmlDocument xmlDocument = (XmlDocument)document(context);
        IRubyObject ruby_encoding = xmlDocument.encoding(context);
        if (!ruby_encoding.isNil()) {
            encoding = rubyStringToString(ruby_encoding);
        }
        return encoding;
    }
    
    private String encodeStringToHtmlEntity(String text) {
        int last = 126; // = U+007E. No need to encode under U+007E.
        StringBuffer sb = new StringBuffer();
        for (int i=0; i<text.length(); i++) {
            int codePoint = text.codePointAt(i);
            if (codePoint > last) sb.append("&#x" + Integer.toHexString(codePoint) + ";");
            else sb.append(text.charAt(i));
        }
        return new String(sb);
    }
}
