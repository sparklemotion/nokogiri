/**
 * (The MIT License)
 *
 * Copyright (c) 2008 - 2012:
 *
 * * {Aaron Patterson}[http://tenderlovemaking.com]
 * * {Mike Dalessio}[http://mike.daless.io]
 * * {Charles Nutter}[http://blog.headius.com]
 * * {Sergio Arbeo}[http://www.serabe.com]
 * * {Patrick Mahoney}[http://polycrystal.org]
 * * {Yoko Harada}[http://yokolet.blogspot.com]
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * 'Software'), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

package nokogiri;

import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;
import static org.jruby.javasupport.util.RuntimeHelpers.invoke;
import static nokogiri.internals.NokogiriHelpers.rubyStringToString;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.charset.IllegalCharsetNameException;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.EnumSet;
import java.util.concurrent.Future;
import java.util.concurrent.FutureTask;
import java.util.concurrent.ThreadFactory;

import nokogiri.internals.ClosedStreamException;
import nokogiri.internals.NokogiriBlockingQueueInputStream;
import nokogiri.internals.ParserContext;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyException;
import org.jruby.RubyFixnum;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

/**
 * Class for Nokogiri::HTML::SAX::PushParser
 *
 * @author 
 * @author Piotr Szmielew <p.szmielew@ava.waw.pl> - based on Nokogiri::XML::SAX::PushParser
 */
@JRubyClass(name="Nokogiri::HTML::SAX::PushParser")
public class HtmlSaxPushParser extends RubyObject {
    ParserContext.Options options;
    IRubyObject optionsRuby;
    IRubyObject saxParser;
    NokogiriBlockingQueueInputStream stream;
    ParserTask parserTask = null;
    FutureTask<HtmlSaxParserContext> futureTask = null;
    ExecutorService executor = null;

    public HtmlSaxPushParser(Ruby ruby, RubyClass rubyClass) {
        super(ruby, rubyClass);
    }

    @Override
    public void finalize() {
      terminateTask(null);
    }

    /**
    * Silently skips provided encoding
    *
    */
    @JRubyMethod
    public IRubyObject initialize_native(final ThreadContext context,
                                         IRubyObject saxParser,
                                         IRubyObject fileName,
                                         IRubyObject encoding) {
        optionsRuby
            = invoke(context, context.getRuntime().getClassFromPath("Nokogiri::XML::ParseOptions"), "new");
       
        options = new ParserContext.Options(0);
        this.saxParser = saxParser;
        return this;
    }

    /**
     * Returns an integer.
     */
    @JRubyMethod(name="options")
    public IRubyObject getOptions(ThreadContext context) {
        return invoke(context, optionsRuby, "options");
    }

    /**
     * <code>val</code> is an integer.
     */
    @JRubyMethod(name="options=")
    public IRubyObject setOptions(ThreadContext context, IRubyObject val) {
        invoke(context, optionsRuby, "options=", val);
        options =
            new ParserContext.Options(val.convertToInteger().getLongValue());
        return getOptions(context);
    }

    @JRubyMethod
    public IRubyObject native_write(ThreadContext context, IRubyObject chunk,
                                    IRubyObject isLast) {
        try {
            initialize_task(context);
        } catch (IOException e) {
            throw context.getRuntime().newRuntimeError(e.getMessage());
        }
        byte[] data = null;
        if (chunk instanceof RubyString || chunk.respondsTo("to_str")) {
            data = chunk.convertToString().getBytes();
        } else {
            terminateTask(context);
            XmlSyntaxError xmlSyntaxError =
                (XmlSyntaxError) NokogiriService.XML_SYNTAXERROR_ALLOCATOR.allocate(context.getRuntime(), getNokogiriClass(context.getRuntime(), "Nokogiri::HTML::SyntaxError"));
            throw new RaiseException(xmlSyntaxError);
        }

        int errorCount0 = parserTask.getErrorCount();;


        if (isLast.isTrue()) {
            IRubyObject document = invoke(context, this, "document");
            invoke(context, document, "end_document");
            terminateTask(context);
        } else {
            try {
              Future<Void> task = stream.addChunk(new ByteArrayInputStream(data));
              task.get();
            } catch (ClosedStreamException ex) {
              // this means the stream is closed, ignore this exception
            } catch (Exception e) {
              throw context.getRuntime().newRuntimeError(e.getMessage());
            }

        }

        if (!options.recover && parserTask.getErrorCount() > errorCount0) {
            terminateTask(context);
            throw new RaiseException(parserTask.getLastError(), true);
        }

        return this;
    }

    private void initialize_task(ThreadContext context) throws IOException {
        if (futureTask == null || stream == null) {
            stream = new NokogiriBlockingQueueInputStream();

            parserTask = new ParserTask(context, saxParser);
            futureTask = new FutureTask<HtmlSaxParserContext>(parserTask);
            executor = Executors.newSingleThreadExecutor(new ThreadFactory() {
              @Override
              public Thread newThread(Runnable r) {
                Thread t = new Thread(r);
                t.setName("HtmlSaxPushParser");
                t.setDaemon(true);
                return t;
              }
            });
            executor.submit(futureTask);
        }
    }

    private synchronized void terminateTask(ThreadContext context) {
        try {
          Future<Void> task = stream.addChunk(NokogiriBlockingQueueInputStream.END);
          task.get();
        } catch (ClosedStreamException ex) {
          // ignore this exception, it means the stream was closed
        } catch (Exception e) {
            if (context != null)
              throw context.getRuntime().newRuntimeError(e.getMessage());
        }
        futureTask.cancel(true);
        executor.shutdown();
        executor = null;
        stream = null;
        futureTask = null;
    }
    
    private static String findEncoding(ThreadContext context, IRubyObject encoding) {
        String rubyEncoding = null;
        if (encoding instanceof RubyString) {
            rubyEncoding = rubyStringToString(encoding);
        } else if (encoding instanceof RubyFixnum) {
            int value = (Integer)encoding.toJava(Integer.class);
            rubyEncoding = findName(value);
        }
        if (rubyEncoding == null) return null;
        try {
            Charset charset = Charset.forName(rubyEncoding);
            return charset.displayName();
        } catch (IllegalCharsetNameException e) {
            throw context.getRuntime().newEncodingCompatibilityError(
                    rubyEncoding + "is not supported in Java.");
        } catch (IllegalArgumentException e) {
            throw context.getRuntime().newInvalidEncoding(
                    "encoding should not be nil");
        }
    }
    
    private static String findName(int value) {
        EnumSet<EncodingType> set = EnumSet.allOf(EncodingType.class);
        for (EncodingType type : set) {
            if (type.getValue() == value) return type.toString();
        }
        return null;
    }
    
     public static enum EncodingType {
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
          EncodingType(int value, String name) {
              this.value = value;
              this.name = name;
          }

          public int getValue() {
              return value;
          }

          public String toString() {
              return name;
          }
      }
    

    private class ParserTask implements Callable<HtmlSaxParserContext> {
        private final ThreadContext context;
        private final IRubyObject handler;
        private final HtmlSaxParserContext parser;

        private ParserTask(ThreadContext context, IRubyObject handler) {
            RubyClass klazz = getNokogiriClass(context.getRuntime(), "Nokogiri::HTML::SAX::ParserContext");
            this.context = context;
            this.handler = handler;
            this.parser = (HtmlSaxParserContext) HtmlSaxParserContext.parse_stream(context, klazz, stream);
        }

        @Override
        public HtmlSaxParserContext call() throws Exception {
          try {
            parser.parse_with(context, handler);
          } finally {
            // we have to close the stream before exiting, otherwise someone
            // can add a chunk and block on task.get() forever.
            stream.close();
          }
          return parser;
        }

        private synchronized int getErrorCount() {
            // check for null because thread may not have started yet
            if (parser.getNokogiriHandler() == null) return 0;
            else return parser.getNokogiriHandler().getErrorCount();
        }

        private synchronized RubyException getLastError() {
            return (RubyException) parser.getNokogiriHandler().getLastError();
        }
    }
}
