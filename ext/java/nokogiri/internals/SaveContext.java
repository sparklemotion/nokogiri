package nokogiri.internals;

import java.lang.Character;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyString;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

/**
 *
 * @author sergio
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

    public SaveContext(ThreadContext context, int options, String indentString,
                       String encoding) {
        this.context = context;
        this.elementDescription =
            (RubyClass) context.getRuntime().getClassFromPath(
                "Nokogiri::HTML::ElementDescription");
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
        if (format && !endsInWhitespace()) append(' ');
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
        return new RubyString(runtime, runtime.getString(), buffer);
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
