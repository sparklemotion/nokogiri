package nokogiri;

import java.lang.RuntimeException;
import nokogiri.internals.NokogiriHelpers;
import nokogiri.internals.SaveContext;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.w3c.dom.Node;

import static nokogiri.internals.NokogiriHelpers.rubyStringToString;

public class XmlText extends XmlNode {
    public XmlText(Ruby ruby, RubyClass rubyClass, Node node) {
        super(ruby, rubyClass, node);
    }

    @JRubyMethod(name = "new", meta = true)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject text, IRubyObject xNode) {
        XmlNode xmlNode = asXmlNode(context, xNode);
        XmlDocument xmlDoc = (XmlDocument)xmlNode.document(context);
        Document document = xmlDoc.getDocument();
        String content = rubyStringToString(encode_special_chars(context, text));
        Node node = document.createTextNode(content);
        return new XmlText(context.getRuntime(), (RubyClass) cls, node);
    }


    @Override
    public void saveContent(ThreadContext context, SaveContext ctx) {
        ctx.append(rubyStringToString(content(context)));
    }
}
