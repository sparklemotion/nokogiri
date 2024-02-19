package nokogiri.internals;

import nokogiri.internals.*;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyException;
import org.jruby.RubyFixnum;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import static org.jruby.runtime.Helpers.invoke;

import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;

import java.io.IOException;
import java.io.InputStream;
import java.util.List;
import java.util.concurrent.Callable;

public abstract class SaxParserContext<TParser extends org.xml.sax.XMLReader> extends ParserContext
{
  private static final long serialVersionUID = 1L;

  protected TParser parser;
  protected NokogiriHandler handler;
  protected NokogiriErrorHandler errorHandler;

  protected boolean replaceEntities = true;
  protected boolean recovery = false;

  protected static final String FEATURE_CONTINUE_AFTER_FATAL_ERROR =
    "http://apache.org/xml/features/continue-after-fatal-error";
  protected static final String PROPERTY_LEXICAL_HANDLER =
    "http://xml.org/sax/properties/lexical-handler";

  public
  SaxParserContext(final Ruby ruby, RubyClass rubyClass)
  {
    super(ruby, rubyClass);
  }

  @Override
  public Object
  clone() throws CloneNotSupportedException
  {
    return super.clone();
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

  protected abstract TParser createParser() throws SAXException;

  public final NokogiriHandler
  getNokogiriHandler() { return handler; }

  public final NokogiriErrorHandler
  getNokogiriErrorHandler() { return errorHandler; }

  protected abstract Options defaultParseOptions(ThreadContext context);

  protected void
  parseSetup(ThreadContext context, IRubyObject rubyParser)
  {
  }

  public IRubyObject
  parse_with(ThreadContext context, IRubyObject rubyParser)
  {
    final Ruby runtime = context.runtime;

    if (!invoke(context, rubyParser, "respond_to?", runtime.newSymbol("document")).isTrue()) {
      throw runtime.newArgumentError("argument must respond_to document");
    }

    /* TODO: how should we pass in parse options? */
    ParserContext.Options options = defaultParseOptions(context);

    errorHandler = new NokogiriStrictErrorHandler(runtime, options.noError, options.noWarning);
    handler = new NokogiriHandler(runtime, rubyParser, errorHandler);

    parseSetup(context, rubyParser);

    parser.setContentHandler(handler);
    parser.setErrorHandler(handler);
    parser.setEntityResolver(new NokogiriEntityResolver(runtime, errorHandler, options));
    try {
      parser.setProperty(PROPERTY_LEXICAL_HANDLER, handler);
    } catch (SAXException e) {
      throw runtime.newRuntimeError(e.getMessage());
    }

    try {
      try {
        parser.parse(getInputSource());
      } catch (SAXParseException ex) {
        // A bad document (<foo><bar></foo>) should call the
        // error handler instead of raising a SAX exception.

        // However, an EMPTY document should raise a RuntimeError.
        // This is a bit kludgy, but AFAIK SAX doesn't distinguish
        // between empty and bad whereas Nokogiri does.
        String message = ex.getMessage();
        if (message != null && message.contains("Premature end of file.") && stringDataSize < 1) {
          throw runtime.newRuntimeError("couldn't parse document: " + message);
        }
        handler.error(ex);
      }
    } catch (SAXException ex) {
      // Unexpected failure in XML subsystem
      throw runtime.newRuntimeError(ex.getMessage());
    } catch (IOException ex) {
      throw runtime.newIOErrorFromException(ex);
    }

    return runtime.getNil();
  }

  public static abstract class ParserTask<T extends SaxParserContext<?>> implements Callable<T>
  {
    protected final ThreadContext context; // TODO does not seem like a good idea!?
    protected final IRubyObject handler;
    protected final T parser;
    final InputStream stream;

    public
    ParserTask(ThreadContext context, IRubyObject handler, T parser, InputStream stream)
    {
      this.context = context;
      this.handler = handler;
      this.parser = parser;
      this.stream = stream;
    }

    public final NokogiriHandler
    getNokogiriHandler()
    {
      return parser.getNokogiriHandler();
    }

    public synchronized final int
    getErrorCount()
    {
      // check for null because thread may not have started yet
      if (parser.getNokogiriErrorHandler() == null) { return 0; }
      return parser.getNokogiriErrorHandler().getErrors().size();
    }

    public synchronized final RubyException
    getLastError()
    {
      List<RubyException> errors = parser.getNokogiriErrorHandler().getErrors();
      return errors.get(errors.size() - 1);
    }

    @Override
    public T
    call() throws Exception
    {
      try {
        parser.parse_with(context, handler);
      } finally { stream.close(); }
      // we have to close the stream before exiting, otherwise someone
      // can add a chunk and block on task.get() forever.
      return parser;
    }
  }
}
