package nokogiri;

import nokogiri.internals.ClosedStreamException;
import nokogiri.internals.NokogiriBlockingQueueInputStream;
import nokogiri.internals.NokogiriHelpers;
import nokogiri.internals.ParserContext;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.concurrent.*;

import static nokogiri.XmlSaxPushParser.terminateExecution;
import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;
import static org.jruby.runtime.Helpers.invoke;

/**
 * Class for Nokogiri::HTML4::SAX::PushParser
 *
 * @author
 * @author Piotr Szmielew <p.szmielew@ava.waw.pl> - based on Nokogiri::XML::SAX::PushParser
 */
@JRubyClass(name = "Nokogiri::HTML4::SAX::PushParser")
public class Html4SaxPushParser extends RubyObject
{
  private static final long serialVersionUID = 1L;

  ParserContext.Options options;
  IRubyObject saxParser;

  NokogiriBlockingQueueInputStream stream;

  private ParserTask parserTask = null;
  private FutureTask<Html4SaxParserContext> futureTask = null;
  private ExecutorService executor = null;

  public
  Html4SaxPushParser(Ruby ruby, RubyClass rubyClass)
  {
    super(ruby, rubyClass);
  }

  @SuppressWarnings("deprecation")
  @Override
  public void
  finalize()
  {
    try {
      terminateImpl();
    } catch (Exception e) { /* ignored */ }
  }

  @JRubyMethod
  public IRubyObject
  initialize_native(final ThreadContext context,
                    IRubyObject saxParser,
                    IRubyObject fileName,
                    IRubyObject encoding)
  {
    // NOTE: Silently skips provided encoding
    options = new ParserContext.Options(0);
    this.saxParser = saxParser;
    return this;
  }

  private transient IRubyObject parse_options;

  private IRubyObject
  parse_options(final ThreadContext context)
  {
    if (parse_options == null) {
      parse_options = invoke(context, context.runtime.getClassFromPath("Nokogiri::XML::ParseOptions"), "new");
    }
    return parse_options;
  }

  @JRubyMethod(name = "options")
  public IRubyObject
  getOptions(ThreadContext context)
  {
    return invoke(context, parse_options(context), "options");
  }

  @JRubyMethod(name = "options=")
  public IRubyObject
  setOptions(ThreadContext context, IRubyObject opts)
  {
    invoke(context, parse_options(context), "options=", opts);
    options = new ParserContext.Options(opts.convertToInteger().getLongValue());
    return getOptions(context);
  }

  @JRubyMethod
  public IRubyObject
  native_write(ThreadContext context, IRubyObject chunk, IRubyObject isLast)
  {
    try {
      initialize_task(context);
    } catch (IOException e) {
      throw context.getRuntime().newRuntimeError(e.getMessage());
    }
    final ByteArrayInputStream data = NokogiriHelpers.stringBytesToStream(chunk);
    if (data == null) {
      terminateTask(context.runtime);
      throw XmlSyntaxError.createHTMLSyntaxError(context.runtime).toThrowable(); // Nokogiri::HTML4::SyntaxError
    }

    int errorCount0 = parserTask.getErrorCount();

    if (isLast.isTrue()) {
      IRubyObject document = invoke(context, this, "document");
      invoke(context, document, "end_document");
      terminateTask(context.runtime);
    } else {
      try {
        Future<Void> task = stream.addChunk(data);
        task.get();
      } catch (ClosedStreamException ex) {
        // this means the stream is closed, ignore this exception
      } catch (Exception e) {
        throw context.runtime.newRuntimeError(e.getMessage());
      }

    }

    if (!options.recover && parserTask.getErrorCount() > errorCount0) {
      terminateTask(context.runtime);
      throw parserTask.getLastError().toThrowable();
    }

    return this;
  }

  @SuppressWarnings("unchecked")
  private void
  initialize_task(ThreadContext context) throws IOException
  {
    if (futureTask == null || stream == null) {
      stream = new NokogiriBlockingQueueInputStream();

      assert saxParser != null : "saxParser null";
      parserTask = new ParserTask(context, saxParser, stream);
      futureTask = new FutureTask<Html4SaxParserContext>((Callable) parserTask);
      executor = Executors.newSingleThreadExecutor(new ThreadFactory() {
        @Override
        public Thread newThread(Runnable r) {
          Thread t = new Thread(r);
          t.setName("Html4SaxPushParser");
          t.setDaemon(true);
          return t;
        }
      });
      executor.submit(futureTask);
    }
  }

  private void
  terminateTask(final Ruby runtime)
  {
    if (executor == null) { return; }

    try {
      terminateImpl();
    } catch (InterruptedException e) {
      throw runtime.newRuntimeError(e.toString());
    } catch (Exception e) {
      throw runtime.newRuntimeError(e.toString());
    }
  }

  private synchronized void
  terminateImpl() throws InterruptedException, ExecutionException
  {
    terminateExecution(executor, stream, futureTask);

    executor = null;
    stream = null;
    futureTask = null;
  }

  private static Html4SaxParserContext
  parse(final Ruby runtime, final InputStream stream)
  {
    RubyClass klazz = getNokogiriClass(runtime, "Nokogiri::HTML4::SAX::ParserContext");
    return Html4SaxParserContext.parse_stream(runtime, klazz, stream);
  }

  static class ParserTask extends XmlSaxPushParser.ParserTask /* <Html4SaxPushParser> */
  {

    private
    ParserTask(ThreadContext context, IRubyObject handler, InputStream stream)
    {
      super(context, handler, parse(context.runtime, stream), stream);
    }

    @Override
    public Html4SaxParserContext
    call() throws Exception
    {
      return (Html4SaxParserContext) super.call();
    }

  }

}
