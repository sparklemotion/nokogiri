package nokogiri;

import java.io.IOException;
import java.io.StringReader;
import java.util.logging.Level;
import java.util.logging.Logger;
import nokogiri.internals.NokogiriHandler;
import org.cyberneko.html.parsers.SAXParser;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.Visibility;
import org.jruby.runtime.builtin.IRubyObject;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.ext.DefaultHandler2;

public class HtmlSaxParser extends XmlSaxParser {
    private DefaultHandler2 handler;
    private SAXParser parser;

    public HtmlSaxParser(Ruby ruby, RubyClass rubyClass) {
        super(ruby, rubyClass);

        this.handler = new NokogiriHandler(ruby, this);

        
            this.parser = new SAXParser();

            this.parser.setContentHandler(this.handler);
            this.parser.setErrorHandler(this.handler);
            try{
                this.parser.setProperty("http://xml.org/sax/properties/lexical-handler", handler);
                this.parser.setProperty("http://cyberneko.org/html/properties/names/elems", "match");
                this.parser.setProperty("http://cyberneko.org/html/properties/names/attrs", "no-change");
            } catch(Exception ex) {
                System.out.println("Problem while creating HTML SAX Parser: "+ex.toString());
            }
        
    }

    @JRubyMethod(visibility = Visibility.PRIVATE)
    public IRubyObject native_parse_memory(ThreadContext context, IRubyObject self, IRubyObject data, IRubyObject encoding) {
        String input = data.convertToString().asJavaString();
        try {
            this.parser.parse(new InputSource(new StringReader(input)));
        } catch (SAXException se) {
            throw RaiseException.createNativeRaiseException(context.getRuntime(), se);
        } catch (IOException ioe) {
            throw context.getRuntime().newIOErrorFromException(ioe);
        }
        return data;
    }

    @JRubyMethod(visibility = Visibility.PRIVATE)
    public IRubyObject native_parse_file(ThreadContext context, IRubyObject self, IRubyObject data, IRubyObject encoding) {
        String file = data.convertToString().asJavaString();
        try {
            this.parser.parse(file);
        } catch (SAXException se) {
            throw RaiseException.createNativeRaiseException(context.getRuntime(), se);
        } catch (IOException ioe) {
            throw context.getRuntime().newIOErrorFromException(ioe);
        }
        return data;
    }
}
