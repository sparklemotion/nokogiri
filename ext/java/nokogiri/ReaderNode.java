package nokogiri;

import org.jruby.Ruby;
import org.jruby.RubyBoolean;
import org.jruby.runtime.builtin.IRubyObject;
import org.xml.sax.Attributes;
import org.xml.sax.SAXParseException;

abstract class ReaderNode {

    Ruby ruby;
    RubyBoolean value_p;
    IRubyObject uri, localName, qName, value;
    Attributes attrs;

    // Construct an Element Node. Maybe, if this go further, I should make subclasses.
    public static ReaderNode createElementNode(Ruby ruby, String uri, String localName, String qName, Attributes attrs) {
        return new ElementNode(ruby, uri, localName, qName, attrs);
    }

    public static ReaderNode createEmptyNode(Ruby ruby) {
        return new EmptyNode(ruby);
    }

    public static ReaderNode createExceptionNode(Ruby ruby, SAXParseException ex) {
        return new ExceptionNode(ruby, ex);
    }

    // Construct a Text Node.
    public static ReaderNode createTextNode(Ruby ruby, String content) {
        return new TextNode(ruby, content);
    }

    public boolean fits(String uri, String localName, String qName) {
        return this.uri.asJavaString().equals(uri) &&
                this.localName.asJavaString().equals(localName) &&
                this.qName.asJavaString().equals(qName);
    }

    public IRubyObject getLocalName() {
        return this.localName;
    }

    public IRubyObject getName() {
        return this.qName;
    }

    public IRubyObject getQName() {
        return this.qName;
    }

    public IRubyObject getUri() {
        return this.uri;
    }

    public IRubyObject getValue() {
        return this.value;
    }

    public abstract RubyBoolean hasValue();

    public RubyBoolean isDefault(){
        // TODO Implement.
        return ruby.getFalse();
    }

    public boolean isError() { return false; }

    protected IRubyObject toRubyString(String string) {
        return (string == null) ? this.ruby.newString() : this.ruby.newString(string);
    }

    public IRubyObject toSyntaxError() { return this.ruby.getNil(); }
}

class ElementNode extends ReaderNode {

    public ElementNode(Ruby ruby, String uri, String localName, String qName, Attributes attrs) {
        this.ruby = ruby;
        this.uri = toRubyString(uri);
        this.localName = toRubyString(localName);
        this.qName = toRubyString(qName);
        this.value_p = ruby.getFalse();
        this.attrs = attrs; // I don't know what to do with you yet, my friend.
    }

    @Override
    public RubyBoolean hasValue() {
        return ruby.getFalse();
    }

}

class EmptyNode extends ReaderNode {

    public EmptyNode(Ruby ruby) {
        this.ruby = ruby;
        this.uri = this.value = this.localName = this.qName = ruby.getNil();
    }

    @Override
    public RubyBoolean hasValue() {
        return ruby.getFalse();
    }
}

class ExceptionNode extends EmptyNode {
    private final XmlSyntaxError exception;

    // Still don't know what to do with ex.
    public ExceptionNode(Ruby ruby, SAXParseException ex) {
        super(ruby);
        this.exception = new XmlSyntaxError(ruby);
    }
    
    @Override
    public boolean isError() { return true; }

    @Override
    public IRubyObject toSyntaxError(){
        return this.exception;
    }
}
class TextNode extends ReaderNode {

    public TextNode(Ruby ruby, String content) {
        this.ruby = ruby;
        this.uri = ruby.newString();
        this.value = toRubyString(content);
        this.localName = toRubyString("#text");
        this.qName = toRubyString("#text");
    }

    @Override
    public RubyBoolean hasValue() {
        return ruby.getTrue();
    }
}