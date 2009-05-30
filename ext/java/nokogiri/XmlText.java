package nokogiri;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.w3c.dom.Node;

public class XmlText extends XmlNode {
    public XmlText(Ruby ruby, RubyClass rubyClass, Node node) {
        super(ruby, rubyClass, node);
    }

    @JRubyMethod(name = "new", meta = true)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject text, IRubyObject doc) {
        XmlDocument xmlDoc = (XmlDocument)doc;
        Document document = xmlDoc.getDocument();
        Node node = document.createTextNode(text.convertToString().asJavaString());
        return XmlNode.constructNode(context.getRuntime(), node);
    }
}
