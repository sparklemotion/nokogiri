package nokogiri.internals;

import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import nokogiri.XmlDocument;
import nokogiri.XmlSyntaxError;

import org.apache.xerces.parsers.DOMParser;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.EntityResolver;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

/**
 *
 * @author sergio
 */
public class XmlDomParserContext extends ParserContext {
    protected static final String FEATURE_LOAD_EXTERNAL_DTD =
        "http://apache.org/xml/features/nonvalidating/load-external-dtd";
    protected static final String FEATURE_INCLUDE_IGNORABLE_WHITESPACE =
        "http://apache.org/xml/features/dom/include-ignorable-whitespace";
    protected static final String FEATURE_VALIDATION = "http://xml.org/sax/features/validation";

    protected ParserContext.Options options;
    protected DOMParser parser;
    protected NokogiriErrorHandler errorHandler;
    protected String java_encoding;
    protected IRubyObject ruby_encoding;

    public XmlDomParserContext(Ruby runtime, IRubyObject options) {
        this(runtime, runtime.getNil(), options);
    }
    
    public XmlDomParserContext(Ruby runtime, IRubyObject encoding, IRubyObject options) {
        super(runtime);
        this.options = new ParserContext.Options((Long)options.toJava(Long.class));
        this.java_encoding = encoding.isNil() ? NokogiriHelpers.guessEncoding(runtime) : (String)encoding.toJava(String.class);
        ruby_encoding = encoding;
        initErrorHandler();
        initParser(runtime);
    }
    
    protected void initErrorHandler() {
        if (continuesOnError()) {
            errorHandler = new NokogiriNonStrictErrorHandler();
        } else {
            errorHandler = new NokogiriStrictErrorHandler();
        }
    }

    protected void initParser(Ruby runtime) {
        parser = new XmlDomParser();
        parser.setErrorHandler(errorHandler);

        if (options.noBlanks) {
            setFeature(FEATURE_INCLUDE_IGNORABLE_WHITESPACE, false);
        }

        if (options.dtdValid) {
            setFeature(FEATURE_VALIDATION, true);
        }
        // If we turn off loading of external DTDs complete, we don't
        // getthe publicID.  Instead of turning off completely, we use
        // an entity resolver that returns empty documents.
        if (options.dtdLoad) {
            setFeature(FEATURE_LOAD_EXTERNAL_DTD, true);
            parser.setEntityResolver(new ChdirEntityResolver(runtime));
        } else {
            parser.setEntityResolver(new EntityResolver() {
                    public InputSource resolveEntity(String arg0, String arg1)
                        throws SAXException, IOException {
                        ByteArrayInputStream empty =
                            new ByteArrayInputStream(new byte[0]);
                        return new InputSource(empty);
                    }
                });
        }
    }

    /**
     * Convenience method that catches and ignores SAXException
     * (unrecognized and unsupported exceptions).
     */
    protected void setFeature(String feature, boolean value) {
        try {
            parser.setFeature(feature, value);
        } catch (SAXException e) {
            // ignore
        }
    }

    /**
     * Convenience method that catches and ignores SAXException
     * (unrecognized and unsupported exceptions).
     */
    protected void setProperty(String property, Object value) {
        try {
            parser.setProperty(property, value);
        } catch (SAXException e) {
            // ignore
        }
    }

    public void addErrorsIfNecessary(ThreadContext context, XmlDocument doc) {
        Ruby ruby = context.getRuntime();
        RubyArray errors = ruby.newArray(this.errorHandler.getErrorsReadyForRuby(context));
        doc.setInstanceVariable("@errors", errors);
    }

    public XmlDocument getDocumentWithErrorsOrRaiseException(ThreadContext context, Exception ex) {
        if(this.continuesOnError()) {
            XmlDocument doc = this.getNewEmptyDocument(context);
            this.addErrorsIfNecessary(context, doc);
            ((RubyArray) doc.getInstanceVariable("@errors")).append(new XmlSyntaxError(context.getRuntime(), ex));
            return doc;
        } else {
            throw new RaiseException(new XmlSyntaxError(context.getRuntime(), ex));
        }
    }

    protected XmlDocument getNewEmptyDocument(ThreadContext context) {
        IRubyObject[] args = new IRubyObject[0];
        return (XmlDocument) XmlDocument.rbNew(context,
                    getNokogiriClass(context.getRuntime(), "Nokogiri::XML::Document"),
                    args);
    }

    public boolean continuesOnError() {
        return options.recover;
    }

    /**
     * This method is broken out so that HtmlDomParserContext can
     * override it.
     */
    protected XmlDocument wrapDocument(ThreadContext context,
                                       RubyClass klass,
                                       Document doc) {
        XmlDocument xmlDocument = new XmlDocument(context.getRuntime(), klass, doc);
        xmlDocument.setEncoding(ruby_encoding);
        return xmlDocument;
    }

    /**
     * Must call setInputSource() before this method.
     */
    public XmlDocument parse(ThreadContext context,
                             IRubyObject klass,
                             IRubyObject url) {
        try {
            Document doc = do_parse();
            XmlDocument xmlDoc = wrapDocument(context, (RubyClass)klass, doc);
            xmlDoc.setUrl(url);
            addErrorsIfNecessary(context, xmlDoc);
            return xmlDoc;
        } catch (SAXException e) {
            return getDocumentWithErrorsOrRaiseException(context, e);
        } catch (IOException e) {
            return getDocumentWithErrorsOrRaiseException(context, e);
        }
    }

    protected Document do_parse() throws SAXException, IOException {
        parser.parse(getInputSource());
        if (options.noBlanks) {
            List<Node> emptyNodes = new ArrayList<Node>();
            findEmptyTexts(parser.getDocument(), emptyNodes);
            if (emptyNodes.size() > 0) {
                for (Node node : emptyNodes) {
                    node.getParentNode().removeChild(node);
                }
            }
        }
        return parser.getDocument();
    }
    
    private void findEmptyTexts(Node node, List<Node> emptyNodes) {
        if (node.getNodeType() == Node.TEXT_NODE && "".equals(node.getTextContent().trim())) {
            emptyNodes.add(node);
        } else {
            NodeList children = node.getChildNodes();
            for (int i=0; i < children.getLength(); i++) {
                findEmptyTexts(children.item(i), emptyNodes);
            }
        }
    }
}
