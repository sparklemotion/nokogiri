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

import java.io.InputStream;

import org.apache.xerces.parsers.AbstractSAXParser;
import org.cyberneko.html.parsers.SAXParser;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.xml.sax.SAXException;

import nokogiri.internals.NokogiriHandler;
import nokogiri.internals.NokogiriHelpers;

/**
 * Class for Nokogiri::HTML::SAX::ParserContext.
 *
 * @author serabe
 * @author Patrick Mahoney <pat@polycrystal.org>
 * @author Yoko Harada <yokolet@gmail.com>
 */

@JRubyClass(name="Nokogiri::HTML::SAX::ParserContext", parent="Nokogiri::XML::SAX::ParserContext")
public class HtmlSaxParserContext extends XmlSaxParserContext {

    public HtmlSaxParserContext(Ruby ruby, RubyClass rubyClass) {
        super(ruby, rubyClass);
    }
    
    @Override
    protected AbstractSAXParser createParser() throws SAXException {
        SAXParser parser = new SAXParser();

        try{
            parser.setProperty(
                "http://cyberneko.org/html/properties/names/elems", "lower");
            parser.setProperty(
                "http://cyberneko.org/html/properties/names/attrs", "lower");

            // NekoHTML should not try to guess the encoding based on the meta
            // tags or other information in the document.  This is already
            // handled by the EncodingReader.
            parser.setFeature("http://cyberneko.org/html/features/scanner/ignore-specified-charset", true);
            return parser;
        } catch(SAXException ex) {
            throw new SAXException(
                "Problem while creating HTML SAX Parser: " + ex.toString());
        }
    }

    @JRubyMethod(name="memory", meta=true)
    public static IRubyObject parse_memory(ThreadContext context,
                                           IRubyObject klazz,
                                           IRubyObject data,
                                           IRubyObject encoding) {
        HtmlSaxParserContext ctx = (HtmlSaxParserContext) NokogiriService.HTML_SAXPARSER_CONTEXT_ALLOCATOR.allocate(context.getRuntime(), (RubyClass)klazz);
        ctx.initialize(context.runtime);
        ctx.java_encoding = NokogiriHelpers.getValidEncodingOrNull(context.runtime, encoding);
        ctx.setStringInputSource(context, data, context.nil);
        return ctx;
    }

    public enum EncodingType {
        NONE(0, "NONE"),
        UTF_8(1, "UTF-8"),
        UTF16LE(2, "UTF16LE"),
        UTF16BE(3, "UTF16BE"),
        UCS4LE(4, "UCS4LE"),
        UCS4BE(5, "UCS4BE"),
        EBCDIC(6, "EBCDIC"),
        UCS4_2143(7, "ICS4-2143"),
        UCS4_3412(8, "UCS4-3412"),
        UCS2(9, "UCS2"),
        ISO_8859_1(10, "ISO-8859-1"),
        ISO_8859_2(11, "ISO-8859-2"),
        ISO_8859_3(12, "ISO-8859-3"),
        ISO_8859_4(13, "ISO-8859-4"),
        ISO_8859_5(14, "ISO-8859-5"),
        ISO_8859_6(15, "ISO-8859-6"),
        ISO_8859_7(16, "ISO-8859-7"),
        ISO_8859_8(17, "ISO-8859-8"),
        ISO_8859_9(18, "ISO-8859-9"),
        ISO_2022_JP(19, "ISO-2022-JP"),
        SHIFT_JIS(20, "SHIFT-JIS"),
        EUC_JP(21, "EUC-JP"),
        ASCII(22, "ASCII");
        
        private final int value;
        private final String name;

        EncodingType(int value, String name) {
            this.value = value;
            this.name = name;
        }
        
        public int getValue() {
            return value;
        }
        
        public String toString() {
            return name;
        }
    }
    
    private static String findName(final int value) {
        for (EncodingType type : EncodingType.values()) {
            if (type.getValue() == value) return type.toString();
        }
        return null;
    }
    
    private static String findEncoding(ThreadContext context, IRubyObject encoding) {
        // HTML::Sax::Parser leaks a libxml implementation detail and passes an
        // Encoding integer to parse_io.  We have to reverse map the integer
        // into a name.
        if (encoding instanceof RubyFixnum) {
            int value = RubyFixnum.fix2int((RubyFixnum) encoding);
            return findName(value);
        }

        return NokogiriHelpers.getValidEncodingOrNull(context.runtime, encoding);
    }

    @JRubyMethod(name="file", meta=true)
    public static IRubyObject parse_file(ThreadContext context,
                                         IRubyObject klazz,
                                         IRubyObject data,
                                         IRubyObject encoding) {
        HtmlSaxParserContext ctx = (HtmlSaxParserContext) NokogiriService.HTML_SAXPARSER_CONTEXT_ALLOCATOR.allocate(context.getRuntime(), (RubyClass)klazz);
        ctx.initialize(context.getRuntime());
        ctx.java_encoding = NokogiriHelpers.getValidEncodingOrNull(context.runtime, encoding);
        ctx.setInputSourceFile(context, data);
        return ctx;
    }

    @JRubyMethod(name="io", meta=true)
    public static IRubyObject parse_io(ThreadContext context,
                                       IRubyObject klazz,
                                       IRubyObject data,
                                       IRubyObject encoding) {
        HtmlSaxParserContext ctx = (HtmlSaxParserContext) NokogiriService.HTML_SAXPARSER_CONTEXT_ALLOCATOR.allocate(context.getRuntime(), (RubyClass)klazz);
        ctx.initialize(context.getRuntime());
        ctx.java_encoding = findEncoding(context, encoding);
        ctx.setIOInputSource(context, data, context.getRuntime().getNil());
        return ctx;
    }

    /**
     * Create a new parser context that will read from a raw input stream.
     * Meant to be run in a separate thread by HtmlSaxPushParser.
     */
    static HtmlSaxParserContext parse_stream(final Ruby runtime, RubyClass klazz, InputStream stream) {
        HtmlSaxParserContext ctx = (HtmlSaxParserContext) NokogiriService.HTML_SAXPARSER_CONTEXT_ALLOCATOR.allocate(runtime, klazz);
        ctx.initialize(runtime);
        ctx.setInputSource(stream);
        return ctx;
    }

    @Override
    protected void preParse(final Ruby runtime, IRubyObject handlerRuby, NokogiriHandler handler) {
        // this function is meant to be empty.  It overrides the one in XmlSaxParserContext
    }

}
