package nokogiri;

import static nokogiri.internals.NokogiriHelpers.rubyStringToString;
import nokogiri.internals.SaveContext;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.w3c.dom.Node;

@JRubyClass(name="Nokogiri::XML::Comment", parent="Nokogiri::XML::CharacterData")
public class XmlComment extends XmlNode {
    public XmlComment(Ruby ruby, RubyClass rubyClass, Node node) {
        super(ruby, rubyClass, node);
    }

    public XmlComment(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }

    @Override
    protected void init(ThreadContext context, IRubyObject[] args) {
        if (args.length < 2)
            throw getRuntime().newArgumentError(args.length, 2);

        IRubyObject doc = args[0];
        IRubyObject text = args[1];

        XmlDocument xmlDoc = (XmlDocument) doc;
        Document document = xmlDoc.getDocument();
        Node node = document.createComment(rubyStringToString(text));
        setNode(context, node);
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
