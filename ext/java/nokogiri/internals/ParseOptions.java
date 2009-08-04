package nokogiri.internals;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import nokogiri.XmlDocument;
import nokogiri.XmlSyntaxError;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.xml.sax.EntityResolver;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

/**
 *
 * @author sergio
 */
public class ParseOptions {

    public static final long STRICT = 0;
    public static final long RECOVER = 1;
    public static final long NOENT = 2;
    public static final long DTDLOAD = 4;
    public static final long DTDATTR = 8;
    public static final long DTDVALID = 16;
    public static final long NOERROR = 32;
    public static final long NOWARNING = 64;
    public static final long PEDANTIC = 128;
    public static final long NOBLANKS = 256;
    public static final long SAX1 = 512;
    public static final long XINCLUDE = 1024;
    public static final long NONET = 2048;
    public static final long NODICT = 4096;
    public static final long NSCLEAN = 8192;
    public static final long NOCDATA = 16384;
    public static final long NOXINCNODE = 32768;

    protected boolean strict, recover, noEnt, dtdLoad, dtdAttr, dtdValid,
            noError, noWarning, pedantic, noBlanks, sax1, xInclude, noNet,
            noDict, nsClean, noCdata, noXIncNode;

    protected NokogiriErrorHandler errorHandler;

    public ParseOptions(IRubyObject options) {
        this(options.convertToInteger().getLongValue());
    }

    public ParseOptions(long options) {
        if(options == STRICT) {
            this.strict = true;
            this.recover = this.noEnt = this.dtdLoad = this.dtdAttr =
                    this.dtdValid = this.noError = this.noWarning =
                    this.pedantic = this.noBlanks = this.sax1 = this.xInclude =
                    this.noNet = this.noDict = this.nsClean = this.noCdata =
                    this.noXIncNode = false;
        } else {
            this.strict = false;
            this.recover = (options & RECOVER) == RECOVER;
            this.noEnt = (options & NOENT) == NOENT;
            this.dtdLoad = (options & DTDLOAD) == DTDLOAD;
            this.dtdAttr = (options & DTDATTR) == DTDATTR;
            this.dtdValid = (options & DTDVALID) == DTDVALID;
            this.noError = (options & NOERROR) == NOERROR;
            this.noWarning = (options & NOWARNING) == NOWARNING;
            this.pedantic = (options & PEDANTIC) == PEDANTIC;
            this.noBlanks = (options & NOBLANKS) == NOBLANKS;
            this.sax1 = (options & SAX1) == SAX1;
            this.xInclude = (options & XINCLUDE) == XINCLUDE;
            this.noNet = (options & NONET) == NONET;
            this.noDict = (options & NODICT) == NODICT;
            this.nsClean = (options & NSCLEAN) == NSCLEAN;
            this.noCdata = (options & NOCDATA) == NOCDATA;
            this.noXIncNode = (options & NOXINCNODE) == NOXINCNODE;
        }

        if(this.continuesOnError()){
            this.errorHandler = new NokogiriNonStrictErrorHandler();
        } else {
            this.errorHandler = new NokogiriStrictErrorHandler();
        }
    }

    public void addErrorsIfNecessary(ThreadContext context, XmlDocument doc) {
        Ruby ruby = context.getRuntime();
        RubyArray errors = ruby.newArray(this.errorHandler.getErrorsReadyForRuby(context));
        doc.setInstanceVariable("@errors", errors);
    }

    public DocumentBuilder getDocumentBuilder() throws ParserConfigurationException {
        DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
        dbf.setNamespaceAware(true);
        dbf.setIgnoringElementContentWhitespace(false);
        dbf.setValidating(!this.continuesOnError());

        DocumentBuilder db = dbf.newDocumentBuilder();
        db.setEntityResolver(new EntityResolver() {
            public InputSource resolveEntity(String arg0, String arg1) throws SAXException, IOException {
                return new InputSource(new ByteArrayInputStream(new byte[0]));
            }
        });

        db.setErrorHandler(this.errorHandler);

        return db;
    }

    public XmlDocument getDocumentWithErrorsOrRaiseException(ThreadContext context, Exception ex) {
        if(this.continuesOnError()) {
            IRubyObject[] args = new IRubyObject[0];
            XmlDocument doc = (XmlDocument) XmlDocument.rbNew(context,
                    context.getRuntime().getClassFromPath("Nokogiri::XML::Document"),
                    args);
            this.addErrorsIfNecessary(context, doc);
            return doc;
        } else {
            throw new RaiseException(new XmlSyntaxError(context.getRuntime(), ex));
        }
    }

    public boolean continuesOnError() {
        return this.recover;
    }

    public Document parse(InputStream input)
            throws ParserConfigurationException, SAXException, IOException {
        return this.getDocumentBuilder().parse(input);
    }

    public boolean dtdAttr() { return this.dtdAttr; }
    
    public boolean dtdLoad() { return this.dtdLoad; }

    public boolean dtdValid() { return this.dtdValid; }

    public boolean noBlanks() { return this.noBlanks; }

    public boolean noCdata() { return this.noCdata; }

    public boolean noDict() { return this.noDict; }

    public boolean noEnt() { return this.noEnt; }

    public boolean noError() { return this.noError; }

    public boolean noNet() { return this.noNet; }

    public boolean noWarning() { return this.noWarning; }

    public boolean nsClean() { return this.nsClean; }

    public boolean pedantic() { return this.pedantic; }

    public boolean recover() { return this.recover; }

    public boolean sax1() { return this.sax1; }

    public boolean strict() { return this.strict; }

    public boolean xInclude() { return this.xInclude; }

}
