package nokogiri;

import static nokogiri.internals.NokogiriHelpers.isXmlEscaped;
import static nokogiri.internals.NokogiriHelpers.stringOrNil;
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
        setNode(context, node);
    }
    
    @Override
    protected IRubyObject getNodeName(ThreadContext context) {
        return JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), "text");
    }
    
    @Override
    @JRubyMethod(name = {"content", "text", "inner_text"})
    public IRubyObject content(ThreadContext context) {
        if (content == null || content.isNil()) {
            return stringOrNil(context.getRuntime(), node.getTextContent());
        } else {
            return content;
        }
    }

    @Override
    public void saveContent(ThreadContext context, SaveContext ctx) {
        String textContent = node.getTextContent();
        
        if (!isXmlEscaped(textContent)) {        
            textContent = NokogiriHelpers.encodeJavaString(textContent);
        }
        if (getEncoding(context, ctx) == null) {
            textContent = encodeStringToHtmlEntity(textContent);
        }
        ctx.append(textContent);
    }
    
    private String getEncoding(ThreadContext context, SaveContext ctx) {
        String encoding  = ctx.getEncoding();
        if (encoding != null) return encoding;
        XmlDocument xmlDocument = (XmlDocument)document(context);
        IRubyObject ruby_encoding = xmlDocument.encoding(context);
        if (!ruby_encoding.isNil()) {
            encoding = (String)ruby_encoding.toJava(String.class);
        }
        return encoding;
    }
    
    private String encodeStringToHtmlEntity(String text) {
        int last = 126; // = U+007E. No need to encode under U+007E.
        StringBuffer sb = new StringBuffer();
        for (int i=0; i<text.length(); i++) {
            int codePoint = text.codePointAt(i);
            if (codePoint > last) sb.append("&#x" + Integer.toHexString(codePoint) + ";");
            else sb.append(text.charAt(i));
        }
        return new String(sb);
    }
}
