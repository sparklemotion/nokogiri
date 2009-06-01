package nokogiri;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.util.LinkedList;
import java.util.Queue;
import java.util.Stack;
import org.jruby.Ruby;
import org.jruby.RubyBoolean;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;
import org.xml.sax.Attributes;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.XMLReader;
import org.xml.sax.ext.DefaultHandler2;
import org.xml.sax.helpers.XMLReaderFactory;

public class XmlReader extends RubyObject {

    final Queue<ReaderNode> nodeQueue;
    
    public XmlReader(Ruby ruby, RubyClass rubyClass) {
        super(ruby, rubyClass);
        this.nodeQueue = new LinkedList<ReaderNode>();
        this.nodeQueue.add(ReaderNode.getEmptyNode(ruby));
    }

    private void parseRubyString(ThreadContext context, RubyString content){
        Ruby ruby = context.getRuntime();
        try {
            XMLReader reader = this.createReader(ruby);
            ByteList byteList = content.getByteList();
            ByteArrayInputStream bais = new ByteArrayInputStream(byteList.unsafeBytes(), byteList.begin(), byteList.length());
            reader.parse(new InputSource(bais));
        } catch (IOException ioe) {
            throw RaiseException.createNativeRaiseException(ruby, ioe);
        } catch (SAXException saxe) {
            throw RaiseException.createNativeRaiseException(ruby, saxe);
        }
    }

    public ReaderNode peek() { return this.nodeQueue.peek(); }

    @JRubyMethod
    public IRubyObject attribute(ThreadContext context, IRubyObject name) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod
    public IRubyObject attribute_at(ThreadContext context, IRubyObject index) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod
    public IRubyObject attribute_count(ThreadContext context) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod
    public IRubyObject attributes(ThreadContext context) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod(name = "attributes?")
    public IRubyObject attributes_p(ThreadContext context) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod(name="default?")
    public IRubyObject default_p(ThreadContext context){
        return peek().isDefault();
    }

    @JRubyMethod(meta = true, rest = true)
    public static IRubyObject from_io(ThreadContext context, IRubyObject cls, IRubyObject args[]) {
        // Only to pass the  source test.
        Ruby ruby = context.getRuntime();

        // Not nil allowed!
        if(args[0].isNil()) throw ruby.newArgumentError("io cannot be nil");

        XmlReader r = new XmlReader(ruby, ((RubyModule) ruby.getModule("Nokogiri").getConstant("XML")).getClass("Reader"));
        r.setInstanceVariable("@source", args[0]);
        
        RubyString content = RuntimeHelpers.invoke(context, args[0], "read").convertToString();

        r.parseRubyString(context, content);
        return r;
    }

    @JRubyMethod(meta = true, rest = true)
    public static IRubyObject from_memory(ThreadContext context, IRubyObject cls, IRubyObject args[]) {
        //TODO: Do actual work.
        Ruby ruby = context.getRuntime();
        
        // Not nil allowed!
        if(args[0].isNil()) throw ruby.newArgumentError("string cannot be nil");

        XmlReader r = new XmlReader(ruby, ((RubyModule) ruby.getModule("Nokogiri").getConstant("XML")).getClass("Reader"));
        
        r.parseRubyString(context, args[0].convertToString());

        return r;
    }

    @JRubyMethod
    public IRubyObject read(ThreadContext context) {
        this.nodeQueue.poll();
        return (peek() == null) ? context.getRuntime().getNil() : this;
    }

    @JRubyMethod
    public IRubyObject state(ThreadContext context) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod
    public IRubyObject name(ThreadContext context) {
        return peek().getName();
    }

    @JRubyMethod
    public IRubyObject local_name(ThreadContext context) {
        return peek().getLocalName();
    }

    @JRubyMethod
    public IRubyObject namespace_uri(ThreadContext context) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod
    public IRubyObject prefix(ThreadContext context) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod
    public IRubyObject value(ThreadContext context) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod
    public IRubyObject lang(ThreadContext context) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod
    public IRubyObject xml_version(ThreadContext context) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod
    public IRubyObject encoding(ThreadContext context) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod
    public IRubyObject depth(ThreadContext context) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @JRubyMethod(name = "value?")
    public IRubyObject value_p(ThreadContext context) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    protected XMLReader createReader(final Ruby ruby) {
        DefaultHandler2 handler = new DefaultHandler2() {

            Stack<ReaderNode> nodeStack;

            private void add(ReaderNode node) {
                nodeQueue.add(node);
            }

            private void addToBoth(ReaderNode node) {
                nodeStack.push(node);
                nodeQueue.add(node);
            }

            @Override
            public void characters(char[] chars, int start, int length) {
                add(new ReaderNode(ruby, new String(chars, start, length)));
            }

            @Override
            public void endElement(String uri, String localName, String qName) {
                if (nodeStack.peek().fits(uri, localName, qName)) {
                    nodeQueue.add(nodeStack.pop());
                } else {
                }
            }

            @Override
            public void startDocument() {
                nodeStack = new Stack<ReaderNode>();
            }

            @Override
            public void startElement(String uri, String localName, String qName, Attributes attrs) {
                addToBoth(new ReaderNode(ruby, uri, localName, qName, attrs));
            }
        };
        try {
            XMLReader reader = XMLReaderFactory.createXMLReader();
            reader.setContentHandler(handler);
            reader.setErrorHandler(handler);
            return reader;
        } catch (SAXException saxe) {
            throw RaiseException.createNativeRaiseException(ruby, saxe);
        }
    }

    public static class ReaderNode {

        Ruby ruby;
        RubyString uri, localName, qName, value;
        Attributes attrs;

        public ReaderNode(Ruby ruby, String content) {
            this.ruby = ruby;
            this.uri = ruby.newString();
            this.value = toRubyString(content);
            this.localName = this.qName = toRubyString("#text");
        }

        public ReaderNode(Ruby ruby, String uri, String localName, String qName, Attributes attrs) {
            this.ruby = ruby;
            this.uri = toRubyString(uri);
            this.localName = toRubyString(localName);
            this.qName = toRubyString(qName);
            this.attrs = attrs; // I don't know what to do with you yet, my friend.
        }

        public boolean fits(String uri, String localName, String qName) {
            return this.uri.asJavaString().equals(uri) &&
                    this.localName.asJavaString().equals(localName) &&
                    this.qName.asJavaString().equals(qName);
        }

        public static ReaderNode getEmptyNode(Ruby ruby) {
            return new ReaderNode(ruby, "#empty");
        }

        public RubyString getLocalName() {
            return this.localName;
        }

        public RubyString getName() {
            return this.qName;
        }

        public RubyString getQName() {
            return this.qName;
        }

        public RubyString getUri() {
            return this.uri;
        }

        public RubyString getValue() {
            return this.value;
        }

        public RubyBoolean isDefault(){
            // TODO Implement.
            return ruby.getFalse();
        }

        protected RubyString toRubyString(String string) {
            return (string == null) ? this.ruby.newString() : this.ruby.newString(string);
        }
    }
}