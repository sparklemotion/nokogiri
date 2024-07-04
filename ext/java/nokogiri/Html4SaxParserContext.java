package nokogiri;

import java.io.ByteArrayInputStream;
import java.io.InputStream;

import org.apache.xerces.parsers.AbstractSAXParser;
import net.sourceforge.htmlunit.cyberneko.parsers.SAXParser;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyEncoding;
import org.jruby.RubyFixnum;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.xml.sax.SAXException;

import nokogiri.internals.NokogiriHandler;
import static nokogiri.internals.NokogiriHelpers.rubyStringToString;

import static org.jruby.runtime.Helpers.invoke;

/**
 * Class for Nokogiri::HTML4::SAX::ParserContext.
 *
 * @author serabe
 * @author Patrick Mahoney <pat@polycrystal.org>
 * @author Yoko Harada <yokolet@gmail.com>
 */
@JRubyClass(name = "Nokogiri::HTML4::SAX::ParserContext", parent = "Nokogiri::XML::SAX::ParserContext")
public class Html4SaxParserContext extends XmlSaxParserContext
{
  private static final long serialVersionUID = 1L;

  static Html4SaxParserContext
  newInstance(final Ruby runtime, final RubyClass klazz)
  {
    Html4SaxParserContext instance = new Html4SaxParserContext(runtime, klazz);
    instance.initialize(runtime);
    return instance;
  }

  public
  Html4SaxParserContext(Ruby ruby, RubyClass rubyClass)
  {
    super(ruby, rubyClass);
  }

  @Override
  protected AbstractSAXParser
  createParser() throws SAXException
  {
    SAXParser parser = new SAXParser();

    try {
      parser.setProperty("http://cyberneko.org/html/properties/names/elems", "lower");
      parser.setProperty("http://cyberneko.org/html/properties/names/attrs", "lower");
      parser.setFeature("http://cyberneko.org/html/features/report-errors", true);

      // NekoHTML should not try to guess the encoding based on the meta
      // tags or other information in the document.  This is already
      // handled by the EncodingReader.
      parser.setFeature("http://cyberneko.org/html/features/scanner/ignore-specified-charset", true);
      return parser;
    } catch (SAXException ex) {
      throw new SAXException(
        "Problem while creating HTML4 SAX Parser: " + ex.toString());
    }
  }

  @JRubyMethod(name = "native_memory", meta = true)
  public static IRubyObject
  parse_memory(ThreadContext context, IRubyObject klazz, IRubyObject data, IRubyObject encoding)
  {
    String java_encoding = null;
    if (encoding != context.runtime.getNil()) {
      if (!(encoding instanceof RubyEncoding)) {
        throw context.runtime.newTypeError("encoding must be kind_of Encoding");
      }
      java_encoding = ((RubyEncoding)encoding).toString();
    }

    Html4SaxParserContext ctx = Html4SaxParserContext.newInstance(context.runtime, (RubyClass) klazz);
    ctx.setStringInputSourceNoEnc(context, data, context.runtime.getNil());

    if (java_encoding != null) {
      ctx.getInputSource().setEncoding(java_encoding);
    }

    return ctx;
  }

  @JRubyMethod(name = "native_file", meta = true)
  public static IRubyObject
  parse_file(ThreadContext context, IRubyObject klass, IRubyObject data, IRubyObject encoding)
  {
    String java_encoding = null;
    if (encoding != context.runtime.getNil()) {
      if (!(encoding instanceof RubyEncoding)) {
        throw context.runtime.newTypeError("encoding must be kind_of Encoding");
      }
      java_encoding = ((RubyEncoding)encoding).toString();
    }

    Html4SaxParserContext ctx = Html4SaxParserContext.newInstance(context.runtime, (RubyClass) klass);
    ctx.setInputSourceFile(context, data);

    if (java_encoding != null) {
      ctx.getInputSource().setEncoding(java_encoding);
    }

    return ctx;
  }

  @JRubyMethod(name = "native_io", meta = true)
  public static IRubyObject
  parse_io(ThreadContext context, IRubyObject klazz, IRubyObject data, IRubyObject encoding)
  {
    if (!invoke(context, data, "respond_to?", context.runtime.newSymbol("read")).isTrue()) {
      throw context.runtime.newTypeError("argument expected to respond to :read");
    }

    String java_encoding = null;
    if (encoding != context.runtime.getNil()) {
      if (!(encoding instanceof RubyEncoding)) {
        throw context.runtime.newTypeError("encoding must be kind_of Encoding");
      }
      java_encoding = ((RubyEncoding)encoding).toString();
    }

    Html4SaxParserContext ctx = Html4SaxParserContext.newInstance(context.runtime, (RubyClass) klazz);
    ctx.setIOInputSource(context, data, context.nil);

    if (java_encoding != null) {
      ctx.getInputSource().setEncoding(java_encoding);
    }

    return ctx;
  }

  /**
   * Create a new parser context that will read from a raw input stream.
   * Meant to be run in a separate thread by Html4SaxPushParser.
   */
  static Html4SaxParserContext
  parse_stream(final Ruby runtime, RubyClass klass, InputStream stream)
  {
    Html4SaxParserContext ctx = Html4SaxParserContext.newInstance(runtime, klass);
    ctx.setInputSource(stream);
    return ctx;
  }

  @Override
  protected void
  preParse(final Ruby runtime, IRubyObject handlerRuby, NokogiriHandler handler)
  {
    // this function is meant to be empty.  It overrides the one in XmlSaxParserContext
  }

}
