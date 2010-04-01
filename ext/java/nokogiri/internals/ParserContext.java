package nokogiri.internals;

import java.io.ByteArrayInputStream;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.StringReader;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyIO;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.TypeConverter;
import org.xml.sax.InputSource;

import static org.jruby.javasupport.util.RuntimeHelpers.invoke;
import static nokogiri.internals.NokogiriHelpers.rubyStringToString;

/**
 * Base class for the various parser contexts.  Handles converting
 * Ruby objects to InputSource objects.
 *
 * @author Patrick Mahoney <pat@polycrystal.org>
 */
public class ParserContext extends RubyObject {
    protected InputSource source = null;

    public ParserContext(Ruby runtime) {
        // default to class 'Object' because this class isn't exposed to Ruby
        super(runtime, runtime.getObject());
    }

    public ParserContext(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }

    protected InputSource getInputSource() {
        return source;
    }

    /**
     * Set the InputSource from <code>data</code> which may be an IO
     * object, a String, or a StringIO.
     */
    public void setInputSource(ThreadContext context,
                               IRubyObject data) {
        Ruby ruby = context.getRuntime();

        if (invoke(context, data, "respond_to?",
                   ruby.newSymbol("to_io").to_sym()).isTrue()) {
            /* IO or other object that responds to :to_io */
            RubyIO io =
                (RubyIO) TypeConverter.convertToType(data,
                                                     ruby.getIO(),
                                                     "to_io");
            source = new InputSource(io.getInStream());
        } else {
            RubyString str;
            if (invoke(context, data, "respond_to?",
                          ruby.newSymbol("string").to_sym()).isTrue()) {
                /* StringIO or other object that responds to :string */
                str = invoke(context, data, "string").convertToString();
            } else if (data instanceof RubyString) {
                str = (RubyString) data;
            } else {
                throw ruby.newArgumentError(
                    "must be kind_of String or respond to :to_io or :string");
            }

            // I don't know why ByteArrayInputStream doesn't
            // work... It's a similar problem to that
            // rubyStringToString is supposed to solve (treating Ruby
            // string data as UTF-8).  But StringReader seems to work,
            // so going with it. -- Patrick

            //byte[] bytes = rubyStringToString(str).getBytes();
            //source = new InputSource(new ByteArrayInputStream(bytes));
            source = new InputSource(new StringReader(rubyStringToString(str)));
        }
    }

    /**
     * Set the InputSource to read from <code>file</code>, a String filename.
     */
    public void setInputSourceFile(ThreadContext context, IRubyObject file) {
        String filename = rubyStringToString(file);

        try{
            source = new InputSource(new FileInputStream(filename));
        } catch (Exception e) {
            throw RaiseException
                .createNativeRaiseException(context.getRuntime(), e);
        }

    }

    /**
     * Set the InputSource from <code>stream</code>.
     */
    public void setInputSource(InputStream stream) {
        source = new InputSource(stream);
    }

}
