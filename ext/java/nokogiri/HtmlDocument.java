/**
 * (The MIT License)
 *
 * Copyright (c) 2008 - 2012:
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

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Helpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Attr;
import org.w3c.dom.Document;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import nokogiri.internals.HtmlDomParserContext;

import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;

/**
 * Class for Nokogiri::HTML::Document.
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */
@JRubyClass(name="Nokogiri::HTML::Document", parent="Nokogiri::XML::Document")
public class HtmlDocument extends XmlDocument {
    private static final String DEFAULT_CONTENT_TYPE = "html";
    private static final String DEFAULT_PUBLIC_ID = "-//W3C//DTD HTML 4.01//EN";
    private static final String DEFAULT_SYTEM_ID = "http://www.w3.org/TR/html4/strict.dtd";

    private String parsed_encoding = null;

    public HtmlDocument(Ruby ruby, RubyClass klazz) {
        super(ruby, klazz);
    }

    public HtmlDocument(Ruby runtime, Document document) {
        this(runtime, getNokogiriClass(runtime, "Nokogiri::XML::Document"), document);
    }

    public HtmlDocument(Ruby ruby, RubyClass klazz, Document doc) {
        super(ruby, klazz, doc);
    }

    @JRubyMethod(name="new", meta = true, rest = true, required=0)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject klazz, IRubyObject[] args) {
        final Ruby runtime = context.runtime;
        HtmlDocument htmlDocument;
        try {
            Document docNode = createNewDocument(runtime);
            htmlDocument = (HtmlDocument) NokogiriService.HTML_DOCUMENT_ALLOCATOR.allocate(runtime, (RubyClass) klazz);
            htmlDocument.setDocumentNode(context.runtime, docNode);
        } catch (Exception ex) {
            throw asRuntimeError(runtime, "couldn't create document: ", ex);
        }

        Helpers.invoke(context, htmlDocument, "initialize", args);

        return htmlDocument;
    }

    public IRubyObject getInternalSubset(ThreadContext context) {
        IRubyObject internalSubset = super.getInternalSubset(context);

        // html documents are expected to have a default internal subset
        // the default values are the same ones used when the following
        // feature is turned on
        // "http://cyberneko.org/html/features/insert-doctype"
        // the reason we don't turn it on, is because it overrides the document's
        // declared doctype declaration.

        if (internalSubset.isNil()) {
            internalSubset = XmlDtd.newEmpty(context.getRuntime(),
                                             getDocument(),
                                             context.getRuntime().newString(DEFAULT_CONTENT_TYPE),
                                             context.getRuntime().newString(DEFAULT_PUBLIC_ID),
                                             context.getRuntime().newString(DEFAULT_SYTEM_ID));
            setInternalSubset(internalSubset);
        }

        return internalSubset;
    }

    @Override
    void init(Ruby runtime, Document document) {
        stabilizeTextContent(document);
        document.normalize();
        setInstanceVariable("@decorators", runtime.getNil());
        if (document.getDocumentElement() != null) {
            stabilizeAttrs(document.getDocumentElement());
        }
    }

    private static void stabilizeAttrs(Node node) {
        if (node.hasAttributes()) {
            NamedNodeMap nodeMap = node.getAttributes();
            for (int i=0; i<nodeMap.getLength(); i++) {
                Node n = nodeMap.item(i);
                if (n instanceof Attr) {
                    stabilizeAttr((Attr) n);
                }
            }
        }
        NodeList children = node.getChildNodes();
        for (int i=0; i<children.getLength(); i++) {
            stabilizeAttrs(children.item(i));
        }
    }
    
    public void setParsedEncoding(String encoding) {
        parsed_encoding = encoding;
    }
    
    public String getPraedEncoding() {
        return parsed_encoding;
    }

    /*
     * call-seq:
     *  read_io(io, url, encoding, options)
     *
     * Read the HTML document from +io+ with given +url+, +encoding+,
     * and +options+.  See Nokogiri::HTML.parse
     */
    @JRubyMethod(meta = true, required = 4)
    public static IRubyObject read_io(ThreadContext context, IRubyObject klass, IRubyObject[] args) {
        HtmlDomParserContext ctx = new HtmlDomParserContext(context.runtime, args[2], args[3]);
        ctx.setIOInputSource(context, args[0], args[1]);
        return ctx.parse(context, (RubyClass) klass, args[1]);
    }

    /*
     * call-seq:
     *  read_memory(string, url, encoding, options)
     *
     * Read the HTML document contained in +string+ with given +url+, +encoding+,
     * and +options+.  See Nokogiri::HTML.parse
     */
    @JRubyMethod(meta = true, required = 4)
    public static IRubyObject read_memory(ThreadContext context, IRubyObject klass, IRubyObject[] args) {
        HtmlDomParserContext ctx = new HtmlDomParserContext(context.runtime, args[2], args[3]);
        ctx.setStringInputSource(context, args[0], args[1]);
        return ctx.parse(context, (RubyClass) klass, args[1]);
    }
}
