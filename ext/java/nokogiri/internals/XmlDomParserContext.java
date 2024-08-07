package nokogiri.internals;

import nokogiri.XmlDocument;
import nokogiri.XmlDtd;
import nokogiri.XmlSyntaxError;
import org.apache.xerces.parsers.DOMParser;
import org.jruby.*;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.Helpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import static nokogiri.internals.NokogiriHelpers.isBlank;

/**
 * Parser class for XML DOM processing. This class actually parses XML document
 * and creates DOM tree in Java side. However, DOM tree in Ruby side is not since
 * we delay creating objects for performance.
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class XmlDomParserContext extends ParserContext
{
  private static final long serialVersionUID = 1L;

  protected static final String FEATURE_LOAD_EXTERNAL_DTD =
    "http://apache.org/xml/features/nonvalidating/load-external-dtd";
  protected static final String FEATURE_LOAD_DTD_GRAMMAR =
    "http://apache.org/xml/features/nonvalidating/load-dtd-grammar";
  protected static final String FEATURE_INCLUDE_IGNORABLE_WHITESPACE =
    "http://apache.org/xml/features/dom/include-ignorable-whitespace";
  protected static final String CONTINUE_AFTER_FATAL_ERROR =
    "http://apache.org/xml/features/continue-after-fatal-error";
  protected static final String FEATURE_NOT_EXPAND_ENTITY =
    "http://apache.org/xml/features/dom/create-entity-ref-nodes";
  protected static final String FEATURE_VALIDATION = "http://xml.org/sax/features/validation";
  private static final String SECURITY_MANAGER = "http://apache.org/xml/properties/security-manager";

  protected ParserContext.Options options;
  protected DOMParser parser;
  protected NokogiriErrorHandler errorHandler;
  protected IRubyObject ruby_encoding;

  public
  XmlDomParserContext(Ruby runtime, IRubyObject options)
  {
    this(runtime, runtime.getNil(), options);
  }

  public
  XmlDomParserContext(Ruby runtime, IRubyObject encoding, IRubyObject options)
  {
    super(runtime);
    this.options = new ParserContext.Options(RubyFixnum.fix2long(options));
    java_encoding = NokogiriHelpers.getValidEncodingOrNull(encoding);
    ruby_encoding = encoding;
    initErrorHandler(runtime);
    initParser(runtime);
  }

  protected void
  initErrorHandler(Ruby runtime)
  {
    if (options.recover) {
      errorHandler = new NokogiriNonStrictErrorHandler(runtime, options.noError, options.noWarning);
    } else {
      errorHandler = new NokogiriStrictErrorHandler(runtime, options.noError, options.noWarning);
    }
  }

  protected void
  initParser(Ruby runtime)
  {
    if (options.xInclude) {
      System.setProperty("org.apache.xerces.xni.parser.XMLParserConfiguration",
                         "org.apache.xerces.parsers.XIncludeParserConfiguration");
    }

    parser = new NokogiriDomParser(options);
    parser.setErrorHandler(errorHandler);

    // Fix for Issue#586.  This limits entity expansion up to 100000 and nodes up to 3000.
    setProperty(SECURITY_MANAGER, new org.apache.xerces.util.SecurityManager());

    setFeature(FEATURE_INCLUDE_IGNORABLE_WHITESPACE, !options.noBlanks);
    setFeature(CONTINUE_AFTER_FATAL_ERROR, options.recover);
    setFeature(FEATURE_VALIDATION, options.dtdValid);
    setFeature(FEATURE_NOT_EXPAND_ENTITY, !options.noEnt);

    // If we turn off loading of external DTDs complete, we don't
    // get the publicID.  Instead of turning off completely, we use
    // an entity resolver that returns empty documents.
    setFeature(FEATURE_LOAD_EXTERNAL_DTD, options.dtdLoad);
    setFeature(FEATURE_LOAD_DTD_GRAMMAR, options.dtdLoad);

    parser.setEntityResolver(new NokogiriEntityResolver(runtime, errorHandler, options));
  }

  /**
   * Convenience method that catches and ignores SAXException
   * (unrecognized and unsupported exceptions).
   */
  protected void
  setFeature(String feature, boolean value)
  {
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
  protected void
  setProperty(String property, Object value)
  {
    try {
      parser.setProperty(property, value);
    } catch (SAXException e) {
      // ignore
    }
  }

  public void
  addErrorsIfNecessary(ThreadContext context, XmlDocument doc)
  {
    doc.setInstanceVariable("@errors", mapErrors(context, errorHandler));
  }


  public static RubyArray<?>
  mapErrors(ThreadContext context, NokogiriErrorHandler errorHandler)
  {
    final Ruby runtime = context.runtime;
    final List<RubyException> errors = errorHandler.getErrors();
    final IRubyObject[] errorsAry = new IRubyObject[errors.size()];
    for (int i = 0; i < errors.size(); i++) {
      errorsAry[i] = errors.get(i);
    }
    return runtime.newArrayNoCopy(errorsAry);
  }

  public XmlDocument
  getDocumentWithErrorsOrRaiseException(ThreadContext context, RubyClass klazz, Exception ex)
  {
    if (options.recover) {
      XmlDocument xmlDocument = getInterruptedOrNewXmlDocument(context, klazz);
      this.addErrorsIfNecessary(context, xmlDocument);
      XmlSyntaxError xmlSyntaxError = XmlSyntaxError.createXMLSyntaxError(context.runtime);
      xmlSyntaxError.setException(ex);
      ((RubyArray) xmlDocument.getInstanceVariable("@errors")).append(xmlSyntaxError);
      return xmlDocument;
    } else {
      XmlSyntaxError xmlSyntaxError = XmlSyntaxError.createXMLSyntaxError(context.runtime);
      xmlSyntaxError.setException(ex);
      throw xmlSyntaxError.toThrowable();
    }
  }

  private XmlDocument
  getInterruptedOrNewXmlDocument(ThreadContext context, RubyClass klass)
  {
    Document document = parser.getDocument();
    XmlDocument xmlDocument = new XmlDocument(context.runtime, klass, document);
    xmlDocument.setEncoding(ruby_encoding);
    return xmlDocument;
  }

  /**
   * This method is broken out so that HtmlDomParserContext can
   * override it.
   */
  protected XmlDocument
  wrapDocument(ThreadContext context, RubyClass klass, Document doc)
  {
    XmlDocument xmlDocument = new XmlDocument(context.runtime, klass, doc);
    Helpers.invoke(context, xmlDocument, "initialize");
    xmlDocument.setEncoding(ruby_encoding);

    if (options.dtdLoad) {
      IRubyObject dtd = XmlDtd.newFromExternalSubset(context.runtime, doc);
      if (!dtd.isNil()) {
        doc.setUserData(XmlDocument.DTD_EXTERNAL_SUBSET, (XmlDtd) dtd, null);
      }
    }
    return xmlDocument;
  }

  /**
   * Must call setInputSource() before this method.
   */
  public XmlDocument
  parse(ThreadContext context, RubyClass klass, IRubyObject url)
  {
    XmlDocument xmlDoc;
    try {
      Document doc = do_parse();
      xmlDoc = wrapDocument(context, klass, doc);
      xmlDoc.setUrl(url);
      addErrorsIfNecessary(context, xmlDoc);
      return xmlDoc;
    } catch (SAXException e) {
      return getDocumentWithErrorsOrRaiseException(context, klass, e);
    } catch (IOException e) {
      return getDocumentWithErrorsOrRaiseException(context, klass, e);
    }
  }

  protected Document
  do_parse() throws SAXException, IOException
  {
    try {
      parser.parse(getInputSource());
    } catch (NullPointerException ex) {
      // FIXME: this is really a hack to fix #838. Xerces will throw a NullPointerException
      // if we tried to parse '<? ?>'. We should submit a patch to Xerces.
    }
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

  private static void
  findEmptyTexts(Node node, List<Node> emptyNodes)
  {
    if (node.getNodeType() == Node.TEXT_NODE && isBlank(node.getTextContent())) {
      emptyNodes.add(node);
    } else {
      NodeList children = node.getChildNodes();
      for (int i = 0; i < children.getLength(); i++) {
        findEmptyTexts(children.item(i), emptyNodes);
      }
    }
  }
}
