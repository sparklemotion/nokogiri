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

    public XmlText(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }

    protected void init(ThreadContext context, IRubyObject[] args) {
        if (args.length < 2) {
            throw getRuntime().newArgumentError(args.length, 2);
        }

        IRubyObject text = args[0];
        IRubyObject xNode = args[1];

        XmlNode xmlNode = asXmlNode(context, xNode);
        XmlDocument xmlDoc = (XmlDocument)xmlNode.document(context);
        Document document = xmlDoc.getDocument();
        String content = rubyStringToString(encode_special_chars(context, text));
        Node node = document.createTextNode(content);
        setNode(node);
    }


    @Override
    public void saveContent(ThreadContext context, SaveContext ctx) {
        ctx.append(rubyStringToString(content(context)));
    }
}
