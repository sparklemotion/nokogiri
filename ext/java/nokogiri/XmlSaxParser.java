package nokogiri;

import java.io.ByteArrayInputStream;
import java.io.FileInputStream;
import java.io.IOException;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyIO;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.Visibility;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;
import org.jruby.util.TypeConverter;
import org.xml.sax.Attributes;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;
import org.xml.sax.XMLReader;
import org.xml.sax.ext.DefaultHandler2;
import org.xml.sax.helpers.XMLReaderFactory;

public class XmlSaxParser extends RubyObject {
    private DefaultHandler2 handler;
    private XMLReader reader;

    public XmlSaxParser(final Ruby ruby, RubyClass rubyClass) {
        super(ruby, rubyClass);

        final Ruby runtime = ruby;
        handler = new DefaultHandler2() {
            boolean inCDATA = false;

            @Override
            public void startDocument() throws SAXException {
                call("start_document");
            }

            @Override
            public void endDocument() throws SAXException {
                call("end_document");
            }

            @Override
            public void startElement(String uri, String localName, String qName, Attributes attr) throws SAXException {
                RubyArray attrs = RubyArray.newArray(ruby, attr.getLength());
                for (int i = 0; i < attr.getLength(); i++) {
                    attrs.append(ruby.newString(attr.getQName(i)));
                    attrs.append(ruby.newString(attr.getValue(i)));
                }
                call("start_element", ruby.newString(qName), attrs);
            }

            @Override
            public void endElement(String uri, String localName, String qName) throws SAXException {
                call("end_element", ruby.newString(qName));
            }

            @Override
            public void characters(char[] ch, int start, int length) throws SAXException {
                String target = inCDATA ? "cdata_block" : "characters";
                call(target, ruby.newString(new String(ch, start, length)));
            }

            @Override
            public void comment(char[] ch, int start, int length) throws SAXException {
                call("comment", ruby.newString(new String(ch, start, length)));
            }

            @Override
            public void startCDATA() throws SAXException {
                inCDATA = true;
            }

            @Override
            public void endCDATA() throws SAXException {
                inCDATA = false;
            }

            @Override
            public void error(SAXParseException saxpe) {
                call("error", ruby.newString(saxpe.getMessage()));
            }

            @Override
            public void warning(SAXParseException saxpe) {
                call("warning", ruby.newString(saxpe.getMessage()));
            }

            private void call(String methodName) {
                ThreadContext context = runtime.getCurrentContext();
                RuntimeHelpers.invoke(context, document(context), methodName);
            }

            private void call(String methodName, IRubyObject argument) {
                ThreadContext context = runtime.getCurrentContext();
                RuntimeHelpers.invoke(context, document(context), methodName, argument);
            }

            private void call(String methodName, IRubyObject arg1, IRubyObject arg2) {
                ThreadContext context = runtime.getCurrentContext();
                RuntimeHelpers.invoke(context, document(context), methodName, arg1, arg2);
            }
        };
        try {
            reader = XMLReaderFactory.createXMLReader();
            reader.setContentHandler(handler);
            reader.setErrorHandler(handler);
            reader.setProperty("http://xml.org/sax/properties/lexical-handler", handler);
        } catch (SAXException se) {
            throw RaiseException.createNativeRaiseException(runtime, se);
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
            throw RaiseException.createNativeRaiseException(context.getRuntime(), se);
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
            throw RaiseException.createNativeRaiseException(context.getRuntime(), se);
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
            throw RaiseException.createNativeRaiseException(context.getRuntime(), se);
        } catch (IOException ioe) {
            throw context.getRuntime().newIOErrorFromException(ioe);
        }
    }

    private IRubyObject document(ThreadContext context){
        return RuntimeHelpers.invoke(context, this, "document");
    }
}