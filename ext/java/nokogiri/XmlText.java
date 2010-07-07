package nokogiri;

import static nokogiri.internals.NokogiriHelpers.isXmlEscaped;
import static nokogiri.internals.NokogiriHelpers.rubyStringToString;
import nokogiri.internals.NokogiriHelpers;
import nokogiri.internals.SaveContext;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.Text;

@JRubyClass(name="Nokogiri::XML::Text", parent="Nokogiri::XML::CharacterData")
public class XmlText extends XmlNode {
    public XmlText(Ruby ruby, RubyClass rubyClass, Node node) {
        super(ruby, rubyClass, node);
    }

    public XmlText(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }

    @Override
    protected void init(ThreadContext context, IRubyObject[] args) {
        if (args.length < 2) {
            throw getRuntime().newArgumentError(args.length, 2);
        }

        content = args[0];
        IRubyObject xNode = args[1];

        XmlNode xmlNode = asXmlNode(context, xNode);
        XmlDocument xmlDoc = (XmlDocument)xmlNode.document(context);
        doc = xmlDoc;
        Document document = xmlDoc.getDocument();
        // text node content should not be encoded when it is created by Text node.
        // while content should be encoded when it is created by Element node.
        Node node = document.createTextNode((String)content.toJava(String.class));
        setNode(node);
    }
    
    @Override
    protected IRubyObject getNodeName(ThreadContext context) {
        return JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), "text");
    }
    
    @Override
    @JRubyMethod(name = {"content", "text", "inner_text"})
    public IRubyObject content(ThreadContext context) {
        if (content != null) return content;
        String text = null;
        if (node != null) {
            text = ((Text)node).getWholeText();
        }
        return NokogiriHelpers.stringOrNil(context.getRuntime(), text);
    }

    @Override
    public void saveContent(ThreadContext context, SaveContext ctx) {
        if (isXmlEscaped(node.getTextContent())) {
            ctx.append(rubyStringToString(content(context)));
        } else {             
            ctx.append(rubyStringToString(encode_special_chars(context, content(context))));
        }
    }
}
