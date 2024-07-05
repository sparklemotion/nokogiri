package nokogiri;

import nokogiri.internals.*;
import static nokogiri.internals.NokogiriHelpers.rubyStringToString;

import org.apache.xerces.parsers.AbstractSAXParser;
import org.jruby.Ruby;
import org.jruby.RubyClass;
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
import java.nio.charset.Charset;
import java.nio.charset.IllegalCharsetNameException;
import java.nio.charset.UnsupportedCharsetException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

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
  @JRubyMethod(name = "memory", meta = true, required = 1, optional = 1)
  public static IRubyObject
  parse_memory(ThreadContext context,
               IRubyObject klazz,
               IRubyObject[] args)
  {
    IRubyObject data = args[0];
    IRubyObject encoding = null;
    if (args.length > 1) {
      encoding = args[1];
    }

    XmlSaxParserContext ctx = newInstance(context.runtime, (RubyClass) klazz);
    ctx.initialize(context.runtime);
    ctx.setStringInputSource(context, data, context.runtime.getNil());

    /* this overrides the encoding guess made by setStringInputSource */
    String java_encoding = encoding != null ? findEncodingName(context, encoding) : null;
    ctx.getInputSource().setEncoding(java_encoding);

    return ctx;
  }

  /**
   * Create a new parser context that will read from the file
   * <code>data</code> and parse.
   */
  @JRubyMethod(name = "file", meta = true)
  public static IRubyObject
  parse_file(ThreadContext context,
             IRubyObject klazz,
             IRubyObject data)
  {
    final Ruby runtime = context.runtime;
    XmlSaxParserContext ctx = newInstance(runtime, (RubyClass) klazz);
    ctx.initialize(context.getRuntime());
    ctx.setInputSourceFile(context, data);
    return ctx;
  }

  /**
   * Create a new parser context that will read from the IO or
   * StringIO <code>data</code> and parse.
   *
   * TODO: Currently ignores encoding <code>enc</code>.
   */
  @JRubyMethod(name = "io", meta = true, required = 1, optional = 1)
  public static IRubyObject
  parse_io(ThreadContext context,
           IRubyObject klazz,
           IRubyObject[] args)
  {
    IRubyObject data = args[0];
    IRubyObject encoding = null;
    if (args.length > 1) {
      encoding = args[1];
    }

    if (encoding != null && !(encoding instanceof RubyFixnum)) {
      throw context.getRuntime().newTypeError("encoding must be kind_of String");
    }

    final Ruby runtime = context.runtime;
    XmlSaxParserContext ctx = newInstance(runtime, (RubyClass) klazz);
    ctx.initialize(runtime);
    ctx.setIOInputSource(context, data, runtime.getNil());

    /* this overrides the encoding guess made by setIOInputSource */
    String java_encoding = encoding != null ? findEncodingName(context, encoding) : null;
    ctx.getInputSource().setEncoding(java_encoding);

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

  public enum EncodingType {
    NONE(0, "NONE"),
    UTF_8(1, "UTF-8"),
    UTF16LE(2, "UTF16LE"),
    UTF16BE(3, "UTF16BE"),
    UCS4LE(4, "UCS4LE"),
    UCS4BE(5, "UCS4BE"),
    EBCDIC(6, "EBCDIC"),
    UCS4_2143(7, "ICS4-2143"),
    UCS4_3412(8, "UCS4-3412"),
    UCS2(9, "UCS2"),
    ISO_8859_1(10, "ISO-8859-1"),
    ISO_8859_2(11, "ISO-8859-2"),
    ISO_8859_3(12, "ISO-8859-3"),
    ISO_8859_4(13, "ISO-8859-4"),
    ISO_8859_5(14, "ISO-8859-5"),
    ISO_8859_6(15, "ISO-8859-6"),
    ISO_8859_7(16, "ISO-8859-7"),
    ISO_8859_8(17, "ISO-8859-8"),
    ISO_8859_9(18, "ISO-8859-9"),
    ISO_2022_JP(19, "ISO-2022-JP"),
    SHIFT_JIS(20, "SHIFT-JIS"),
    EUC_JP(21, "EUC-JP"),
    ASCII(22, "ASCII");

    private final int value;
    private final String name;

    EncodingType(int value, String name)
    {
      this.value = value;
      this.name = name;
    }

    public int getValue()
    {
      return value;
    }

    public String toString()
    {
      return name;
    }

    private static transient EncodingType[] values;

    // NOTE: assuming ordinal == value
    static EncodingType get(final int ordinal)
    {
      EncodingType[] values = EncodingType.values;
      if (values == null) {
        values = EncodingType.values();
        EncodingType.values = values;
      }
      if (ordinal >= 0 && ordinal < values.length) {
        return values[ordinal];
      }
      return null;
    }

  }

  protected static String
  findEncodingName(final int value)
  {
    EncodingType type = EncodingType.get(value);
    if (type == null) { return null; }
    assert type.value == value;
    return type.name;
  }

  protected static String
  findEncodingName(ThreadContext context, IRubyObject encoding)
  {
    String rubyEncoding = null;
    if (encoding instanceof RubyString) {
      rubyEncoding = rubyStringToString((RubyString) encoding);
    } else if (encoding instanceof RubyFixnum) {
      rubyEncoding = findEncodingName(RubyFixnum.fix2int((RubyFixnum) encoding));
    }
    if (rubyEncoding == null) { return null; }
    if (rubyEncoding.equals("NONE")) { return null; }
    try {
      return Charset.forName(rubyEncoding).displayName();
    } catch (UnsupportedCharsetException e) {
      throw context.getRuntime().newEncodingCompatibilityError(rubyEncoding + " is not supported");
    } catch (IllegalCharsetNameException e) {
      throw context.getRuntime().newEncodingError(e.getMessage());
    }
  }

  protected static final Pattern CHARSET_PATTERN = Pattern.compile("charset(()|\\s)=(()|\\s)([a-z]|-|_|\\d)+",
      Pattern.CASE_INSENSITIVE);

  protected static CharSequence
  applyEncoding(final String input, final String enc)
  {
    int start_pos = 0;
    int end_pos = 0;
    if (containsIgnoreCase(input, "charset")) {
      Matcher m = CHARSET_PATTERN.matcher(input);
      while (m.find()) {
        start_pos = m.start();
        end_pos = m.end();
      }
    }
    if (start_pos != end_pos) {
      return new StringBuilder(input).replace(start_pos, end_pos, "charset=" + enc);
    }
    return input;
  }

  protected static boolean
  containsIgnoreCase(final String str, final String sub)
  {
    final int len = sub.length();
    final int max = str.length() - len;

    if (len == 0) { return true; }
    final char c0Lower = Character.toLowerCase(sub.charAt(0));
    final char c0Upper = Character.toUpperCase(sub.charAt(0));

    for (int i = 0; i <= max; i++) {
      final char ch = str.charAt(i);
      if (ch != c0Lower && Character.toLowerCase(ch) != c0Lower && Character.toUpperCase(ch) != c0Upper) {
        continue; // first char doesn't match
      }

      if (str.regionMatches(true, i + 1, sub, 0 + 1, len - 1)) {
        return true;
      }
    }
    return false;
  }
}
