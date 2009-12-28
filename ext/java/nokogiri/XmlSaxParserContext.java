package nokogiri;

import java.io.ByteArrayInputStream;
import java.io.FileInputStream;
import java.io.IOException;
import nokogiri.internals.NokogiriHandler;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyIO;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.Visibility;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;
import org.jruby.util.TypeConverter;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.XMLReader;
import org.xml.sax.ext.DefaultHandler2;
import org.xml.sax.helpers.XMLReaderFactory;

public class XmlSaxParserContext extends RubyObject {
    private DefaultHandler2 handler;
    private XMLReader reader;

    public XmlSaxParserContext(final Ruby ruby, RubyClass rubyClass) {
        super(ruby, rubyClass);

        handler = new NokogiriHandler(ruby, this);
        try {
            reader = XMLReaderFactory.createXMLReader();
            reader.setContentHandler(handler);
            reader.setErrorHandler(handler);
            reader.setProperty("http://xml.org/sax/properties/lexical-handler", handler);
        } catch (SAXException se) {
            throw RaiseException.createNativeRaiseException(ruby, se);
        }
    }

    @JRubyMethod
    public IRubyObject parse_memory(ThreadContext context, IRubyObject data) {
        try {
            RubyString content = data.convertToString();
            ByteList byteList = content.getByteList();
            ByteArrayInputStream bais = new ByteArrayInputStream(byteList.unsafeBytes(), byteList.begin(), byteList.length());
            reader.parse(new InputSource(bais));
            return data;
        } catch (SAXException se) {
            throw context.getRuntime().newRuntimeError(se.getMessage());
        } catch (IOException ioe) {
            throw context.getRuntime().newIOErrorFromException(ioe);
        }
    }

    @JRubyMethod(visibility = Visibility.PRIVATE)
    public IRubyObject native_parse_file(ThreadContext context, IRubyObject data) {
        try {
            String filename = data.convertToString().asJavaString();
            reader.parse(new InputSource(new FileInputStream(filename)));
            return data;
        } catch (SAXException se) {
            throw context.getRuntime().newRuntimeError(se.getMessage());
        } catch (IOException ioe) {
            throw context.getRuntime().newIOErrorFromException(ioe);
        }
    }

    @JRubyMethod(visibility = Visibility.PRIVATE)
    public IRubyObject native_parse_io(ThreadContext context, IRubyObject data, IRubyObject enc) {
        try {
            int encoding = (int)enc.convertToInteger().getLongValue();
            RubyIO io = (RubyIO)TypeConverter.convertToType(data, getRuntime().getIO(), "to_io");
            reader.parse(new InputSource(io.getInStream()));
            return data;
        } catch (SAXException se) {
            throw context.getRuntime().newRuntimeError(se.getMessage());
        } catch (IOException ioe) {
            throw context.getRuntime().newIOErrorFromException(ioe);
        }
    }
}