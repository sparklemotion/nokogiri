package nokogiri;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import javax.xml.parsers.ParserConfigurationException;
import nokogiri.internals.HtmlDocumentImpl;
import nokogiri.internals.HtmlEmptyDocumentImpl;
import nokogiri.internals.HtmlParseOptions;
import nokogiri.internals.ParseOptions;
import org.apache.html.dom.HTMLDocumentImpl;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyIO;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.Arity;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;
import org.w3c.dom.Document;
import org.xml.sax.SAXException;

public class HtmlDocument extends XmlDocument {

    public HtmlDocument(Ruby ruby, RubyClass klazz, Document doc) {
        super(ruby, klazz, doc);
        this.internalNode = new HtmlDocumentImpl(ruby, doc);
    }

    @JRubyMethod(name="new", meta = true, rest = true, required=0)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject[] args) {
        HtmlDocument doc = null;
        try {

            HTMLDocumentImpl docNode = new HTMLDocumentImpl();

            doc = new HtmlDocument(context.getRuntime(), (RubyClass) cls,
                    docNode);
            doc.internalNode = new HtmlEmptyDocumentImpl(context.getRuntime(),
                    docNode);
        } catch (Exception ex) {
            throw context.getRuntime().newRuntimeError("couldn't create document: "+ex.toString());
        }

        RuntimeHelpers.invoke(context, doc, "initialize", args);

        return doc;
    }

    @JRubyMethod(meta = true, rest = true)
    public static IRubyObject read_io(ThreadContext context, IRubyObject cls, IRubyObject[] args) {
        Ruby ruby = context.getRuntime();
        Arity.checkArgumentCount(ruby, args, 4, 4);
        ParseOptions options = new HtmlParseOptions(args[3]);
        try {
            Document document;
            if (args[0] instanceof RubyIO) {
                RubyIO io = (RubyIO)args[0];
                document = options.parse(io.getInStream());
                HtmlDocument doc = new HtmlDocument(ruby, (RubyClass)cls, document);
                doc.setUrl(args[1]);
                options.addErrorsIfNecessary(context, doc);
                return doc;
            } else {
                throw ruby.newTypeError("Only IO supported for Document.read_io currently");
            }
        } catch (ParserConfigurationException pce) {
            return options.getDocumentWithErrorsOrRaiseException(context, pce);
        } catch (SAXException saxe) {
            return options.getDocumentWithErrorsOrRaiseException(context, saxe);
        } catch (IOException ioe) {
            return options.getDocumentWithErrorsOrRaiseException(context, ioe);
        }
    }

    @JRubyMethod(meta = true, rest = true)
    public static IRubyObject read_memory(ThreadContext context, IRubyObject cls, IRubyObject[] args) {
        Ruby ruby = context.getRuntime();
        Arity.checkArgumentCount(ruby, args, 4, 4);
        ParseOptions options = new HtmlParseOptions(args[3]);
        try {
            Document document;
            RubyString content = args[0].convertToString();
            ByteList byteList = content.getByteList();
            ByteArrayInputStream bais = new ByteArrayInputStream(byteList.unsafeBytes(), byteList.begin(), byteList.length());
            document = options.getDocumentBuilder().parse(bais);
            HtmlDocument doc = new HtmlDocument(ruby, (RubyClass)cls, document);
            doc.setUrl(args[1]);
            options.addErrorsIfNecessary(context, doc);
            return doc;
        } catch (ParserConfigurationException pce) {
            return options.getDocumentWithErrorsOrRaiseException(context, pce);
        } catch (SAXException saxe) {
            return options.getDocumentWithErrorsOrRaiseException(context, saxe);
        } catch (IOException ioe) {
            return options.getDocumentWithErrorsOrRaiseException(context, ioe);
        }
    }

    @JRubyMethod
    public static IRubyObject serialize(ThreadContext context, IRubyObject htmlDoc) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }
}