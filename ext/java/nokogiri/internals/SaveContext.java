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

import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;

import java.nio.charset.Charset;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyEncoding;
import org.jruby.RubyString;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;

/**
 * A class for serializing a document.
 * 
 * @author sergio
 * @author Patrick Mahoney <pat@polycrystal.org>
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class SaveContext {

    private final ThreadContext context;
    private final RubyClass elementDescription;
    private StringBuffer buffer;
    private int options;
    private int level=0;
    private String encoding, indentString;
    private boolean format, noDecl, noEmpty, noXhtml, xhtml, asXml, asHtml;

    /*
     * U can't touch this.
     * http://www.youtube.com/watch?v=WJ2ZFVx6A4Q
     *
     * Taken from libxml save options.
     */

    public static final int FORMAT = 1;
    public static final int NO_DECL = 2;
    public static final int NO_EMPTY = 4;
    public static final int NO_XHTML = 8;
    public static final int XHTML = 16;
    public static final int AS_XML = 32;
    public static final int AS_HTML = 64;

    public SaveContext(ThreadContext context, int options, String indentString, String encoding) {
        this.context = context;
        this.elementDescription = (RubyClass)getNokogiriClass(context.getRuntime(), "Nokogiri::HTML::ElementDescription");
        this.options = options;
        this.encoding = encoding;
        this.indentString = indentString;
        this.buffer = new StringBuffer();
        format = (options & FORMAT) == FORMAT;
        noDecl = (options & NO_DECL) == NO_DECL;
        noEmpty = (options & NO_EMPTY) == NO_EMPTY;
        noXhtml = (options & NO_XHTML) == NO_XHTML;
        xhtml = (options & XHTML) == XHTML;
        asXml = (options & AS_XML) == AS_XML;
        asHtml = (options & AS_HTML) == AS_HTML;
    }
    
    public void append(String s) {
        this.buffer.append(s);
    }

    public void append(char c) {
        buffer.append(c);
    }

    public void append(StringBuffer sb) {
        this.buffer.append(sb);
    }

    public void appendQuoted(String s) {
        this.append("\"");
        this.append(s);
        this.append("\"");
    }

    public void appendQuoted(StringBuffer sb) {
        this.append("\"");
        this.append(sb);
        this.append("\"");
    }

    public void emptyTag(String name) {
        emptyTagStart(name);
        emptyTagEnd(name);
    }

    public void emptyTagStart(String name) {
        openTagInlineStart(name);
    }

    public void emptyTagEnd(String name) {
        if (asHtml) {
            if (isEmpty(name) && noEmpty()) {
                append(">");
            } else {
                openTagInlineEnd();
                closeTagInline(name);
            }
        } else if (xhtml) {
            append(" />");
        } else {
            append("/>");
        }
    }

    public void openTag(String name) {
        openTagStart(name);
        openTagEnd();
    }

    public void openTagStart(String name) {
        maybeBreak();
        indent();
        append("<");
        append(name);
    }

    public void openTagEnd() {
        append(">");
        maybeBreak();
        increaseLevel();
    }

    public void closeTag(String name) {
        decreaseLevel();
        maybeBreak();
        indent();
        append("</");
        append(name);
        append(">");
        maybeBreak();
    }

    public void openTagInline(String name) {
        openTagInlineStart(name);
        openTagInlineEnd();
    }

    public void openTagInlineStart(String name) {
        maybeIndent();
        append("<");
        append(name);
    }

    public void openTagInlineEnd() {
        append(">");
    }

    public void closeTagInline(String name) {
        append("</");
        append(name);
        append(">");
    }

    public void maybeBreak() {
        if (format && !endsInNewline()) append('\n');
    }

    public void maybeSpace() {
        if (!endsInWhitespace()) append(' ');
    }

    /**
     * Indent if this is the start of a fresh line.
     */
    public void maybeIndent() {
        if (format && endsInNewline()) indent();
    }

    public void indent() {
        if (format) append(getCurrentIndentString());
    }

    public boolean endsInWhitespace() {
        return (Character.isWhitespace(lastChar()));
    }

    public boolean endsInNewline() {
        return (lastChar() == '\n');
    }

    public char lastChar() {
        if (buffer.length() == 0) return '\n'; // logically, the char
                                               // *before* a text file
                                               // is a newline
        return buffer.charAt(buffer.length() - 1);
    }

    public boolean asHtml() { return this.asHtml; }

    public boolean asXml() { return this.asXml; }
    
    public void decreaseLevel() {
        if(this.level > 0) this.level--;
    }

    public String encoding() { return this.encoding; }

    public boolean format() { return this.format; }

    public String getCurrentIndentString() {
        StringBuffer res = new StringBuffer();
        for(int i = 0; i < this.level; i++) {
            res.append(this.indentString());
        }
        return res.toString();
    }

    public String getEncoding() { return this.encoding; }

    public void increaseLevel() {
        if(this.level >= 0) this.level++;
    }

    public String indentString() { return this.indentString; }

    public boolean noDecl() { return this.noDecl; }

    public boolean noEmpty() { return this.noEmpty; }

    public boolean noXhtml() { return this.noXhtml; }

    public void setFormat(boolean format) { this.format = format; }

    public void setLevel(int level) { this.level = level; }

    @Override
    public String toString() { return this.buffer.toString(); }

    public RubyString toRubyString(Ruby runtime) {
        ByteList bytes;
        if (encoding == null) bytes = new ByteList(buffer.toString().getBytes());
        else bytes = new ByteList(RubyEncoding.encode(buffer.toString(), Charset.forName(encoding)), false);
        return RubyString.newString(runtime, bytes);
    }

    public boolean Xhtml() { return this.xhtml; }

    /**
     * Looks up the HTML ElementDescription and tests if it is an
     * empty element.
     */
    protected boolean isEmpty(String name) {
        IRubyObject desc =
            RuntimeHelpers.invoke(context,
                                  elementDescription, "[]",
                                  context.getRuntime().newString(name));
        return RuntimeHelpers.invoke(context, desc, "empty?").isTrue();
    }
}
