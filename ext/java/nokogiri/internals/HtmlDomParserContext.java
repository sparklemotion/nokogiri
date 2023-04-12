package nokogiri.internals;

import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;
import static nokogiri.internals.NokogiriHelpers.isNamespace;
import static nokogiri.internals.NokogiriHelpers.stringOrNil;

import nokogiri.Html4Document;
import nokogiri.NokogiriService;
import nokogiri.XmlDocument;
import nokogiri.XmlSyntaxError;

import org.apache.xerces.xni.Augmentations;
import org.apache.xerces.xni.QName;
import org.apache.xerces.xni.XMLAttributes;
import org.apache.xerces.xni.XNIException;
import org.apache.xerces.xni.parser.XMLDocumentFilter;
import org.apache.xerces.xni.parser.XMLParserConfiguration;
import net.sourceforge.htmlunit.cyberneko.HTMLConfiguration;
import net.sourceforge.htmlunit.cyberneko.filters.DefaultFilter;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.Helpers;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

/**
 * Parser for Html4Document. This class actually parses Html4Document using NekoHtml.
 *
 * @author sergio
 * @author Patrick Mahoney <pat@polycrystal.org>
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class HtmlDomParserContext extends XmlDomParserContext
{
  private static final long serialVersionUID = 1L;

  public
  HtmlDomParserContext(Ruby runtime, IRubyObject options)
  {
    this(runtime, runtime.getNil(), options);
  }

  public
  HtmlDomParserContext(Ruby runtime, IRubyObject encoding, IRubyObject options)
  {
    super(runtime, encoding, options);
    java_encoding = NokogiriHelpers.getValidEncoding(encoding);
  }

  @Override
  protected void
  initParser(Ruby runtime)
  {
    XMLParserConfiguration config = new HTMLConfiguration();
    XMLDocumentFilter elementValidityCheckFilter = new ElementValidityCheckFilter(errorHandler);
    XMLDocumentFilter[] filters = { elementValidityCheckFilter};

    config.setErrorHandler(this.errorHandler);

    parser = new NokogiriDomParser(config);

    // see http://nekohtml.sourceforge.net/settings.html for details
    setProperty("http://cyberneko.org/html/properties/default-encoding", java_encoding);
    setProperty("http://cyberneko.org/html/properties/names/elems", "lower");
    setProperty("http://cyberneko.org/html/properties/names/attrs", "lower");
    setProperty("http://cyberneko.org/html/properties/filters", filters);
    setFeature("http://cyberneko.org/html/features/report-errors", true);
    setFeature("http://xml.org/sax/features/namespaces", false);
  }

  @Override
  public void
  setEncoding(String encoding)
  {
    super.setEncoding(encoding);
  }

  /**
   * Enable NekoHTML feature for balancing tags in a document fragment.
   *
   * This method is used in XmlNode#in_context method.
   */
  public void
  enableDocumentFragment()
  {
    setFeature("http://cyberneko.org/html/features/balance-tags/document-fragment", true);
  }

  @Override
  public XmlDocument
  parse(ThreadContext context, RubyClass klass, IRubyObject url)
  {
    XmlDocument xmlDoc = super.parse(context, klass, url);

    // let's be consistent in how we handle RECOVER and NORECOVER (a.k.a. STRICT)
    // https://github.com/sparklemotion/nokogiri/issues/2130
    if (!options.recover && errorHandler.getErrors().size() > 0) {
      XmlSyntaxError xmlSyntaxError = XmlSyntaxError.createXMLSyntaxError(context.runtime);
      String exceptionMsg = String.format("%s: '%s'",
                                          "Parser without recover option encountered error or warning",
                                          errorHandler.getErrors().get(0));
      xmlSyntaxError.setException(new Exception(exceptionMsg));
      throw xmlSyntaxError.toThrowable();
    }

    return xmlDoc;
  }

  @Override
  protected XmlDocument
  wrapDocument(ThreadContext context, RubyClass klass, Document document)
  {
    Html4Document htmlDocument = new Html4Document(context.runtime, klass, document);
    htmlDocument.setDocumentNode(context.runtime, document);
    Helpers.invoke(context, htmlDocument, "initialize");

    if (ruby_encoding.isNil()) {
      // ruby_encoding might have detected by Html4Document::EncodingReader
      if (detected_encoding != null && !detected_encoding.isNil()) {
        ruby_encoding = detected_encoding;
      } else {
        // no encoding given & no encoding detected, then try to get it
        String charset = tryGetCharsetFromHtml5MetaTag(document);
        ruby_encoding = stringOrNil(context.runtime, charset);
      }
    }
    htmlDocument.setEncoding(ruby_encoding);
    htmlDocument.setParsedEncoding(java_encoding);
    return htmlDocument;
  }

  // NekoHtml doesn't understand HTML5 meta tag format. This fails to detect charset
  // from an HTML5 style meta tag. Luckily, the meta tag and charset exists in DOM tree
  // so, this method attempts to find the charset.
  private static String
  tryGetCharsetFromHtml5MetaTag(Document document)
  {
    if (!"html".equalsIgnoreCase(document.getDocumentElement().getNodeName())) { return null; }
    NodeList list = document.getDocumentElement().getChildNodes();
    Node item;
    for (int i = 0; i < list.getLength(); i++) {
      if ("head".equalsIgnoreCase((item = list.item(i)).getNodeName())) {
        NodeList headers = item.getChildNodes();
        for (int j = 0; j < headers.getLength(); j++) {
          if ("meta".equalsIgnoreCase((item = headers.item(j)).getNodeName())) {
            NamedNodeMap nodeMap = item.getAttributes();
            for (int k = 0; k < nodeMap.getLength(); k++) {
              if ("charset".equalsIgnoreCase((item = nodeMap.item(k)).getNodeName())) {
                return item.getNodeValue();
              }
            }
          }
        }
      }
    }
    return null;
  }

  public static class ElementValidityCheckFilter extends DefaultFilter
  {
    private NokogiriErrorHandler errorHandler;

    private
    ElementValidityCheckFilter(NokogiriErrorHandler errorHandler)
    {
      this.errorHandler = errorHandler;
    }

    // element names from xhtml1-strict.dtd
    private static String[][] element_names = {
      {"a", "abbr", "acronym", "address", "area"},
      {"b", "base", "basefont", "bdo", "big", "blockquote", "body", "br", "button"},
      {"caption", "cite", "code", "col", "colgroup"},
      {"dd", "del", "dfn", "div", "dl", "dt"},
      {"em"},
      {"fieldset", "font", "form", "frame", "frameset"},
      {}, // g
      {"h1", "h2", "h3", "h4", "h5", "h6", "head", "hr", "html"},
      {"i", "iframe", "img", "input", "ins"},
      {}, // j
      {"kbd"},
      {"label", "legend", "li", "link"},
      {"map", "meta"},
      {"noframes", "noscript"},
      {"object", "ol", "optgroup", "option"},
      {"p", "param", "pre"},
      {"q"},
      {}, // r
      {"s", "samp", "script", "select", "small", "span", "strike", "strong", "style", "sub", "sup"},
      {"table", "tbody", "td", "textarea", "tfoot", "th", "thead", "title", "tr", "tt"},
      {"u", "ul"},
      {"var"},
      {}, // w
      {}, // x
      {}, // y
      {}  // z
    };

    private static boolean
    isValid(final String name)
    {
      int index = name.charAt(0) - 97;
      if (index >= element_names.length) { return false; }
      String[] elementNames = element_names[index];
      for (int i = 0; i < elementNames.length; i++) {
        if (name.equals(elementNames[i])) {
          return true;
        }
      }
      return false;
    }

    @Override
    public void
    startElement(QName name, XMLAttributes attrs, Augmentations augs) throws XNIException
    {
      if (!isValid(name.rawname)) {
        errorHandler.addError(new Exception("Tag " + name.rawname + " invalid"));
      }
      super.startElement(name, attrs, augs);
    }
  }
}
