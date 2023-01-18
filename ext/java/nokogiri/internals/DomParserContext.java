package nokogiri.internals;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyException;
import org.jruby.RubyFixnum;
import org.jruby.runtime.Helpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

import nokogiri.internals.ParserContext;
import nokogiri.internals.ParserContext.Options;

import nokogiri.XmlDocument;
import nokogiri.XmlDtd;
import nokogiri.XmlSyntaxError;

import static nokogiri.internals.NokogiriHelpers.isBlank;

public abstract class DomParserContext<TParser extends org.apache.xerces.parsers.DOMParser> extends ParserContext
{
  private static final long serialVersionUID = 1L;

  protected ParserContext.Options options;
  protected TParser parser;
  protected IRubyObject ruby_encoding;
  protected NokogiriErrorHandler errorHandler;

  public
  DomParserContext(Ruby ruby, IRubyObject parserOptions, IRubyObject encoding)
  {
    super(ruby, ruby.getObject()); // class 'Object' because this class hierarchy isn't exposed to Ruby
    options = new ParserContext.Options(RubyFixnum.fix2long(parserOptions));
    java_encoding = NokogiriHelpers.getValidEncodingOrNull(encoding);
    ruby_encoding = encoding;

    if (options.recover) {
      errorHandler = new NokogiriNonStrictErrorHandler(ruby, options.noError, options.noWarning);
    } else {
      errorHandler = new NokogiriStrictErrorHandler(ruby, options.noError, options.noWarning);
    }
  }

  public XmlDocument
  parse(ThreadContext context, RubyClass klass, IRubyObject url)
  {
    XmlDocument xmlDoc;
    try {
      parser.parse(getInputSource());
    } catch (NullPointerException ex) {
      // FIXME: this is really a hack to fix #838. Xerces will throw a NullPointerException
      // if we tried to parse '<? ?>'. We should submit a patch to Xerces.
    } catch (SAXException e) {
      return getDocumentWithErrorsOrRaiseException(context, klass, e);
    } catch (IOException e) {
      return getDocumentWithErrorsOrRaiseException(context, klass, e);
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
    xmlDoc = wrapDocument(context, klass, parser.getDocument());
    xmlDoc.setUrl(url);
    addErrorsIfNecessary(context, xmlDoc);
    return xmlDoc;
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

  public void
  addErrorsIfNecessary(ThreadContext context, XmlDocument doc)
  {
    doc.setInstanceVariable("@errors", mapErrors(context, errorHandler));
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
}
