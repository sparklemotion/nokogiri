package nokogiri;

import nokogiri.internals.SaveContext;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.w3c.dom.Node;

public class XmlComment extends XmlNode {
    public XmlComment(Ruby ruby, RubyClass rubyClass, Node node) {
        super(ruby, rubyClass, node);
    }

    @JRubyMethod(name = "new", meta = true)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject doc, IRubyObject text) {
        XmlDocument xmlDoc = (XmlDocument)doc;
        Document document = xmlDoc.getDocument();
        Node node = document.createComment(text.convertToString().asJavaString());
        return new XmlComment(context.getRuntime(), (RubyClass) cls, node);
    }

    @Override
    public boolean isComment() { return true; }

    @Override
    public void saveContent(ThreadContext context, SaveContext ctx) {
        ctx.append("<!--");
        ctx.append(content(context).convertToString().asJavaString());
        ctx.append("-->");
    }
}
