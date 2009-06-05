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
        boolean uriFits = true;
        if(!node().uri.isNil())
            uriFits = node().uri.asJavaString().equals(uri);
        else
            uriFits = uri.equals(uri);
        return  uriFits &&
                node().localName.asJavaString().equals(localName) &&
                node().qName.asJavaString().equals(qName);
    }

    public IRubyObject getAttributeByIndex(IRubyObject index){
        if(index.isNil()) return index;
        
        long i = index.convertToInteger().getLongValue();
        if(i > Integer.MAX_VALUE)
            throw node().ruby.newArgumentError("value too long to be an array index");

        if(node().attributeValues == null){
            return node().ruby.getNil();
        } else if (i<0 || node().attributeValues.length<=i){
            return node().ruby.getNil();
        } else {
            return node().attributeValues[(int) i];
        }
    }

    public IRubyObject getAttributeByName(IRubyObject name){
        if(node().attributes == null)
            return node().ruby.getNil();
        IRubyObject attrValue = node().attributes.get(name);
        return (attrValue == null) ? node().ruby.getNil() : attrValue;
    }

    public IRubyObject getAttributeByName(String name) {
        return this.getAttributeByName(node().ruby.newString(name));
    }

    public IRubyObject getAttributeCount(){
        if(node().attributes == null)
            return node().ruby.newFixnum(0);
        return node().ruby.newFixnum(node().attributes.size());
    }

    public IRubyObject getAttributesNodes() {
        if(node().attrs == null)
            node().attrs = node().ruby.newArray();
        return node().attrs;
    }

    public IRubyObject getDepth() {
        if(node().depth == null)
            node().depth = node().ruby.newFixnum(0);
        return node().depth;
    }

    public IRubyObject getLang() {
        if(node().lang == null)
            node().lang = node().ruby.getNil();
        return node().lang;
    }

    public IRubyObject getLocalName() {
        if(node().localName == null)
            node().localName = node().ruby.getNil();
        return node().localName;
    }

    public IRubyObject getName() {
        if(node().qName == null)
            node().qName = node().ruby.getNil();
        return node().qName;
    }

    public IRubyObject getNamespaces() {
        if(node().namespaces == null)
            node().namespaces = node().ruby.getNil();
        return node().namespaces;
    }

    public IRubyObject getPrefix() {
        if(node().prefix == null)
            node().prefix = node().ruby.getNil();
        return node().prefix;
    }

    public IRubyObject getQName() {
        if(node().qName == null)
            node().qName = node().ruby.getNil();
        return node().qName;
    }

    public IRubyObject getUri() {
        if(node().uri == null)
            node().uri = node().ruby.getNil();
        return node().uri;
    }

    public IRubyObject getValue() {
        if(node().value == null)
            node().value = node().ruby.getNil();
        return node().value;
    }

    public IRubyObject getXmlVersion() {
        if(node().xmlVersion == null)
            node().xmlVersion = node().ruby.newString("1.0");
        return node().xmlVersion;
    }

    public RubyBoolean hasAttributes() {
        if (node().attributes == null)
            return node().ruby.getFalse();
        return node().attributes.isEmpty() ? node().ruby.getFalse() : node().ruby.getTrue();
    }

    public abstract RubyBoolean hasValue();

    public RubyBoolean isDefault(){
        // TODO Implement.
        return node().ruby.getFalse();
    }

    public boolean isError() { return false; }

    protected ReaderNode node() { return this; }

    protected IRubyObject parsePrefix(String qName) {
        int index = qName.indexOf(':');
        if(index != -1)
            return node().ruby.newString(qName.substring(0, index));
        return node().ruby.getNil();
    }

    public void setLang(String lang) {
        node().lang = (lang == null) ? node().ruby.getNil() : node().ruby.newString(lang);
    }

    protected IRubyObject toRubyString(String string) {
        return (string == null) ? node().ruby.newString() : node().ruby.newString(string);
    }

    public IRubyObject toSyntaxError() { return node().ruby.getNil(); }
}



class ClosingNode extends ReaderNode{
    
    ReaderNode node;
    
    public ClosingNode(Ruby ruby, ReaderNode node){
        this.ruby = ruby;
        this.node = node;
    }

    @Override
    public IRubyObject getAttributeCount(){
        return ruby.newFixnum(0);
    }

    @Override
    public RubyBoolean hasValue() {
        return node().hasValue();
    }

    @Override
    protected ReaderNode node() {
        return this.node;
    }
}
class ElementNode extends ReaderNode {

    public ElementNode(Ruby ruby, String uri, String localName, String qName, Attributes attrs, int depth) {
        this.ruby = ruby;
        this.uri = (uri.equals("")) ? ruby.getNil() : toRubyString(uri);
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