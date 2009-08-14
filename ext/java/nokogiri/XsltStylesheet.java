package nokogiri;

import javax.xml.transform.Templates;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMResult;
import javax.xml.transform.dom.DOMSource;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;

public class XsltStylesheet extends RubyObject {

    private Templates sheet;

    public XsltStylesheet(Ruby ruby, RubyClass rubyClass) {
        super(ruby, rubyClass);
    }

    private void addParametersToTransformer(ThreadContext context, Transformer transf, IRubyObject parameters) {
        Ruby ruby = context.getRuntime();
        RubyArray params = parameters.convertToArray();
        int limit = params.getLength();
        if(limit % 2 == 1) limit--;

        for(int i = 0; i < limit; i+=2) {
            String name = params.aref(ruby.newFixnum(i)).asJavaString();
            String value = params.aref(ruby.newFixnum(i+1)).asJavaString();
            transf.setParameter(name, unparseValue(value));
        }
    }

    private String unparseValue(String orig) {
        if(orig.startsWith("\"") && orig.endsWith("\"")) {
            orig = orig.substring(1, orig.length()-1);
        }

        return orig;
    }

    @JRubyMethod(meta = true)
    public static IRubyObject parse_stylesheet_doc(ThreadContext context, IRubyObject cls, IRubyObject document) {
        
        Ruby ruby = context.getRuntime();

        if(!(document instanceof XmlDocument)) {
            throw ruby.newArgumentError("doc must be a Nokogiri::XML::Document instance");
        }

        XmlDocument xmlDoc = (XmlDocument) document;

        RubyArray errors = (RubyArray) xmlDoc.getInstanceVariable("@errors");

        if(!errors.isEmpty()) {
            throw ruby.newRuntimeError(errors.first().asJavaString());
        }
        
        Document doc = ((XmlDocument) xmlDoc.dup_implementation(context, true)).getDocument();

        XsltStylesheet xslt = new XsltStylesheet(ruby, (RubyClass) cls);
        try {
            xslt.sheet = TransformerFactory.newInstance().newTemplates(new DOMSource(doc));
        } catch (TransformerConfigurationException ex) {
            ruby.newRuntimeError("could not parse xslt stylesheet");
        }

        return xslt;
    }

    @JRubyMethod
    public IRubyObject serialize(ThreadContext context, IRubyObject doc) {
        return RuntimeHelpers.invoke(context,
                RuntimeHelpers.invoke(context, doc, "root"),
                "to_s");
    }

    @JRubyMethod(rest = true, required=1, optional=2)
    public IRubyObject transform(ThreadContext context, IRubyObject[] args) {
        Ruby ruby = context.getRuntime();

        DOMSource docSource = new DOMSource(((XmlDocument) args[0]).getDocument());
        DOMResult result = new DOMResult();

        try{
            Transformer transf = this.sheet.newTransformer();
            if(args.length > 1) {
                addParametersToTransformer(context, transf, args[1]);
            }
            transf.transform(docSource, result);
        } catch(TransformerConfigurationException ex) {
            throw ruby.newRuntimeError("Could not transform the document.");
        } catch(TransformerException ex) {
            throw ruby.newRuntimeError("Could not transform the document.");
        }

        return new XmlDocument(ruby,
                (RubyClass) ruby.getClassFromPath("Nokogiri::XML::Document"),
                (Document) result.getNode());
    }
}