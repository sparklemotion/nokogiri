package nokogiri;

import java.util.ArrayList;
import java.util.Hashtable;
import java.util.List;
import java.util.Map;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import org.jruby.Ruby;
import org.jruby.RubyBoolean;
import org.jruby.RubyHash;
import org.jruby.RubyString;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Attr;
import org.w3c.dom.Document;
import org.xml.sax.Attributes;
import org.xml.sax.SAXParseException;



abstract class ReaderNode {

    Ruby ruby;
    IRubyObject attrs, depth, lang, localName, namespaces, prefix, qName, uri, value, xmlVersion;
    /*
     * Difference between attrs and attributes is that attributes map includes
     * namespaces.
     */
    // FIXME: Maybe faster to return this instead of standar attributes method
    Map<IRubyObject,IRubyObject> attributes;
    IRubyObject[] attributeValues;
    private boolean closing;


    public ReaderNode getClosingNode(){
        return new ClosingNode(this.ruby, this);
    }

    // Construct an Element Node. Maybe, if this go further, I should make subclasses.
    public static ReaderNode createElementNode(Ruby ruby, String uri, String localName, String qName, Attributes attrs, int depth) {
        return new ElementNode(ruby, uri, localName, qName, attrs, depth);
    }

    public static ReaderNode createEmptyNode(Ruby ruby) {
        return new EmptyNode(ruby);
    }

    public static ReaderNode createExceptionNode(Ruby ruby, SAXParseException ex) {
        return new ExceptionNode(ruby, ex);
    }

    // Construct a Text Node.
    public static ReaderNode createTextNode(Ruby ruby, String content, int depth) {
        return new TextNode(ruby, content, depth);
    }

    public boolean fits(String uri, String localName, String qName) {
        return this.uri.asJavaString().equals(uri) &&
                this.localName.asJavaString().equals(localName) &&
                this.qName.asJavaString().equals(qName);
    }

    public IRubyObject getAttributeByIndex(IRubyObject index){
        if(index.isNil()) return index;
        
        long i = index.convertToInteger().getLongValue();
        if(i > Integer.MAX_VALUE)
            throw ruby.newArgumentError("value too long to be an array index");

        if(this.attributeValues == null){
            return ruby.getNil();
        } else if (i<0 ||this.attributeValues.length<=i){
            return ruby.getNil();
        } else {
            return this.attributeValues[(int) i];
        }
    }

    public IRubyObject getAttributeByName(IRubyObject name){
        if(this.attributes == null)
            return ruby.getNil();
        IRubyObject attrValue = this.attributes.get(name);
        return (attrValue == null) ? ruby.getNil() : attrValue;
    }

    public IRubyObject getAttributeByName(String name) {
        return this.getAttributeByName(ruby.newString(name));
    }

    public IRubyObject getAttributeCount(){
        if(this.attributes == null)
            return ruby.newFixnum(0);
        return ruby.newFixnum(this.attributes.size());
    }

    public IRubyObject getAttributesNodes() {
        if(this.attrs == null)
            this.attrs = this.ruby.newArray();
        return this.attrs;
    }

    public IRubyObject getDepth() {
        if(this.depth == null)
            this.depth = ruby.newFixnum(0);
        return this.depth;
    }

    public IRubyObject getLang() {
        if(this.lang == null)
            this.lang = ruby.getNil();
        return this.lang;
    }

    public IRubyObject getLocalName() {
        if(this.localName == null)
            this.localName = ruby.getNil();
        return this.localName;
    }

    public IRubyObject getName() {
        if(this.qName == null)
            this.qName = ruby.getNil();
        return this.qName;
    }

    public IRubyObject getNamespaces() {
        if(this.namespaces == null)
            this.namespaces = ruby.getNil();
        return this.namespaces;
    }

    public IRubyObject getPrefix() {
        if(this.prefix == null)
            this.prefix = ruby.getNil();
        return this.prefix;
    }

    public IRubyObject getQName() {
        if(this.qName == null)
            this.qName = ruby.getNil();
        return this.qName;
    }

    public IRubyObject getUri() {
        if(this.uri == null)
            this.uri = ruby.getNil();
        return this.uri;
    }

    public IRubyObject getValue() {
        if(this.value == null)
            this.value = ruby.getNil();
        return this.value;
    }

    public IRubyObject getXmlVersion() {
        if(this.xmlVersion == null)
            this.xmlVersion = ruby.newString("1.0");
        return this.xmlVersion;
    }

    public abstract RubyBoolean hasValue();

    public RubyBoolean isDefault(){
        // TODO Implement.
        return ruby.getFalse();
    }

    public boolean isError() { return false; }

    protected IRubyObject parsePrefix(String qName) {
        int index = qName.indexOf(':');
        if(index != -1)
            return ruby.newString(qName.substring(0, index));
        return ruby.getNil();
    }

    public void setLang(String lang) {
        this.lang = (lang == null) ? ruby.getNil() : ruby.newString(lang);
    }

    protected IRubyObject toRubyString(String string) {
        return (string == null) ? this.ruby.newString() : this.ruby.newString(string);
    }

    public IRubyObject toSyntaxError() { return this.ruby.getNil(); }
}


class ClosingNode extends ReaderNode{
    
    ReaderNode node;
    
    public ClosingNode(Ruby ruby, ReaderNode node){
        this.ruby = ruby;
        this.node = node;
    }
    
    @Override
    public boolean fits(String uri, String localName, String qName) {
        return this.node.fits(uri, localName, qName);
    }

    @Override
    public IRubyObject getAttributeByIndex(IRubyObject index){
        return this.node.getAttributeByIndex(index);
    }

    @Override
    public IRubyObject getAttributeByName(IRubyObject name){
        return this.node.getAttributeByName(name);
    }

    @Override
    public IRubyObject getAttributeCount(){
        return ruby.newFixnum(0);
    }

    @Override
    public IRubyObject getAttributesNodes() {
        return this.node.getAttributesNodes();
    }

    @Override
    public IRubyObject getDepth() {
        return this.node.getDepth();
    }

    @Override
    public IRubyObject getLang() {
        return this.node.getLang();
    }

    @Override
    public IRubyObject getLocalName() {
        return this.node.getLocalName();
    }

    @Override
    public IRubyObject getName() {
        return this.node.getName();
    }
    
    @Override
    public IRubyObject getNamespaces() {
        return this.node.getNamespaces();
    }

    @Override
    public IRubyObject getPrefix() {
        return this.node.getPrefix();
    }

    @Override
    public IRubyObject getQName() { return this.node.getQName(); }

    @Override
    public IRubyObject getUri() { return this.node.getUri(); }

    @Override
    public IRubyObject getValue() { return this.node.getValue(); }

    @Override
    public RubyBoolean hasValue() { return this.node.hasValue(); };

    @Override
    public RubyBoolean isDefault() { return this.node.isDefault(); }

    @Override
    public boolean isError() { return this.node.isError(); }
}
class ElementNode extends ReaderNode {

    public ElementNode(Ruby ruby, String uri, String localName, String qName, Attributes attrs, int depth) {
        this.ruby = ruby;
        this.uri = toRubyString(uri);
        this.localName = toRubyString(localName);
        this.qName = toRubyString(qName);
        this.prefix = parsePrefix(qName);
        this.depth = ruby.newFixnum(depth);
        parseAttrs(attrs); // I don't know what to do with you yet, my friend.
    }

    @Override
    public RubyBoolean hasValue() {
        return ruby.getFalse();
    }

    private void parseAttrs(Attributes attrs) {
        List<IRubyObject> arr = new ArrayList<IRubyObject>();
        Hashtable<IRubyObject,IRubyObject> hash = new Hashtable<IRubyObject,IRubyObject>();

        this.attributes = new Hashtable<IRubyObject, IRubyObject>();
        this.attributeValues = new IRubyObject[attrs.getLength()];

        ThreadContext context = this.ruby.getCurrentContext();

        DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
        Document doc = null;
        try{
            DocumentBuilder db = dbf.newDocumentBuilder();
            doc = db.newDocument();
        } catch (Exception ex) {
            throw ruby.newRuntimeError(ex.getMessage());
        }

        for(int i = 0; i < attrs.getLength(); i++){
            String n = attrs.getQName(i);
            String v = attrs.getValue(i);
            RubyString attrName = ruby.newString(n);
            RubyString attrValue = ruby.newString(v);

            this.attributeValues[i] = attrValue;
            this.attributes.put(attrName, attrValue);
            
            if(isNamespace(attrs.getQName(i))){
                hash.put(attrName, attrValue);
            } else {
                Attr attr = doc.createAttribute(n);
                attr.setValue(v);
                arr.add(new XmlAttr(ruby, attr));
            }
        }
        this.attrs = ruby.newArray(arr);
        this.namespaces = hash.isEmpty() ? ruby.getNil() : RubyHash.newHash(ruby, hash, ruby.getNil());
    }

    private boolean isNamespace(String qName) {
        return qName.startsWith("xmlns:");
    }

}
class EmptyNode extends ReaderNode {

    public EmptyNode(Ruby ruby) {
        this.ruby = ruby;
    }

    @Override
    public IRubyObject getXmlVersion() { return this.ruby.getNil(); }

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

    public TextNode(Ruby ruby, String content, int depth) {
        this.ruby = ruby;
        this.value = toRubyString(content);
        this.localName = toRubyString("#text");
        this.qName = toRubyString("#text");
        this.depth = ruby.newFixnum(depth);
    }

    @Override
    public RubyBoolean hasValue() {
        return ruby.getTrue();
    }
}