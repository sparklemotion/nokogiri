package nokogiri;

import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;
import static nokogiri.internals.NokogiriHelpers.stringOrBlank;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PipedReader;
import java.io.PipedWriter;
import java.io.StringReader;
import java.util.Set;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.xml.transform.OutputKeys;
import javax.xml.transform.Templates;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMResult;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

import org.apache.xml.serializer.SerializationHandler;
import org.apache.xml.serializer.Serializer;
import org.apache.xml.serializer.SerializerFactory;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Helpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;

import nokogiri.internals.NokogiriXsltErrorListener;

/**
 * Class for Nokogiri::XSLT::Stylesheet
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */
@JRubyClass(name = "Nokogiri::XSLT::Stylesheet")
public class XsltStylesheet extends RubyObject
{
  private static final long serialVersionUID = 1L;

  private TransformerFactory factory = null;
  private Templates sheet = null;
  private IRubyObject stylesheet = null;
  private boolean htmlish = false;

  public
  XsltStylesheet(Ruby ruby, RubyClass rubyClass)
  {
    super(ruby, rubyClass);
  }

  /**
   * Create and return a copy of this object.
   *
   * @return a clone of this object
   */
  @Override
  public Object
  clone() throws CloneNotSupportedException
  {
    return super.clone();
  }

  private void
  addParametersToTransformer(ThreadContext context, Transformer transf, IRubyObject parameters)
  {
    if (parameters instanceof RubyHash) {
      setHashParameters(transf, (RubyHash)parameters);
    } else if (parameters instanceof RubyArray) {
      setArrayParameters(transf, context, (RubyArray)parameters);
    } else {
      throw context.getRuntime().newTypeError("parameters should be given either Array or Hash");
    }
  }

  @SuppressWarnings("unchecked")
  private void
  setHashParameters(Transformer transformer, RubyHash hash)
  {
    for (Map.Entry<Object, Object> entry : (Set<Map.Entry<Object, Object>>)hash.entrySet()) {
      transformer.setParameter((String)entry.getKey(), unparseValue((String)entry.getValue()));
    }
  }

  private void
  setArrayParameters(Transformer transformer, ThreadContext context, RubyArray<?> params)
  {
    int limit = params.getLength();
    if (limit % 2 == 1) { limit--; }

    for (int i = 0; i < limit; i += 2) {
      String name = params.aref(context, context.getRuntime().newFixnum(i)).asJavaString();
      String value = params.aref(context, context.getRuntime().newFixnum(i + 1)).asJavaString();
      transformer.setParameter(name, unparseValue(value));
    }
  }

  private static final Pattern QUOTED = Pattern.compile("'.{1,}'");

  private String
  unparseValue(String orig)
  {
    if ((orig.startsWith("\"") && orig.endsWith("\"")) || QUOTED.matcher(orig).matches()) {
      orig = orig.substring(1, orig.length() - 1);
    }

    return orig;
  }

  @JRubyMethod(meta = true, rest = true)
  public static IRubyObject
  parse_stylesheet_doc(ThreadContext context, IRubyObject klazz, IRubyObject[] args)
  {

    Ruby runtime = context.getRuntime();

    ensureFirstArgIsDocument(runtime, args[0]);

    XmlDocument xmlDoc = (XmlDocument) args[0];
    ensureDocumentHasNoError(context, xmlDoc);

    Document doc = ((XmlDocument) xmlDoc.dup_implementation(context, true)).getDocument();

    XsltStylesheet xslt =
      (XsltStylesheet) NokogiriService.XSLT_STYLESHEET_ALLOCATOR.allocate(runtime, (RubyClass)klazz);

    try {
      xslt.init(args[1], doc);
    } catch (TransformerConfigurationException ex) {
      throw runtime.newRuntimeError("could not parse xslt stylesheet");
    }

    return xslt;
  }

  private void
  init(IRubyObject stylesheet, Document document) throws TransformerConfigurationException
  {
    this.stylesheet = stylesheet;  // either RubyString or RubyFile
    if (factory == null) { factory = TransformerFactory.newInstance(); }
    NokogiriXsltErrorListener elistener = new NokogiriXsltErrorListener();
    factory.setErrorListener(elistener);
    sheet = factory.newTemplates(new DOMSource(document));
  }

  private static void
  ensureFirstArgIsDocument(Ruby runtime, IRubyObject arg)
  {
    if (arg instanceof XmlDocument) { return; }
    throw runtime.newArgumentError("doc must be a Nokogiri::XML::Document instance");
  }

  private static void
  ensureDocumentHasNoError(ThreadContext context, XmlDocument xmlDoc)
  {
    Ruby runtime = context.getRuntime();
    RubyArray<?> errors_of_xmlDoc = (RubyArray) xmlDoc.getInstanceVariable("@errors");
    if (!errors_of_xmlDoc.isEmpty()) {
      throw runtime.newRuntimeError(errors_of_xmlDoc.first().asString().asJavaString());
    }
  }

  @JRubyMethod
  public IRubyObject
  serialize(ThreadContext context, IRubyObject doc) throws IOException
  {
    XmlDocument xmlDoc = (XmlDocument) doc;
    ByteArrayOutputStream writer = new ByteArrayOutputStream();

    java.util.Properties props = this.sheet.getOutputProperties();
    if (props.getProperty(OutputKeys.METHOD) == null) {
      props.setProperty(OutputKeys.METHOD, org.apache.xml.serializer.Method.UNKNOWN);
    }

    Serializer serializer = SerializerFactory.getSerializer(props);
    serializer.setOutputStream(writer);
    ((SerializationHandler) serializer).serialize(xmlDoc.getNode());

    return context.getRuntime().newString(writer.toString());
  }

  @JRubyMethod(rest = true, required = 1, optional = 2)
  public IRubyObject
  transform(ThreadContext context, IRubyObject[] args)
  {
    Ruby runtime = context.getRuntime();

    argumentTypeCheck(runtime, args[0]);

    NokogiriXsltErrorListener elistener = new NokogiriXsltErrorListener();
    DOMSource domSource = new DOMSource(((XmlDocument) args[0]).getDocument());
    final DOMResult result;
    String stringResult = null;
    try {
      result = tryXsltTransformation(context, args, domSource, elistener); // DOMResult
      if (result.getNode().getFirstChild() == null) {
        stringResult = retryXsltTransformation(context, args, domSource, elistener); // StreamResult
      }
    } catch (TransformerConfigurationException ex) {
      throw runtime.newRuntimeError(ex.getMessage());
    } catch (TransformerException ex) {
      throw runtime.newRuntimeError(ex.getMessage());
    } catch (IOException ex) {
      throw runtime.newRuntimeError(ex.getMessage());
    }

    switch (elistener.getErrorType()) {
      case ERROR:
      case FATAL:
        throw runtime.newRuntimeError(elistener.getErrorMessage());
      case WARNING:
      default:
        // no-op
    }

    if (stringResult == null) {
      return createDocumentFromDomResult(context, runtime, result);
    } else {
      return createDocumentFromString(context, runtime, stringResult);
    }
  }

  private DOMResult
  tryXsltTransformation(ThreadContext context, IRubyObject[] args, DOMSource domSource,
                        NokogiriXsltErrorListener elistener) throws TransformerException
  {
    Transformer transf = sheet.newTransformer();
    transf.reset();
    transf.setErrorListener(elistener);
    if (args.length > 1) {
      addParametersToTransformer(context, transf, args[1]);
    }

    DOMResult result = new DOMResult();
    transf.transform(domSource, result);
    return result;
  }

  private String
  retryXsltTransformation(ThreadContext context,
                          IRubyObject[] args,
                          DOMSource domSource,
                          NokogiriXsltErrorListener elistener)
  throws TransformerException, IOException
  {
    Templates templates = getTemplatesFromStreamSource();
    Transformer transf = templates.newTransformer();
    transf.setErrorListener(elistener);
    if (args.length > 1) {
      addParametersToTransformer(context, transf, args[1]);
    }
    PipedWriter pwriter = new PipedWriter();
    PipedReader preader = new PipedReader();
    pwriter.connect(preader);
    StreamResult result = new StreamResult(pwriter);
    transf.transform(domSource, result);

    char[] cbuf = new char[1024];
    int len = preader.read(cbuf, 0, 1024);
    StringBuilder builder = new StringBuilder(len);
    builder.append(cbuf, 0, len);
    htmlish = isHtml(builder); // judge from the first chunk

    while (len == 1024) {
      len = preader.read(cbuf, 0, 1024);
      if (len > 0) {
        builder.append(cbuf, 0, len);
      }
    }

    preader.close();
    pwriter.close();

    return builder.toString();
  }

  private IRubyObject
  createDocumentFromDomResult(ThreadContext context, Ruby runtime, DOMResult domResult)
  {
    if ("html".equals(domResult.getNode().getFirstChild().getNodeName())) {
      return new Html4Document(context.runtime, (Document) domResult.getNode());
    } else {
      return new XmlDocument(context.runtime, (Document) domResult.getNode());
    }
  }

  private Templates
  getTemplatesFromStreamSource() throws TransformerConfigurationException
  {
    if (stylesheet instanceof RubyString) {
      StringReader reader = new StringReader(stylesheet.asJavaString());
      StreamSource xsltStreamSource = new StreamSource(reader);
      return factory.newTemplates(xsltStreamSource);
    }
    return null;
  }

  private static final Pattern HTML_TAG = Pattern.compile("<(%s)*html", Pattern.CASE_INSENSITIVE);

  private static boolean
  isHtml(CharSequence chunk)
  {
    Matcher match = HTML_TAG.matcher(chunk);
    return match.find();
  }

  private IRubyObject
  createDocumentFromString(ThreadContext context, Ruby runtime, String stringResult)
  {
    IRubyObject[] args = new IRubyObject[4];
    args[0] = stringOrBlank(runtime, stringResult);
    args[1] = runtime.getNil();  // url
    args[2] = runtime.getNil();  // encoding
    RubyClass parse_options = (RubyClass)runtime.getClassFromPath("Nokogiri::XML::ParseOptions");
    if (htmlish) {
      args[3] = parse_options.getConstant("DEFAULT_HTML");
      RubyClass htmlDocumentClass = getNokogiriClass(runtime, "Nokogiri::HTML4::Document");
      return Helpers.invoke(context, htmlDocumentClass, "parse", args);
    } else {
      args[3] = parse_options.getConstant("DEFAULT_XML");
      RubyClass xmlDocumentClass = getNokogiriClass(runtime, "Nokogiri::XML::Document");
      XmlDocument xmlDocument = (XmlDocument) Helpers.invoke(context, xmlDocumentClass, "parse", args);
      if (((Document)xmlDocument.getNode()).getDocumentElement() == null) {
        RubyArray<?> errors = (RubyArray) xmlDocument.getInstanceVariable("@errors");
        Helpers.invoke(context, errors, "<<", args[0]);
      }
      return xmlDocument;
    }
  }

  private static void
  argumentTypeCheck(Ruby runtime, IRubyObject arg)
  {
    if (arg instanceof XmlDocument) { return; }
    throw runtime.newArgumentError("argument must be a Nokogiri::XML::Document");
  }
}
