package nokogiri;

import java.io.IOException;
import javax.xml.parsers.ParserConfigurationException;
import nokogiri.internals.HtmlDomParserContext;
import nokogiri.internals.SaveContext;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.Arity;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.w3c.dom.DocumentType;
import org.xml.sax.SAXException;

public class HtmlDocument extends XmlDocument {

    public HtmlDocument(Ruby ruby, RubyClass klazz, Document doc) {
        super(ruby, klazz, doc);
    }

    @JRubyMethod(name="new", meta = true, rest = true, required=0)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject cls,
                                    IRubyObject[] args) {
        HtmlDocument doc = null;
        try {
            Document docNode = createNewDocument();
            doc = new HtmlDocument(context.getRuntime(), (RubyClass) cls,
                                   docNode);
        } catch (Exception ex) {
            throw context.getRuntime()
                .newRuntimeError("couldn't create document: "+ex.toString());
        }

        RuntimeHelpers.invoke(context, doc, "initialize", args);

        return doc;
    }

    public static IRubyObject do_parse(ThreadContext context,
                                       IRubyObject klass,
                                       IRubyObject[] args) {
        Ruby ruby = context.getRuntime();
        Arity.checkArgumentCount(ruby, args, 4, 4);
        HtmlDomParserContext ctx =
            new HtmlDomParserContext(ruby, args[3]);
        ctx.setInputSource(context, args[0]);
        return ctx.parse(context, klass, args[1]);
    }

    @JRubyMethod(meta = true, rest = true)
    public static IRubyObject read_io(ThreadContext context,
                                      IRubyObject cls,
                                      IRubyObject[] args) {
        return do_parse(context, cls, args);
    }

    @JRubyMethod(meta = true, rest = true)
    public static IRubyObject read_memory(ThreadContext context,
                                          IRubyObject cls,
                                          IRubyObject[] args) {
        return do_parse(context, cls, args);
    }


    @JRubyMethod
    public static IRubyObject serialize(ThreadContext context, IRubyObject htmlDoc) {
        throw context.getRuntime().newNotImplementedError("not implemented");
    }

    @Override
    public void saveContent(ThreadContext context, SaveContext ctx) {
        Document doc = getDocument();
        DocumentType dtd = doc.getDoctype();

        if(dtd != null) {
            ctx.append("<!DOCTYPE ");
            ctx.append(dtd.getName());
            if(dtd.getPublicId() != null) {
                ctx.append(" PUBLIC ");
                ctx.appendQuoted(dtd.getPublicId());
                if(dtd.getSystemId() != null) {
                    ctx.append(" ");
                    ctx.appendQuoted(dtd.getSystemId());
                }
            } else if(dtd.getSystemId() != null) {
                ctx.append(" SYSTEM ");
                ctx.appendQuoted(dtd.getSystemId());
            }
            ctx.append(">\n");
        }

        this.saveNodeListContent(context,
                (XmlNodeSet) this.children(context), ctx);
        ctx.append("\n");
    }
}
