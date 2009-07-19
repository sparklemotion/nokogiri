package nokogiri.internals;

/**
 *
 * @author sergio
 */
public class SaveContext {

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

    public SaveContext(int options, String indentString, String encoding) {
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

    public void append(StringBuffer sb) {
        this.buffer.append(sb);
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

    public boolean Xhtml() { return this.xhtml; }
}
