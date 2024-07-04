package nokogiri;

import nokogiri.internals.*;
import static nokogiri.internals.NokogiriHelpers.rubyStringToString;

import org.apache.xerces.parsers.AbstractSAXParser;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyEncoding;
import org.jruby.RubyFixnum;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.Helpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;

import static org.jruby.runtime.Helpers.invoke;

/**
 * Base class for the SAX parsers.
 *
 * @author Patrick Mahoney <pat@polycrystal.org>
 * @author Yoko Harada <yokolet@gmail.com>
 */
@JRubyClass(name = "Nokogiri::XML::SAX::ParserContext")
public class XmlSaxParserContext extends ParserContext
{
  private static final long serialVersionUID = 1L;

  protected static final String FEATURE_NAMESPACES =
    "http://xml.org/sax/features/namespaces";
  protected static final String FEATURE_NAMESPACE_PREFIXES =
    "http://xml.org/sax/features/namespace-prefixes";
  protected static final String FEATURE_LOAD_EXTERNAL_DTD =
    "http://apache.org/xml/features/nonvalidating/load-external-dtd";
  protected static final String FEATURE_CONTINUE_AFTER_FATAL_ERROR =
    "http://apache.org/xml/features/continue-after-fatal-error";

  protected AbstractSAXParser parser;

  protected NokogiriHandler handler;
  protected NokogiriErrorHandler errorHandler;
  private boolean replaceEntities = false;
  private boolean recovery = false;

  public
  XmlSaxParserContext(final Ruby ruby, RubyClass rubyClass)
  {
    super(ruby, rubyClass);
  }

  protected void
  initialize(Ruby runtime)
  {
    try {
      parser = createParser();
    } catch (SAXException se) {
      // Unexpected failure in XML subsystem
      RaiseException ex = runtime.newRuntimeError(se.toString());
      ex.initCause(se);
      throw ex;
    }
  }

  /**
   * Create and return a copy of this object.
   *
   * @return a clone of this object
   */
  @Override
  public Object
  clone() throws CloneNotSupportedException
  {
    return super.clone();
  }

  protected AbstractSAXParser
  createParser() throws SAXException
  {
    XmlSaxParser parser = new XmlSaxParser();
    parser.setFeature(FEATURE_NAMESPACE_PREFIXES, true);
    parser.setFeature(FEATURE_LOAD_EXTERNAL_DTD, false);
    return parser;
  }

  /**
   * Create a new parser context that will parse the string
   * <code>data</code>.
   */
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

    XmlSaxParserContext ctx = newInstance(context.runtime, (RubyClass) klazz);
    ctx.initialize(context.runtime);
    ctx.setStringInputSourceNoEnc(context, data, context.runtime.getNil());

    if (java_encoding != null) {
      ctx.getInputSource().setEncoding(java_encoding);
    }

    return ctx;
  }

  /**
   * Create a new parser context that will read from the file
   * <code>data</code> and parse.
   */
  @JRubyMethod(name = "native_file", meta = true)
  public static IRubyObject
  parse_file(ThreadContext context, IRubyObject klazz, IRubyObject data, IRubyObject encoding)
  {
    String java_encoding = null;
    if (encoding != context.runtime.getNil()) {
      if (!(encoding instanceof RubyEncoding)) {
        throw context.runtime.newTypeError("encoding must be kind_of Encoding");
      }
      java_encoding = ((RubyEncoding)encoding).toString();
    }

    XmlSaxParserContext ctx = newInstance(context.runtime, (RubyClass) klazz);
    ctx.initialize(context.runtime);
    ctx.setInputSourceFile(context, data);

    if (java_encoding != null) {
      ctx.getInputSource().setEncoding(java_encoding);
    }

    return ctx;
  }

  /**
   * Create a new parser context that will read from the IO or
   * StringIO <code>data</code> and parse.
   *
   * TODO: Currently ignores encoding <code>enc</code>.
   */
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

    XmlSaxParserContext ctx = newInstance(context.runtime, (RubyClass) klazz);
    ctx.initialize(context.runtime);
    ctx.setIOInputSource(context, data, context.runtime.getNil());

    if (java_encoding != null) {
      ctx.getInputSource().setEncoding(java_encoding);
    }

    return ctx;
  }

  /**
   * Create a new parser context that will read from a raw input stream.
   * Meant to be run in a separate thread by XmlSaxPushParser.
   */
  static XmlSaxParserContext
  parse_stream(final Ruby runtime, RubyClass klazz, InputStream stream)
  {
    XmlSaxParserContext ctx = newInstance(runtime, klazz);
    ctx.initialize(runtime);
    ctx.setInputSource(stream);
    return ctx;
  }

  private static XmlSaxParserContext
  newInstance(final Ruby runtime, final RubyClass klazz)
  {
    return (XmlSaxParserContext) NokogiriService.XML_SAXPARSER_CONTEXT_ALLOCATOR.allocate(runtime, klazz);
  }

  public final NokogiriHandler
  getNokogiriHandler() { return handler; }

  public final NokogiriErrorHandler
  getNokogiriErrorHandler() { return errorHandler; }

  /**
   * Perform any initialization prior to parsing with the handler
   * <code>handlerRuby</code>. Convenience hook for subclasses.
   */
  protected void
  preParse(Ruby runtime, IRubyObject handlerRuby, NokogiriHandler handler)
  {
    ((XmlSaxParser) parser).setXmlDeclHandler(handler);
    if (recovery) {
      try {
        parser.setFeature(FEATURE_CONTINUE_AFTER_FATAL_ERROR, true);
      } catch (Exception e) {
        // Unexpected failure in XML subsystem
        throw runtime.newRuntimeError(e.getMessage());
      }
    }
  }

  protected void
  postParse(Ruby runtime, IRubyObject handlerRuby, NokogiriHandler handler)
  {
    // noop
  }

  protected void
  do_parse() throws SAXException, IOException
  {
    parser.parse(getInputSource());
  }

  protected static Options
  defaultParseOptions(ThreadContext context)
  {
    return new ParserContext.Options(
             RubyFixnum.fix2long(Helpers.invoke(context,
                                 ((RubyClass)context.getRuntime().getClassFromPath("Nokogiri::XML::ParseOptions"))
                                 .getConstant("DEFAULT_XML"),
                                 "to_i"))
           );
  }

  @JRubyMethod
  public IRubyObject
  parse_with(ThreadContext context, IRubyObject handlerRuby)
  {
    final Ruby runtime = context.getRuntime();

    if (!invoke(context, handlerRuby, "respond_to?", runtime.newSymbol("document")).isTrue()) {
      throw runtime.newArgumentError("argument must respond_to document");
    }

    /* TODO: how should we pass in parse options? */
    ParserContext.Options options = defaultParseOptions(context);
    if (replaceEntities) {
      options.noEnt = true;
    }

    errorHandler = new NokogiriStrictErrorHandler(runtime, options.noError, options.noWarning);
    handler = new NokogiriHandler(runtime, handlerRuby, errorHandler, options.noEnt);

    preParse(runtime, handlerRuby, handler);
    parser.setContentHandler(handler);
    parser.setErrorHandler(handler);
    parser.setEntityResolver(new NokogiriEntityResolver(runtime, errorHandler, options));

    try {
      parser.setProperty("http://xml.org/sax/properties/lexical-handler", handler);
      parser.setProperty("http://xml.org/sax/properties/declaration-handler", handler);
    } catch (Exception ex) {
      throw runtime.newRuntimeError("Problem while creating XML SAX Parser: " + ex.toString());
    }

    try {
      try {
        do_parse();
      } catch (SAXParseException ex) {
        // An EMPTY document should raise a RuntimeError. This is a bit kludgy, but AFAIK SAX
        // doesn't distinguish between empty and bad whereas Nokogiri does.
        String message = ex.getMessage();
        if (message != null && message.contains("Premature end of file.") && stringDataSize < 1) {
          throw runtime.newRuntimeError("input string cannot be empty");
        }

        // A bad document (<foo><bar></foo>) should call the
        // error handler instead of raising a SAX exception.
        handler.error(ex);
      }
    } catch (SAXException ex) {
      // Unexpected failure in XML subsystem
      throw runtime.newRuntimeError(ex.getMessage());
    } catch (IOException ex) {
      throw runtime.newIOErrorFromException(ex);
    }

    postParse(runtime, handlerRuby, handler);

    return runtime.getNil();
  }

  /**
   * Can take a boolean assignment.
   *
   * @param context
   * @param value
   * @return
   */
  @JRubyMethod(name = "replace_entities=")
  public IRubyObject
  set_replace_entities(ThreadContext context, IRubyObject value)
  {
    replaceEntities = value.isTrue();
    return this;
  }

  @JRubyMethod(name = "replace_entities")
  public IRubyObject
  get_replace_entities(ThreadContext context)
  {
    return context.runtime.newBoolean(replaceEntities);
  }

  /**
   * Can take a boolean assignment.
   *
   * @param context
   * @param value
   * @return
   */
  @JRubyMethod(name = "recovery=")
  public IRubyObject
  set_recovery(ThreadContext context, IRubyObject value)
  {
    recovery = value.isTrue();
    return this;
  }

  @JRubyMethod(name = "recovery")
  public IRubyObject
  get_recovery(ThreadContext context)
  {
    return context.runtime.newBoolean(recovery);
  }

  @JRubyMethod(name = "column")
  public IRubyObject
  column(ThreadContext context)
  {
    final Integer number = handler.getColumn();
    if (number == null) { return context.getRuntime().getNil(); }
    return RubyFixnum.newFixnum(context.getRuntime(), number.longValue());
  }

  @JRubyMethod(name = "line")
  public IRubyObject
  line(ThreadContext context)
  {
    final Integer number = handler.getLine();
    if (number == null) { return context.getRuntime().getNil(); }
    return RubyFixnum.newFixnum(context.getRuntime(), number.longValue());
  }
}
