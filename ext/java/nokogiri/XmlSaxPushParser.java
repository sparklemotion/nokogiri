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

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.channels.Channels;
import java.nio.channels.Pipe;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.FutureTask;

import nokogiri.internals.ParserContext;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyException;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

/**
 * Class for Nokogiri::XML::SAX::PushParser
 *
 * @author Patrick Mahoney <pat@polycrystal.org>
 * @author Yoko Harada <yokolet@gmail.com>
 */
@JRubyClass(name="Nokogiri::XML::SAX::PushParser")
public class XmlSaxPushParser extends RubyObject {
    ParserContext.Options options;
    IRubyObject optionsRuby;
    IRubyObject saxParser;
    OutputStream ostream = null;
    InputStream istream = null;
    ParserTask parserTask = null;
    FutureTask<XmlSaxParserContext> futureTask = null;
    ExecutorService executor = null;

    public XmlSaxPushParser(Ruby ruby, RubyClass rubyClass) {
        super(ruby, rubyClass);
    }

    @JRubyMethod
    public IRubyObject initialize_native(final ThreadContext context,
                                         IRubyObject saxParser,
                                         IRubyObject fileName) {
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
            try {
                terminateTask();
            } catch (IOException e) {
                throw context.getRuntime().newRuntimeError(e.getMessage());
            }
            XmlSyntaxError xmlSyntaxError = 
                (XmlSyntaxError) NokogiriService.XML_SYNTAXERROR_ALLOCATOR.allocate(context.getRuntime(), getNokogiriClass(context.getRuntime(), "Nokogiri::XML::SyntaxError"));
            throw new RaiseException(xmlSyntaxError);
        }

        int errorCount0 = parserTask.getErrorCount();;
        
        try {
            if (isLast.isTrue()) {
                IRubyObject document = invoke(context, this, "document");
                invoke(context, document, "end_document");
                terminateTask();
            } else {
                ostream.write(data);
                Thread.currentThread().sleep(10);   // gives a reader a chance to work
            }
        } catch (IOException e) {
            throw context.getRuntime().newRuntimeError(e.getMessage());
        } catch (InterruptedException e) {
            throw context.getRuntime().newRuntimeError(e.getMessage());
        }

        if (!options.recover && parserTask.getErrorCount() > errorCount0) {
            try {
                terminateTask();
            } catch (IOException e) {
                throw context.getRuntime().newRuntimeError(e.getMessage());
            }
            throw new RaiseException(parserTask.getLastError(), true);
        }

        return this;
    }
    
    private void initialize_task(ThreadContext context) throws IOException {
        if (futureTask == null || ostream == null || istream == null) {
            Pipe pipe = Pipe.open();
            Pipe.SinkChannel sink = pipe.sink();
            ostream = Channels.newOutputStream(sink);
            Pipe.SourceChannel source = pipe.source();
            istream = Channels.newInputStream(source);

            parserTask = new ParserTask(context, saxParser);
            futureTask = new FutureTask<XmlSaxParserContext>(parserTask);
            executor = Executors.newSingleThreadExecutor();
            executor.submit(futureTask);
        }
    }
    
    private synchronized void terminateTask() throws IOException {
        futureTask.cancel(true);
        executor.shutdown();
        ostream.close();
        istream.close();
        ostream = null;
        istream = null;
    }
    
    private class ParserTask implements Callable<XmlSaxParserContext> {
        private ThreadContext context;
        private IRubyObject handler;
        private XmlSaxParserContext parser;
        
        private ParserTask(ThreadContext context, IRubyObject handler) {
            RubyClass klazz = getNokogiriClass(context.getRuntime(), "Nokogiri::XML::SAX::ParserContext");
            this.context = context;
            this.handler = handler;
            this.parser = (XmlSaxParserContext) XmlSaxParserContext.parse_stream(context, klazz, istream);
        }

        @Override
        public XmlSaxParserContext call() throws Exception {
            parser.parse_with(context, handler);
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
