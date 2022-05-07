package nokogiri.internals;

import static nokogiri.internals.NokogiriHelpers.rubyStringToString;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.util.concurrent.Callable;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;
import org.jruby.util.IOInputStream;
import org.xml.sax.InputSource;

/**
 * Base class for the various parser contexts.  Handles converting
 * Ruby objects to InputSource objects.
 *
 * @author Patrick Mahoney <pat@polycrystal.org>
 * @author Yoko Harada <yokolet@gmail.com>
 */
public abstract class ParserContext extends RubyObject
{
  private static final long serialVersionUID = 1L;

  protected InputSource source = null;
  protected IRubyObject detected_encoding = null;
  protected int stringDataSize = -1;
  protected String java_encoding;

  public
  ParserContext(Ruby runtime)
  {
    // default to class 'Object' because this class isn't exposed to Ruby
    super(runtime, runtime.getObject());
  }

  public
  ParserContext(Ruby runtime, RubyClass klass)
  {
    super(runtime, klass);
  }

  protected InputSource
  getInputSource()
  {
    return source;
  }

  public void
  setIOInputSource(ThreadContext context, IRubyObject data, IRubyObject url)
  {
    source = new InputSource();
    ParserContext.setUrl(context, source, url);

    Ruby ruby = context.getRuntime();

    if (!(data.respondsTo("read"))) {
      throw ruby.newTypeError("must respond to :read");
    }

    source.setByteStream(new IOInputStream(data));
    if (java_encoding != null) {
      source.setEncoding(java_encoding);
    }
  }

  public void
  setStringInputSource(ThreadContext context, IRubyObject data, IRubyObject url)
  {
    source = new InputSource();
    ParserContext.setUrl(context, source, url);

    Ruby ruby = context.getRuntime();

    if (!(data instanceof RubyString)) {
      throw ruby.newTypeError("must be kind_of String");
    }

    RubyString stringData = (RubyString) data;

    if (stringData.encoding(context) != null) {
      RubyString stringEncoding = stringData.encoding(context).asString();
      String encName = NokogiriHelpers.getValidEncodingOrNull(stringEncoding);
      if (encName != null) {
        java_encoding = encName;
      }
    }

    ByteList bytes = stringData.getByteList();

    stringDataSize = bytes.length() - bytes.begin();
    ByteArrayInputStream stream = new ByteArrayInputStream(bytes.unsafeBytes(), bytes.begin(), bytes.length());
    source.setByteStream(stream);
    source.setEncoding(java_encoding);
  }

  public static void
  setUrl(ThreadContext context, InputSource source, IRubyObject url)
  {
    String path = rubyStringToString(url);
    // Dir.chdir might be called at some point before this.
    if (path != null) {
      try {
        URI uri = URI.create(path);
        source.setSystemId(uri.toURL().toString());
      } catch (Exception ex) {
        // fallback to the old behavior
        File file = new File(path);
        if (file.isAbsolute()) {
          source.setSystemId(path);
        } else {
          String pwd = context.getRuntime().getCurrentDirectory();
          String absolutePath;
          try {
            absolutePath = new File(pwd, path).getCanonicalPath();
          } catch (IOException e) {
            absolutePath = new File(pwd, path).getAbsolutePath();
          }
          source.setSystemId(absolutePath);
        }
      }
    }
  }

  protected void
  setEncoding(String encoding)
  {
    source.setEncoding(encoding);
  }

  /**
   * Set the InputSource to read from <code>file</code>, a String filename.
   */
  public void
  setInputSourceFile(ThreadContext context, IRubyObject file)
  {
    source = new InputSource();
    ParserContext.setUrl(context, source, file);
  }

  /**
   * Set the InputSource from <code>stream</code>.
   */
  public void
  setInputSource(InputStream stream)
  {
    source = new InputSource(stream);
  }

  /**
   * Wrap Nokogiri parser options in a utility class.  This is
   * read-only.
   */
  public static class Options
  {
    protected static final long STRICT = 0;
    protected static final long RECOVER = 1;
    protected static final long NOENT = 2;
    protected static final long DTDLOAD = 4;
    protected static final long DTDATTR = 8;
    protected static final long DTDVALID = 16;
    protected static final long NOERROR = 32;
    protected static final long NOWARNING = 64;
    protected static final long PEDANTIC = 128;
    protected static final long NOBLANKS = 256;
    protected static final long SAX1 = 512;
    protected static final long XINCLUDE = 1024;
    protected static final long NONET = 2048;
    protected static final long NODICT = 4096;
    protected static final long NSCLEAN = 8192;
    protected static final long NOCDATA = 16384;
    protected static final long NOXINCNODE = 32768;

    public final boolean strict;
    public final boolean recover;
    public final boolean noEnt;
    public final boolean dtdLoad;
    public final boolean dtdAttr;
    public final boolean dtdValid;
    public final boolean noError;
    public final boolean noWarning;
    public final boolean pedantic;
    public final boolean noBlanks;
    public final boolean sax1;
    public final boolean xInclude;
    public final boolean noNet;
    public final boolean noDict;
    public final boolean nsClean;
    public final boolean noCdata;
    public final boolean noXIncNode;

    protected static boolean
    test(long options, long mask)
    {
      return ((options & mask) == mask);
    }

    public
    Options(long options)
    {
      strict = ((options & RECOVER) == STRICT);
      recover = test(options, RECOVER);
      noEnt = test(options, NOENT);
      dtdLoad = test(options, DTDLOAD);
      dtdAttr = test(options, DTDATTR);
      dtdValid = test(options, DTDVALID);
      noError = test(options, NOERROR);
      noWarning = test(options, NOWARNING);
      pedantic = test(options, PEDANTIC);
      noBlanks = test(options, NOBLANKS);
      sax1 = test(options, SAX1);
      xInclude = test(options, XINCLUDE);
      noNet = test(options, NONET);
      noDict = test(options, NODICT);
      nsClean = test(options, NSCLEAN);
      noCdata = test(options, NOCDATA);
      noXIncNode = test(options, NOXINCNODE);
    }
  }

  /*
  public static class NokogiriXInlcudeEntityResolver implements org.xml.sax.EntityResolver {
      InputSource source;
      public NokogiriXInlcudeEntityResolver(InputSource source) {
          this.source = source;
      }

      @Override
      public InputSource resolveEntity(String publicId, String systemId)
              throws SAXException, IOException {
          if (systemId != null) source.setSystemId(systemId);
          if (publicId != null) source.setPublicId(publicId);
          return source;
      }
  } */

  public static abstract class ParserTask<T extends ParserContext> implements Callable<T>
  {

    protected final ThreadContext context; // TODO does not seem like a good idea!?
    protected final IRubyObject handler;
    protected final T parser;

    protected
    ParserTask(ThreadContext context, IRubyObject handler, T parser)
    {
      this.context = context;
      this.handler = handler;
      this.parser = parser;
    }

  }

}
