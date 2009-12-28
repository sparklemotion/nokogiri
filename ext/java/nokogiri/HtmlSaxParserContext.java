package nokogiri;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.StringReader;
import nokogiri.internals.NokogiriHandler;
import org.cyberneko.html.parsers.SAXParser;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.ext.DefaultHandler2;

import static org.jruby.javasupport.util.RuntimeHelpers.invoke;

public class HtmlSaxParserContext extends XmlSaxParserContext {
    private SAXParser parser;
    private InputSource source;

    public HtmlSaxParserContext(Ruby ruby, RubyClass rubyClass) {
        super(ruby, rubyClass);

        
		this.parser = new SAXParser();

		try{
			this.parser.setProperty("http://cyberneko.org/html/properties/names/elems", "match");
			this.parser.setProperty("http://cyberneko.org/html/properties/names/attrs", "no-change");
		} catch(Exception ex) {
			System.out.println("Problem while creating HTML SAX Parser: "+ex.toString());
		}
        
    }

    @JRubyMethod(name="memory", meta=true)
    public static IRubyObject parse_memory(ThreadContext context, IRubyObject klazz, IRubyObject data, IRubyObject encoding) {
        String input = data.convertToString().asJavaString();

		HtmlSaxParserContext ctx = new HtmlSaxParserContext(context.getRuntime(), (RubyClass) klazz);

		ctx.source = new InputSource(new StringReader(input));

		return ctx;
    }

    @JRubyMethod(name="file", meta=true)
    public static IRubyObject parse_file(ThreadContext context, IRubyObject klazz, IRubyObject data, IRubyObject encoding) {
        String file = data.convertToString().asJavaString();

		HtmlSaxParserContext ctx = new HtmlSaxParserContext(context.getRuntime(), (RubyClass) klazz);

		try {
		    ctx.source = new InputSource(new FileInputStream(file));
	    } catch (FileNotFoundException ex) {}

        return data;
    }

	@JRubyMethod()
	public IRubyObject parse_with(ThreadContext context, IRubyObject handlerRuby) {
		Ruby ruby = context.getRuntime();

		if(!invoke(context, handlerRuby, "kind_of?",
				ruby.getClassFromPath("Nokogiri::XML::SAX::Parser")).isTrue()) {
			throw ruby.newArgumentError("argument must be a Nokogiri::XML::SAX::Parser");
		}

		DefaultHandler2 handler = new NokogiriHandler(ruby, handlerRuby);

		this.parser.setContentHandler(handler);
		this.parser.setErrorHandler(handler);

		try{
			this.parser.setProperty("http://xml.org/sax/properties/lexical-handler", handler);
		} catch(Exception ex) {
			System.out.println("Problem while creating HTML SAX Parser: "+ex.toString());
		}

		try{
			this.parser.parse(this.source);
		} catch(SAXException se) {
			throw RaiseException.createNativeRaiseException(ruby, se);
		} catch(IOException ioe) {
			throw ruby.newIOErrorFromException(ioe);
		}

		return this;
	}
}
