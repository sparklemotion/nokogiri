package nokogiri;

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
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
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
public class XmlSchema extends RubyObject {

    protected final String URI = XMLConstants.W3C_XML_SCHEMA_NS_URI;

    protected Schema schema;
    private final SchemaFactory schemaFactory;

    public XmlSchema(Ruby ruby, RubyClass klazz) {
        super(ruby, klazz);
        this.schemaFactory = SchemaFactory.newInstance(this.URI);
    }

    private static XmlSchema createSchemaFromSource(ThreadContext context,
            IRubyObject klazz, Source source) {
        Ruby ruby = context.getRuntime();

        XmlSchema schema = new XmlSchema(ruby, (RubyClass) klazz);

        try {
            schema.schema = schema.schemaFactory.newSchema(source);
        } catch(SAXException ex) {
            throw ruby.newRuntimeError("Could not parse document");
        }

        schema.setInstanceVariable("@errors", ruby.newEmptyArray());

        return schema;
    }

    @JRubyMethod(meta=true)
    public static IRubyObject from_document(ThreadContext context,
            IRubyObject klazz, IRubyObject document) {
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

        return createSchemaFromSource(context, klazz, source);
    }

    @JRubyMethod(meta=true)
    public static IRubyObject read_memory(ThreadContext context,
            IRubyObject klazz, IRubyObject content) {
        
        String data = content.convertToString().asJavaString();

        return createSchemaFromSource(context, klazz,
                new StreamSource(new StringReader(data)));
    }

    @JRubyMethod(visibility=Visibility.PRIVATE)
    public IRubyObject validate_document(ThreadContext context, IRubyObject document) {
        Ruby ruby = context.getRuntime();

        Document doc = ((XmlDocument) document).getDocument();

        DOMSource source = new DOMSource(doc);

        Validator validator = this.schema.newValidator();

        RubyArray errors = (RubyArray) this.getInstanceVariable("@errors");
        ErrorHandler errorHandler = new SchemaErrorHandler(ruby, errors);

        validator.setErrorHandler(errorHandler);

        try{
            validator.validate(source);
        } catch(SAXException ex) {
            errors.append(new XmlSyntaxError(ruby, ex));
        } catch (IOException ex) {
            throw ruby.newIOError(ex.getMessage());
        }

        return errors;
    }



}
