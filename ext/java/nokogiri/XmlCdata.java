package nokogiri;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.Arity;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.w3c.dom.Node;

public class XmlCdata extends XmlText {
    public XmlCdata(Ruby ruby, RubyClass rubyClass, Node node) {
        super(ruby, rubyClass, node);
    }

    @JRubyMethod(name = "new", meta = true, rest = true, required = 2)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject[] args) {

        IRubyObject doc = args[0], text = args[1];
        XmlDocument xmlDoc =(XmlDocument) ((XmlNode) doc).document(context);
        Document document = xmlDoc.getDocument();
        Node node = document.createCDATASection((text.isNil()) ? null : text.convertToString().asJavaString());
        XmlNode cdata = (XmlNode) XmlNode.constructNode(context.getRuntime(), node);

        RuntimeHelpers.invoke(context, cdata, "initialize", args);

        // TODO: if_block_given.

        return cdata;
    }
}