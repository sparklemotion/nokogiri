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

package nokogiri.internals;

import static nokogiri.internals.NokogiriHelpers.rubyStringToString;
import static nokogiri.internals.NokogiriHelpers.adjustSystemIdIfNecessary;
import static org.jruby.javasupport.util.RuntimeHelpers.invoke;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.StringReader;
import java.nio.charset.Charset;
import java.nio.charset.UnsupportedCharsetException;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyIO;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.RubyStringIO;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;
import org.jruby.util.TypeConverter;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.ext.EntityResolver2;

/**
 * Base class for the various parser contexts.  Handles converting
 * Ruby objects to InputSource objects.
 *
 * @author Patrick Mahoney <pat@polycrystal.org>
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class ParserContext extends RubyObject {
    protected InputSource source = null;
    protected IRubyObject detected_encoding = null;
    protected int stringDataSize = -1;

    /**
     * Create a file base input source taking into account the current
     * directory of <code>runtime</code>.
     */
    public static InputSource resolveEntity(Ruby runtime, String publicId, String baseURI, String systemId)
        throws IOException {
        InputSource s = new InputSource();
        String adjusted = adjustSystemIdIfNecessary(runtime.getCurrentDirectory(), runtime.getInstanceConfig().getScriptFileName(), baseURI, systemId);
        if (adjusted == null && publicId == null) {
            throw runtime.newRuntimeError("SystemId \"" + systemId + "\" is not correct.");
        }
        s.setSystemId(adjusted);
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
     * Set the InputSource from <code>url</code> or <code>data</code>,
     * which may be an IO object, a String, or a StringIO.
     */
    public void setInputSource(ThreadContext context, IRubyObject data, IRubyObject url) {
        Ruby ruby = context.getRuntime();
        String path = (String) url.toJava(String.class);
        if (data.getType().respondsTo("detect_encoding")) {
            // data is EnocodingReader
            try {
                data.callMethod(context, "read", RubyFixnum.newFixnum(context.getRuntime(), 1024));
            } catch (RaiseException e) {
                detected_encoding = e.getException().getInstanceVariable("@found_encoding");
            }
        }

        if (isAbsolutePath(path)) {
            returnWithSystemId(path);
            return;
        }
        // Dir.chdir might be called at some point before this.
        String currentDir = context.getRuntime().getCurrentDirectory();
        if (path != null && currentDir != null && currentDir.length() != 0) {
            String absPath = currentDir + "/" + path;
            if (isAbsolutePath(absPath)) {
                returnWithSystemId(absPath);
                return;
            }
        }
        RubyString stringData = null;
        if (invoke(context, data, "respond_to?",
                   ruby.newSymbol("to_io").to_sym()).isTrue()) {
            /* IO or other object that responds to :to_io */
            RubyIO io =
                (RubyIO) TypeConverter.convertToType(data,
                                                     ruby.getIO(),
                                                     "to_io");
            source = new InputSource(io.getInStream());
        } else if (((RubyObject)data).getInstanceVariable("@io") != null) {
            // in case of EncodingReader is used
            // since EncodingReader won't respond to :to_io
            RubyObject dataObject = (RubyObject) ((RubyObject)data).getInstanceVariable("@io");
            if (dataObject instanceof RubyIO) {
                RubyIO io = (RubyIO)dataObject;
                source = new InputSource(io.getInStream());
            } else if (dataObject instanceof RubyStringIO) {
                stringData = (RubyString)((RubyStringIO)dataObject).string();
            }
        } else {
            if (invoke(context, data, "respond_to?",
                          ruby.newSymbol("string").to_sym()).isTrue()) {
                /* StringIO or other object that responds to :string */
                stringData = invoke(context, data, "string").convertToString();
            } else if (data instanceof RubyString) {
                stringData = (RubyString) data;
            } else {
                throw ruby.newArgumentError(
                    "must be kind_of String or respond to :to_io or :string");
            }
        }
        if (stringData != null) {
            String encName = null;
            if (stringData.encoding(context) != null) {
                encName = stringData.encoding(context).toString();
            }
            Charset charset = null;
            if (encName != null) {
                try {
                    charset = Charset.forName(encName);
                } catch (UnsupportedCharsetException e) {
                    // do nothing;
                }
            }
            ByteList bytes = stringData.getByteList();
            if (charset != null) {
                StringReader reader = new StringReader(new String(bytes.unsafeBytes(), bytes.begin(), bytes.length(), charset));
                source = new InputSource(reader);
                source.setEncoding(charset.name());
            } else {
                stringDataSize = bytes.length() - bytes.begin();
                source = new InputSource(new ByteArrayInputStream(bytes.unsafeBytes(), bytes.begin(), bytes.length()));
            }
        }
    }
    
    private boolean isAbsolutePath(String url) {
        if (url == null) return false;
        return (new File(url)).isAbsolute();
    }
    
    private void returnWithSystemId(String url) {
        source = new InputSource();
        if (detected_encoding != null) {
            source.setEncoding((String) detected_encoding.toJava(String.class));
        }
        source.setSystemId(url);
        return;
    }

    /**
     * Set the InputSource to read from <code>file</code>, a String filename.
     */
    public void setInputSourceFile(ThreadContext context, IRubyObject file) {
        String filename = rubyStringToString(file);

        try{
            source = resolveEntity(context.getRuntime(), null, null, filename);
        } catch (Exception e) {
            throw RaiseException.createNativeRaiseException(context.getRuntime(), e);
        }

    }

    /**
     * Set the InputSource from <code>stream</code>.
     */
    public void setInputSource(InputStream stream) {
        source = new InputSource(stream);
    }

    /**
     * Wrap Nokogiri parser options in a utility class.  This is
     * read-only.
     */
    public static class Options {
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

        public boolean strict;
        public boolean recover;
        public boolean noEnt;
        public boolean dtdLoad;
        public boolean dtdAttr;
        public boolean dtdValid;
        public boolean noError;
        public boolean noWarning;
        public boolean pedantic;
        public boolean noBlanks;
        public boolean sax1;
        public boolean xInclude;
        public boolean noNet;
        public boolean noDict;
        public boolean nsClean;
        public boolean noCdata;
        public boolean noXIncNode;

        protected static boolean test(long options, long mask) {
            return ((options & mask) == mask);
        }

        public Options(long options) {
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
            return ParserContext.resolveEntity(runtime, publicId, baseURI, systemId);
        }

    }

}
