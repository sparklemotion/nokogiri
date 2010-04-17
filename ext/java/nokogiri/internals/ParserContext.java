package nokogiri.internals;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.IOException;
import java.io.StringReader;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyIO;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;
import org.jruby.util.TypeConverter;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.ext.EntityResolver2;

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

    /**
     * Create a file base input source taking into account the current
     * directory of <code>runtime</code>.
     */
    public static InputSource resolveEntity(Ruby runtime,
                                            String publicId,
                                            String baseURI,
                                            String systemId)
        throws IOException {
        String path;

        if ((new File(systemId)).isAbsolute()) {
            path = systemId;
        } else if (baseURI != null) {
            path = (new File(baseURI, systemId)).getAbsolutePath();
        } else {
            String rubyDir = runtime.getCurrentDirectory();
            path = (new File(rubyDir, systemId)).getAbsolutePath();
        }

        InputSource s = new InputSource(new FileInputStream(path));
        s.setSystemId(systemId);
        s.setPublicId(publicId);
        return s;
    }

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

            ByteList bytes = str.getByteList();
            source = new InputSource(new ByteArrayInputStream(bytes.unsafeBytes(), bytes.begin(), bytes.length()));
            source.setEncoding("UTF-8");
        }
    }

    /**
     * Set the InputSource to read from <code>file</code>, a String filename.
     */
    public void setInputSourceFile(ThreadContext context, IRubyObject file) {
        String filename = rubyStringToString(file);

        try{
            source = resolveEntity(context.getRuntime(),
                                   null, null, filename);
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

    /**
     * An entity resolver aware of the fact that the Ruby runtime can
     * change directory but the JVM cannot.  Thus any file based
     * entity resolution that uses relative paths must be translated
     * to be relative to the current directory of the Ruby runtime.
     */
    public static class ChdirEntityResolver implements EntityResolver2 {
        protected Ruby runtime;

        public ChdirEntityResolver(Ruby runtime) {
            super();
            this.runtime = runtime;
        }

        @Override
        public InputSource getExternalSubset(String name, String baseURI)
            throws SAXException, IOException {
            return null;
        }

        @Override
        public InputSource resolveEntity(String publicId, String systemId)
            throws SAXException, IOException {
            return resolveEntity(null, publicId, null, systemId);
        }

        @Override
        public InputSource resolveEntity(String name,
                                         String publicId,
                                         String baseURI,
                                         String systemId)
            throws SAXException, IOException {
            return ParserContext
                .resolveEntity(runtime, publicId, baseURI, systemId);
        }

    }

}
