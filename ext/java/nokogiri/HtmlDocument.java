package nokogiri;

import java.io.IOException;
import javax.xml.parsers.ParserConfigurationException;
import nokogiri.internals.HtmlDocumentImpl;
import nokogiri.internals.HtmlEmptyDocumentImpl;
import nokogiri.internals.HtmlParseOptions;
import nokogiri.internals.ParseOptions;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.Arity;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.xml.sax.SAXException;

public class HtmlDocument extends XmlDocument {

    public HtmlDocument(Ruby ruby, RubyClass klazz, Document doc) {
        super(ruby, klazz, doc);
        this.document = doc;
        this.internalNode = new HtmlDocumentImpl(ruby, doc);
    }

    @JRubyMethod(name="new", meta = true, rest = true, required=0)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject[] args) {
        HtmlDocument doc = null;
        try {

            /*
             * A little explanation:
             * I'm using an XmlDocument instead of a HTMLDocumentImpl in order
             * not to have capitalized node names.
             */

            Document docNode = (new ParseOptions(0)).getDocumentBuilder().newDocument();

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

        IRubyObject content = RuntimeHelpers.invoke(context, args[0], "read");
        args[0] = content;

        return read_memory(context, cls, args);
    }

    @JRubyMethod(meta = true, rest = true)
    public static IRubyObject read_memory(ThreadContext context, IRubyObject cls, IRubyObject[] args) {
        
        Ruby ruby = context.getRuntime();
        Arity.checkArgumentCount(ruby, args, 4, 4);
        ParseOptions options = new HtmlParseOptions(args[3]);
        try {
            Document document;
            document = options.parse(args[0].convertToString().asJavaString());
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