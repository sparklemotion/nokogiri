package nokogiri;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.nio.charset.Charset;
import java.nio.charset.IllegalCharsetNameException;
import java.nio.charset.UnsupportedCharsetException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.xerces.parsers.AbstractSAXParser;
import net.sourceforge.htmlunit.cyberneko.parsers.SAXParser;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.xml.sax.SAXException;

import nokogiri.internals.NokogiriHandler;
import static nokogiri.internals.NokogiriHelpers.rubyStringToString;

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
      parser.setProperty(
        "http://cyberneko.org/html/properties/names/elems", "lower");
      parser.setProperty(
        "http://cyberneko.org/html/properties/names/attrs", "lower");

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

  @JRubyMethod(name = "memory", meta = true)
  public static IRubyObject
  parse_memory(ThreadContext context,
               IRubyObject klazz,
               IRubyObject data,
               IRubyObject encoding)
  {
    Html4SaxParserContext ctx = Html4SaxParserContext.newInstance(context.runtime, (RubyClass) klazz);
    String javaEncoding = findEncodingName(context, encoding);
    if (javaEncoding != null) {
      CharSequence input = applyEncoding(rubyStringToString(data.convertToString()), javaEncoding);
      ByteArrayInputStream istream = new ByteArrayInputStream(input.toString().getBytes());
      ctx.setInputSource(istream);
      ctx.getInputSource().setEncoding(javaEncoding);
    }
    return ctx;
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

  private static String
  findEncodingName(final int value)
  {
    EncodingType type = EncodingType.get(value);
    if (type == null) { return null; }
    assert type.value == value;
    return type.name;
  }

  private static String
  findEncodingName(ThreadContext context, IRubyObject encoding)
  {
    String rubyEncoding = null;
    if (encoding instanceof RubyString) {
      rubyEncoding = rubyStringToString((RubyString) encoding);
    } else if (encoding instanceof RubyFixnum) {
      rubyEncoding = findEncodingName(RubyFixnum.fix2int((RubyFixnum) encoding));
    }
    if (rubyEncoding == null) { return null; }
    try {
      return Charset.forName(rubyEncoding).displayName();
    } catch (UnsupportedCharsetException e) {
      throw context.getRuntime().newEncodingCompatibilityError(rubyEncoding + "is not supported");
    } catch (IllegalCharsetNameException e) {
      throw context.getRuntime().newEncodingError(e.getMessage());
    }
  }

  private static final Pattern CHARSET_PATTERN = Pattern.compile("charset(()|\\s)=(()|\\s)([a-z]|-|_|\\d)+",
      Pattern.CASE_INSENSITIVE);

  private static CharSequence
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

  private static boolean
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

  @JRubyMethod(name = "file", meta = true)
  public static IRubyObject
  parse_file(ThreadContext context,
             IRubyObject klass,
             IRubyObject data,
             IRubyObject encoding)
  {
    if (!(data instanceof RubyString)) {
      throw context.getRuntime().newTypeError("data must be kind_of String");
    }
    if (!(encoding instanceof RubyString)) {
      throw context.getRuntime().newTypeError("data must be kind_of String");
    }

    Html4SaxParserContext ctx = Html4SaxParserContext.newInstance(context.runtime, (RubyClass) klass);
    ctx.setInputSourceFile(context, data);
    String javaEncoding = findEncodingName(context, encoding);
    if (javaEncoding != null) {
      ctx.getInputSource().setEncoding(javaEncoding);
    }
    return ctx;
  }

  @JRubyMethod(name = "io", meta = true)
  public static IRubyObject
  parse_io(ThreadContext context,
           IRubyObject klass,
           IRubyObject data,
           IRubyObject encoding)
  {
    if (!(encoding instanceof RubyFixnum)) {
      throw context.getRuntime().newTypeError("encoding must be kind_of String");
    }

    Html4SaxParserContext ctx = Html4SaxParserContext.newInstance(context.runtime, (RubyClass) klass);
    ctx.setIOInputSource(context, data, context.nil);
    String javaEncoding = findEncodingName(context, encoding);
    if (javaEncoding != null) {
      ctx.getInputSource().setEncoding(javaEncoding);
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
