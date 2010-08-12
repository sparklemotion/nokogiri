package nokogiri;

import nokogiri.internals.SaveContext;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.CDATASection;
import org.w3c.dom.Document;
import org.w3c.dom.Node;

@JRubyClass(name="Nokogiri::XML::CDATA", parent="Nokogiri::XML::Text")
public class XmlCdata extends XmlText {
    public XmlCdata(Ruby ruby, RubyClass rubyClass) {
        super(ruby, rubyClass);
    }
    
    public XmlCdata(Ruby ruby, RubyClass rubyClass, Node node) {
        super(ruby, rubyClass, node);
    }

    @Override
    protected void init(ThreadContext context, IRubyObject[] args) {
        if (args.length < 2) {
            throw getRuntime().newArgumentError(args.length, 2);
        }
        IRubyObject doc = args[0];
        content = args[1];
        XmlDocument xmlDoc =(XmlDocument) ((XmlNode) doc).document(context);
        doc = xmlDoc;
        Document document = xmlDoc.getDocument();
        Node node = document.createCDATASection((content.isNil()) ? null : (String)content.toJava(String.class));
        setNode(context, node);
    }

    @Override
    public void saveContent(ThreadContext context, SaveContext ctx) {
        CDATASection cdata = (CDATASection) node;

        if(cdata.getData().length() == 0) {
            ctx.append("<![CDATA[]]>");
        } else {
            ctx.append("<![CDATA[");
            ctx.append(cdata.getData());
            ctx.append("]]>");
        }
    }
}
