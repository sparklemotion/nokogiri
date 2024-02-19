package nokogiri;

import nokogiri.internals.*;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.Helpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.xml.sax.SAXException;

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
public class XmlSaxParserContext extends SaxParserContext<XmlSaxParser>
{
  private static final long serialVersionUID = 1L;

  protected static final String FEATURE_NAMESPACES =
    "http://xml.org/sax/features/namespaces";
  protected static final String FEATURE_NAMESPACE_PREFIXES =
    "http://xml.org/sax/features/namespace-prefixes";
  protected static final String FEATURE_LOAD_EXTERNAL_DTD =
    "http://apache.org/xml/features/nonvalidating/load-external-dtd";

  public
  XmlSaxParserContext(final Ruby ruby, RubyClass rubyClass)
  {
    super(ruby, rubyClass);
  }

  private static XmlSaxParserContext
  newInstance(final Ruby runtime, final RubyClass klazz)
  {
    return (XmlSaxParserContext) NokogiriService.XML_SAXPARSER_CONTEXT_ALLOCATOR.allocate(runtime, klazz);
  }

  protected XmlSaxParser
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
  @JRubyMethod(name = "memory", meta = true)
  public static IRubyObject
  parse_memory(ThreadContext context,
               IRubyObject klazz,
               IRubyObject data)
  {
    final Ruby runtime = context.runtime;
    XmlSaxParserContext ctx = newInstance(runtime, (RubyClass) klazz);
    ctx.initialize(runtime);
    ctx.setStringInputSource(context, data, runtime.getNil());
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
  @JRubyMethod(name = "io", meta = true)
  public static IRubyObject
  parse_io(ThreadContext context,
           IRubyObject klazz,
           IRubyObject data,
           IRubyObject encoding)
  {
    // check the type of the unused encoding to match behavior of CRuby
    if (!(encoding instanceof RubyFixnum)) {
      throw context.getRuntime().newTypeError("encoding must be kind_of String");
    }
    final Ruby runtime = context.runtime;
    XmlSaxParserContext ctx = newInstance(runtime, (RubyClass) klazz);
    ctx.initialize(runtime);
    ctx.setIOInputSource(context, data, runtime.getNil());
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

  protected Options
  defaultParseOptions(ThreadContext context)
  {
    return new ParserContext.Options(
             RubyFixnum.fix2long(Helpers.invoke(context,
                                 ((RubyClass)context.getRuntime().getClassFromPath("Nokogiri::XML::ParseOptions"))
                                 .getConstant("DEFAULT_XML"),
                                 "to_i"))
           );
  }

  protected void
  parseSetup(ThreadContext context, IRubyObject rubyParser)
  {
    parser.setXmlDeclHandler(handler);

    if (recovery) {
      try {
        parser.setFeature(FEATURE_CONTINUE_AFTER_FATAL_ERROR, true);
      } catch (SAXException e) {
        throw context.runtime.newRuntimeError(e.getMessage());
      }
    }
  }

  @JRubyMethod
  public IRubyObject
  parse_with(ThreadContext context, IRubyObject rubyParser)
  {
    return super.parse_with(context, rubyParser);
  }

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
