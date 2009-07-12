package nokogiri;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.IOException;
import java.util.LinkedList;
import java.util.Queue;
import java.util.Stack;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;
import org.xml.sax.Attributes;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;
import org.xml.sax.XMLReader;
import org.xml.sax.ext.DefaultHandler2;
import org.xml.sax.helpers.XMLReaderFactory;

public class XmlReader extends RubyObject {

    private static final int XML_TEXTREADER_MODE_INITIAL = 0;
    private static final int XML_TEXTREADER_MODE_INTERACTIVE = 1;
    private static final int XML_TEXTREADER_MODE_ERROR = 2;
    private static final int XML_TEXTREADER_MODE_EOF = 3;
    private static final int XML_TEXTREADER_MODE_CLOSED = 4;
    private static final int XML_TEXTREADER_MODE_READING = 5;

    final Queue<ReaderNode> nodeQueue;
    private int state;
    
    public XmlReader(Ruby ruby, RubyClass rubyClass) {
        super(ruby, rubyClass);
        this.nodeQueue = new LinkedList<ReaderNode>();
        this.nodeQueue.add(ReaderNode.createEmptyNode(ruby));
    }

    private static IRubyObject[] getArgs(IRubyObject[] args) {
        int size = Math.min(args.length, 3);
        IRubyObject[] newArgs = new IRubyObject[size];
        for(int i = 0; i < size; i++)
            newArgs[i] = args[i];
        return newArgs;
    }

    private void parseRubyString(ThreadContext context, RubyString content){
        Ruby ruby = context.getRuntime();
        try {
            this.setState(XML_TEXTREADER_MODE_READING);
            XMLReader reader = this.createReader(ruby);
            ByteList byteList = content.getByteList();
            ByteArrayInputStream bais = new ByteArrayInputStream(byteList.unsafeBytes(), byteList.begin(), byteList.length());
            reader.parse(new InputSource(bais));
            this.setState(XML_TEXTREADER_MODE_CLOSED);
        } catch (SAXParseException spe) {
            this.setState(XML_TEXTREADER_MODE_ERROR);
            this.nodeQueue.add(ReaderNode.createExceptionNode(ruby, spe));
        } catch (IOException ioe) {
            throw RaiseException.createNativeRaiseException(ruby, ioe);
        } catch (SAXException saxe) {
            throw RaiseException.createNativeRaiseException(ruby, saxe);
        }
    }

    private ReaderNode peek() { return this.nodeQueue.peek(); }

    private void setSource(IRubyObject source){
        this.setInstanceVariable("@source", source);
    }

    private void setState(int state) { this.state = state; }

    @JRubyMethod
    public IRubyObject attribute(ThreadContext context, IRubyObject name) {
        return peek().getAttributeByName(name);
    }

    @JRubyMethod
    public IRubyObject attribute_at(ThreadContext context, IRubyObject index) {
        return peek().getAttributeByIndex(index);
    }

    @JRubyMethod
    public IRubyObject attribute_count(ThreadContext context) {
        return peek().getAttributeCount();
    }

    @JRubyMethod
    public IRubyObject attribute_nodes(ThreadContext context) {
        return peek().getAttributesNodes();
    }

    @JRubyMethod(name = "attributes?")
    public IRubyObject attributes_p(ThreadContext context) {
        return peek().hasAttributes();
    }

    @JRubyMethod(name="default?")
    public IRubyObject default_p(ThreadContext context){
        return peek().isDefault();
    }

    @JRubyMethod
    public IRubyObject depth(ThreadContext context) {
        return peek().getDepth();
    }

    @JRubyMethod(meta = true, rest = true)
    public static IRubyObject from_io(ThreadContext context, IRubyObject cls, IRubyObject args[]) {

        // Only to pass the  source test.
        Ruby ruby = context.getRuntime();

        // Not nil allowed!
        if(args[0].isNil()) throw ruby.newArgumentError("io cannot be nil");

        XmlReader r = new XmlReader(ruby, ((RubyModule) ruby.getModule("Nokogiri").getConstant("XML")).getClass("Reader"));

        r.callInit(getArgs(args), Block.NULL_BLOCK);

        r.setSource(args[0]);
        
        RubyString content = RuntimeHelpers.invoke(context, args[0], "read").convertToString();

        r.parseRubyString(context, content);
        return r;
    }

    @JRubyMethod(meta = true, rest = true)
    public static IRubyObject from_memory(ThreadContext context, IRubyObject cls, IRubyObject args[]) {
        Ruby ruby = context.getRuntime();
        
        // Not nil allowed!
        if(args[0].isNil()) throw ruby.newArgumentError("string cannot be nil");

        XmlReader r = new XmlReader(ruby, ((RubyModule) ruby.getModule("Nokogiri").getConstant("XML")).getClass("Reader"));

        r.callInit(getArgs(args), Block.NULL_BLOCK);

        r.setSource(args[0]);

        r.parseRubyString(context, args[0].convertToString());

        return r;
    }

    @JRubyMethod
    public IRubyObject lang(ThreadContext context) {
        return peek().getLang();
    }

    @JRubyMethod
    public IRubyObject local_name(ThreadContext context) {
        return peek().getLocalName();
    }

    @JRubyMethod
    public IRubyObject name(ThreadContext context) {
        return peek().getName();
    }

    @JRubyMethod
    public IRubyObject namespace_uri(ThreadContext context) {
        return peek().getUri();
    }

    @JRubyMethod
    public IRubyObject namespaces(ThreadContext context) {
        return peek().getNamespaces();
    }

    @JRubyMethod
    public IRubyObject prefix(ThreadContext context) {
        return peek().getPrefix();
    }

    @JRubyMethod
    public IRubyObject read(ThreadContext context) {
        this.nodeQueue.poll();
        if(peek() == null) {
            return context.getRuntime().getNil();
        } else if(peek().isError()) {
            RubyArray errors = (RubyArray) this.getInstanceVariable("@errors");
            errors.append(peek().toSyntaxError());

            this.setInstanceVariable("@errors", errors);

            throw new RaiseException((XmlSyntaxError) peek().toSyntaxError());
        } else {
            return this;
        }
    }

    @JRubyMethod
    public IRubyObject state(ThreadContext context) {
        return context.getRuntime().newFixnum(this.state);
    }

    @JRubyMethod
    public IRubyObject value(ThreadContext context) {
        return peek().getValue();
    }

    @JRubyMethod(name = "value?")
    public IRubyObject value_p(ThreadContext context) {
        return peek().hasValue();
    }

    @JRubyMethod
    public IRubyObject xml_version(ThreadContext context) {
        // TODO: Implement it.
        return peek().getXmlVersion();
    }

    protected XMLReader createReader(final Ruby ruby) {
        DefaultHandler2 handler = new DefaultHandler2() {

            Stack<ReaderNode> nodeStack;
            LangStack langStack;
            int depth;

            private void add(ReaderNode node) {
                this.langStack.setLangToNode(node);
                nodeQueue.add(node);
            }

            private void addToBoth(ReaderNode node) {
                add(node);
                nodeStack.push(node);
            }

            @Override
            public void characters(char[] chars, int start, int length) {
                add( ReaderNode.createTextNode(ruby, new String(chars, start, length), depth));

            }

            @Override
            public void endElement(String uri, String localName, String qName) {
                depth--;
                if (nodeStack.peek().fits(uri, localName, qName)) {
                    ReaderNode node = nodeStack.pop().getClosingNode();
                    this.langStack.updateStack(node);
                    nodeQueue.add(node);
                } else {
                }
            }

            @Override
            public void error(SAXParseException ex) throws SAXParseException {
                add(ReaderNode.createExceptionNode(ruby, ex));
                throw ex;
            }

            @Override
            public void fatalError(SAXParseException ex) throws SAXParseException {
                add(ReaderNode.createExceptionNode(ruby, ex));
                throw ex;
            }

            @Override
            public void startDocument() {
                langStack = new LangStack();
                nodeStack = new Stack<ReaderNode>();
                depth = 0;
            }

            @Override
            public void startElement(String uri, String localName, String qName, Attributes attrs) {
                addToBoth( ReaderNode.createElementNode(ruby, uri, localName, qName, attrs, depth));
                depth++;
            }

            @Override
            public void warning(SAXParseException ex) throws SAXParseException {
                add(ReaderNode.createExceptionNode(ruby, ex));
                throw ex;
            }
        };
        try {
            XMLReader reader = XMLReaderFactory.createXMLReader();
            reader.setContentHandler(handler);
            reader.setDTDHandler(handler);
            reader.setErrorHandler(handler);
            reader.setFeature("http://xml.org/sax/features/xmlns-uris", true);
            reader.setFeature("http://xml.org/sax/features/namespace-prefixes", true);
            reader.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);
            return reader;
        } catch (SAXException saxe) {
            throw RaiseException.createNativeRaiseException(ruby, saxe);
        }
    }


}

class LangStack {

    Stack<Integer> depth;
    Stack<String> lang;

    public LangStack(){
        this.depth = new Stack<Integer>();
        this.lang = new Stack<String>();
    }

    private int currentDepth() {
        return (this.depth.empty()) ? 0 : this.depth.peek().intValue();
    }

    private String currentLang() {
        return (this.lang.empty()) ? null : this.lang.peek();
    }

    private void pop() {
        if(!this.depth.empty()) this.depth.pop();
        if(!this.lang.empty()) this.lang.pop();
    }

    public void push(int depth, String lang) {
        this.depth.push(Integer.valueOf(depth));
        this.lang.push(lang);
    }

    public void setLangToNode(ReaderNode node) {
        IRubyObject langString = node.getAttributeByName("xml:lang");

        if(!langString.isNil()){
            this.depth.push(Integer.valueOf((int) node.getDepth().convertToInteger().getLongValue()));
            this.lang.push(langString.convertToString().asJavaString());
        }

        node.setLang(currentLang());
    }

    public void updateStack(ReaderNode node) {
        if(node.getDepth().convertToInteger().getLongValue() == currentDepth()) {
            pop();
        }
    }
}