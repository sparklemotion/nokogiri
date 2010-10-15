package nokogiri;

import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;

import java.io.IOException;
import java.io.StringReader;

import javax.xml.XMLConstants;
import javax.xml.transform.Source;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamSource;
import javax.xml.validation.Schema;
import javax.xml.validation.SchemaFactory;
import javax.xml.validation.Validator;

import nokogiri.internals.SchemaErrorHandler;
import nokogiri.internals.XmlDomParserContext;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.Visibility;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.xml.sax.ErrorHandler;
import org.xml.sax.SAXException;

/**
 *
 * @author sergio
 */
@JRubyClass(name="Nokogiri::XML::Schema")
public class XmlSchema extends RubyObject {

    protected Source source;

    public XmlSchema(Ruby ruby, RubyClass klazz) {
        super(ruby, klazz);
    }

    private Schema getSchema(ThreadContext context) {

        Schema schema = null;

        String uri=XMLConstants.W3C_XML_SCHEMA_NS_URI;

        try {
            schema = SchemaFactory.newInstance(uri).newSchema(source);
        } catch(SAXException ex) {
            throw context.getRuntime().newRuntimeError("Could not parse document: "+ex.getMessage());
        }
        return schema;
    }

    protected static XmlSchema createSchemaWithSource(ThreadContext context, RubyClass klazz, Source source) {
        Ruby ruby = context.getRuntime();
        XmlSchema schema = null;
        if( klazz.ancestors(context).include_p(context,
                getNokogiriClass(ruby, "Nokogiri::XML::RelaxNG")).isTrue()) {
            schema = new XmlRelaxng(ruby, klazz);
        } else {
            schema = new XmlSchema(ruby, klazz);
        }
        schema.source = source;

        schema.setInstanceVariable("@errors", ruby.newEmptyArray());
        return schema;
    }

    @JRubyMethod(meta=true)
    public static IRubyObject from_document(ThreadContext context, IRubyObject klazz, IRubyObject document) {
        XmlDocument doc = ((XmlDocument) ((XmlNode) document).document(context));

        RubyArray errors = (RubyArray) doc.getInstanceVariable("@errors");

        if(!errors.isEmpty()) {
            throw new RaiseException((XmlSyntaxError) errors.first());
        }

        DOMSource source = new DOMSource(doc.getDocument());

        IRubyObject uri = doc.url(context);
        
        if(!uri.isNil()) {
            source.setSystemId(uri.convertToString().asJavaString());
        }

        return createSchemaWithSource(context, (RubyClass) klazz, source);
    }

    @JRubyMethod(meta=true)
    public static IRubyObject read_memory(ThreadContext context, IRubyObject klazz, IRubyObject content) {
        
        String data = content.convertToString().asJavaString();

        return createSchemaWithSource(context, (RubyClass) klazz,
                new StreamSource(new StringReader(data)));
    }

    @JRubyMethod(visibility=Visibility.PRIVATE)
    public IRubyObject validate_document(ThreadContext context, IRubyObject document) {
        return validate_document_or_file(context, (XmlDocument)document);
    }
    
    @JRubyMethod(visibility=Visibility.PRIVATE)
    public IRubyObject validate_file(ThreadContext context, IRubyObject file) {
        Ruby ruby = context.getRuntime();

        XmlDomParserContext ctx = new XmlDomParserContext(ruby, RubyFixnum.newFixnum(ruby, 1L));
        ctx.setInputSource(context, file);
        XmlDocument xmlDocument = ctx.parse(context, getNokogiriClass(ruby, "Nokogiri::XML::Document"), ruby.getNil());
        return validate_document_or_file(context, xmlDocument);
    }
    
    private IRubyObject validate_document_or_file(ThreadContext context, XmlDocument xmlDocument) {
        Document doc = xmlDocument.getDocument();

        DOMSource docSource = new DOMSource(doc);
        Validator validator = getSchema(context).newValidator();

        RubyArray errors = (RubyArray) this.getInstanceVariable("@errors");
        ErrorHandler errorHandler = new SchemaErrorHandler(context.getRuntime(), errors);

        validator.setErrorHandler(errorHandler);

        try {
            validator.validate(docSource);
        } catch(SAXException ex) {
            errors.append(new XmlSyntaxError(context.getRuntime(), ex));
        } catch (IOException ex) {
            throw context.getRuntime().newIOError(ex.getMessage());
        }

        return errors;
    }
}
