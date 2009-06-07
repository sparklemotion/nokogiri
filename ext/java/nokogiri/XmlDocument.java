package nokogiri;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyIO;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.Arity;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;
import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.bootstrap.DOMImplementationRegistry;
import org.xml.sax.EntityResolver;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

public class XmlDocument extends XmlNode {
    private Document document;
    private static boolean substituteEntities = false;
    private static boolean loadExternalSubset = false; // TODO: Verify this.

    IRubyObject root;

    public XmlDocument(Ruby ruby, RubyClass klass, Document document) {
        super(ruby, klass, document);
        this.document = document;

        setInstanceVariable("@decorators", ruby.getNil());
    }

    public Document getDocument() {
        return document;
    }
    
    

    @JRubyMethod(meta = true, rest = true)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject[] args) {
        XmlDocument doc = null;
        try {
            doc = new XmlDocument(context.getRuntime(), (RubyClass) cls,
                       DOMImplementationRegistry.newInstance().getDOMImplementation("XML 1.0").createDocument(null, null, null));
        } catch (Exception ex) {
            throw context.getRuntime().newRuntimeError("couldn't create document");
        }

        return doc;
    }

    @JRubyMethod(meta = true)
    public static IRubyObject load_external_subsets_set(ThreadContext context, IRubyObject cls, IRubyObject value) {
        XmlDocument.loadExternalSubset = value.isTrue();
        return context.getRuntime().getNil();
    }

    @JRubyMethod(meta = true, rest = true)
    public static IRubyObject read_io(ThreadContext context, IRubyObject cls, IRubyObject[] args) {
        Ruby ruby = context.getRuntime();
        Arity.checkArgumentCount(ruby, args, 4, 4);
        try {
            Document document;
            if (args[0] instanceof RubyIO) {
                RubyIO io = (RubyIO)args[0];
                DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
                dbf.setNamespaceAware(true);
                DocumentBuilder db = dbf.newDocumentBuilder();
                db.setEntityResolver(new EntityResolver() {
                    public InputSource resolveEntity(String arg0, String arg1) throws SAXException, IOException {
                        return new InputSource(new ByteArrayInputStream(new byte[0]));
                    }
                });
                document = db.parse(io.getInStream());
                return new XmlDocument(ruby, (RubyClass)cls, document);
            } else {
                throw ruby.newTypeError("Only IO supported for Document.read_io currently");
            }
        } catch (ParserConfigurationException pce) {
            throw RaiseException.createNativeRaiseException(ruby, pce);
        } catch (SAXException saxe) {
            throw RaiseException.createNativeRaiseException(ruby, saxe);
        } catch (IOException ioe) {
            throw RaiseException.createNativeRaiseException(ruby, ioe);
        }
    }

    @JRubyMethod(meta = true, rest = true)
    public static IRubyObject read_memory(ThreadContext context, IRubyObject cls, IRubyObject[] args) {
        Ruby ruby = context.getRuntime();
        Arity.checkArgumentCount(ruby, args, 4, 4);
        try {
            Document document;
            RubyString content = args[0].convertToString();
            ByteList byteList = content.getByteList();
            ByteArrayInputStream bais = new ByteArrayInputStream(byteList.unsafeBytes(), byteList.begin(), byteList.length());
            DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
            dbf.setNamespaceAware(true);
            DocumentBuilder db = dbf.newDocumentBuilder();
            db.setEntityResolver(new EntityResolver() {
                public InputSource resolveEntity(String arg0, String arg1) throws SAXException, IOException {
                    return new InputSource(new ByteArrayInputStream(new byte[0]));
                }
            });
            document = db.parse(bais);
            return new XmlDocument(ruby, (RubyClass)cls, document);
        } catch (ParserConfigurationException pce) {
            throw RaiseException.createNativeRaiseException(ruby, pce);
        } catch (SAXException saxe) {
            throw RaiseException.createNativeRaiseException(ruby, saxe);
        } catch (IOException ioe) {
            throw RaiseException.createNativeRaiseException(ruby, ioe);
        }
    }

    @JRubyMethod
    public IRubyObject root(ThreadContext context) {
        if(this.root == null)
            this.root = XmlNode.constructNode(context.getRuntime(), document.getDocumentElement());
        return root;
    }

    @JRubyMethod
    public IRubyObject root_set(ThreadContext context, IRubyObject root) {
        Node node = XmlNode.getNodeFromXmlNode(context, root);
        document.replaceChild(node, document.getDocumentElement());
        return root;
    }

    @JRubyMethod(meta = true)
    public static IRubyObject substitute_entities_set(ThreadContext context, IRubyObject cls, IRubyObject value) {
        XmlDocument.substituteEntities = value.isTrue();
        return context.getRuntime().getNil();
    }
}