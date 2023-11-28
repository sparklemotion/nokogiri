package nokogiri;

import static nokogiri.internals.NokogiriHelpers.adjustSystemIdIfNecessary;
import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;

import java.io.IOException;
import java.io.InputStream;
import java.io.Reader;
import java.io.StringReader;

import javax.xml.XMLConstants;
import javax.xml.transform.Source;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamSource;
import javax.xml.validation.Schema;
import javax.xml.validation.SchemaFactory;
import javax.xml.validation.Validator;

import nokogiri.internals.IgnoreSchemaErrorsErrorHandler;
import nokogiri.internals.SchemaErrorHandler;
import nokogiri.internals.XmlDomParserContext;
import nokogiri.internals.ParserContext;
import nokogiri.internals.ParserContext.Options;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.Visibility;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.Helpers;
import org.w3c.dom.Document;
import org.w3c.dom.ls.LSInput;
import org.w3c.dom.ls.LSResourceResolver;
import org.xml.sax.ErrorHandler;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;

/**
 * Class for Nokogiri::XML::Schema
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */
@JRubyClass(name = "Nokogiri::XML::Schema")
public class XmlSchema extends RubyObject
{
  private static final long serialVersionUID = 1L;

  private Validator validator;

  public
  XmlSchema(Ruby ruby, RubyClass klazz)
  {
    super(ruby, klazz);
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

  private Schema
  getSchema(Source source,
            String currentDir,
            String scriptFileName,
            SchemaErrorHandler errorHandler,
            long parseOptions) throws SAXException
  {
    boolean noNet = new ParserContext.Options(parseOptions).noNet;

    SchemaFactory schemaFactory = SchemaFactory.newInstance(XMLConstants.W3C_XML_SCHEMA_NS_URI);
    SchemaResourceResolver resourceResolver =
      new SchemaResourceResolver(currentDir, scriptFileName, null, errorHandler, noNet);

    schemaFactory.setResourceResolver(resourceResolver);
    schemaFactory.setErrorHandler(errorHandler);

    return schemaFactory.newSchema(source);
  }

  private void
  setValidator(Validator validator)
  {
    this.validator = validator;
  }

  static XmlSchema
  createSchemaInstance(ThreadContext context, RubyClass klazz, Source source, IRubyObject parseOptions)
  {
    Ruby runtime = context.getRuntime();
    XmlSchema xmlSchema = (XmlSchema) NokogiriService.XML_SCHEMA_ALLOCATOR.allocate(runtime, klazz);

    if (parseOptions == null) {
      parseOptions = defaultParseOptions(context.getRuntime());
    }
    long intParseOptions = RubyFixnum.fix2long(Helpers.invoke(context, parseOptions, "to_i"));

    xmlSchema.setInstanceVariable("@errors", runtime.newEmptyArray());
    xmlSchema.setInstanceVariable("@parse_options", parseOptions);

    try {
      SchemaErrorHandler errorHandler =
        new SchemaErrorHandler(context.getRuntime(), (RubyArray)xmlSchema.getInstanceVariable("@errors"));
      Schema schema =
        xmlSchema.getSchema(source,
                            context.getRuntime().getCurrentDirectory(),
                            context.getRuntime().getInstanceConfig().getScriptFileName(),
                            errorHandler,
                            intParseOptions);
      xmlSchema.setValidator(schema.newValidator());
      return xmlSchema;
    } catch (SAXException ex) {
      throw context.getRuntime().newRuntimeError("Could not parse document: " + ex.getMessage());
    }
  }

  protected static IRubyObject
  defaultParseOptions(Ruby runtime)
  {
    return ((RubyClass)runtime.getClassFromPath("Nokogiri::XML::ParseOptions")).getConstant("DEFAULT_SCHEMA");
  }

  /*
   * call-seq:
   *  from_document(doc)
   *
   * Create a new Schema from the Nokogiri::XML::Document +doc+
   */
  @JRubyMethod(meta = true, required = 1, optional = 1)
  public static IRubyObject
  from_document(ThreadContext context, IRubyObject klazz, IRubyObject[] args)
  {
    IRubyObject rbDocument = args[0];
    IRubyObject parseOptions = null;
    if (args.length > 1) {
      parseOptions = args[1];
    }

    if (!(rbDocument instanceof XmlNode)) {
      String msg = "expected parameter to be a Nokogiri::XML::Document, received " + rbDocument.getMetaClass();
      throw context.runtime.newTypeError(msg);
    }
    if (!(rbDocument instanceof XmlDocument)) {
      context.runtime.getWarnings().warn("Passing a Node as the first parameter to Schema.from_document is deprecated. Please pass a Document instead. This will become an error in Nokogiri v1.17.0."); // TODO: deprecated in v1.15.3, remove in v1.17.0
    }

    XmlDocument doc = ((XmlDocument)((XmlNode) rbDocument).document(context));

    RubyArray<?> errors = (RubyArray) doc.getInstanceVariable("@errors");
    if (!errors.isEmpty()) {
      throw((XmlSyntaxError) errors.first()).toThrowable();
    }

    DOMSource source = new DOMSource(doc.getDocument());

    IRubyObject uri = doc.url(context);

    if (!uri.isNil()) {
      source.setSystemId(uri.convertToString().asJavaString());
    }

    return getSchema(context, (RubyClass)klazz, source, parseOptions);
  }

  @JRubyMethod(meta = true, required = 1, optional = 1)
  public static IRubyObject
  read_memory(ThreadContext context, IRubyObject klazz, IRubyObject[] args)
  {
    IRubyObject content = args[0];
    IRubyObject parseOptions = null;
    if (args.length > 1) {
      parseOptions = args[1];
    }
    String data = content.convertToString().asJavaString();
    return getSchema(context, (RubyClass) klazz, new StreamSource(new StringReader(data)), parseOptions);
  }

  private static IRubyObject
  getSchema(ThreadContext context, RubyClass klazz, Source source, IRubyObject parseOptions)
  {
    String moduleName = klazz.getName();
    if ("Nokogiri::XML::Schema".equals(moduleName)) {
      return XmlSchema.createSchemaInstance(context, klazz, source, parseOptions);
    } else if ("Nokogiri::XML::RelaxNG".equals(moduleName)) {
      return XmlRelaxng.createSchemaInstance(context, klazz, source, parseOptions);
    }
    return context.getRuntime().getNil();
  }

  @JRubyMethod(visibility = Visibility.PRIVATE)
  public IRubyObject
  validate_document(ThreadContext context, IRubyObject document)
  {
    return validate_document_or_file(context, (XmlDocument)document);
  }

  @JRubyMethod(visibility = Visibility.PRIVATE)
  public IRubyObject
  validate_file(ThreadContext context, IRubyObject file)
  {
    Ruby runtime = context.runtime;

    XmlDomParserContext ctx = new XmlDomParserContext(runtime, RubyFixnum.newFixnum(runtime, 1L));
    ctx.setInputSourceFile(context, file);
    XmlDocument xmlDocument = ctx.parse(context, getNokogiriClass(runtime, "Nokogiri::XML::Document"), context.nil);
    return validate_document_or_file(context, xmlDocument);
  }

  IRubyObject
  validate_document_or_file(ThreadContext context, XmlDocument xmlDocument)
  {
    RubyArray<?> errors = (RubyArray) this.getInstanceVariable("@errors");
    ErrorHandler errorHandler = new SchemaErrorHandler(context.runtime, errors);
    setErrorHandler(errorHandler);

    try {
      validate(xmlDocument.getDocument());
    } catch (SAXException ex) {
      XmlSyntaxError xmlSyntaxError = XmlSyntaxError.createXMLSyntaxError(context.runtime);
      xmlSyntaxError.setException(ex);
      errors.append(xmlSyntaxError);
    } catch (IOException ex) {
      throw context.runtime.newIOError(ex.getMessage());
    }

    return errors;
  }

  protected void
  setErrorHandler(ErrorHandler errorHandler)
  {
    validator.setErrorHandler(errorHandler);
  }

  protected void
  validate(Document document) throws SAXException, IOException
  {
    DOMSource docSource = new DOMSource(document);
    validator.validate(docSource);
  }

  private class SchemaResourceResolver implements LSResourceResolver
  {
    SchemaLSInput lsInput = new SchemaLSInput();
    String currentDir;
    String scriptFileName;
    SchemaErrorHandler errorHandler;
    boolean noNet;
    //String defaultURI;

    SchemaResourceResolver(String currentDir, String scriptFileName, Object input, SchemaErrorHandler errorHandler,
                           boolean noNet)
    {
      this.currentDir = currentDir;
      this.scriptFileName = scriptFileName;
      this.errorHandler = errorHandler;
      this.noNet = noNet;
      if (input == null) { return; }
      if (input instanceof String) {
        lsInput.setStringData((String)input);
      } else if (input instanceof Reader) {
        lsInput.setCharacterStream((Reader)input);
      } else if (input instanceof InputStream) {
        lsInput.setByteStream((InputStream)input);
      }
    }

    @Override
    public LSInput
    resolveResource(String type,
                    String namespaceURI,
                    String publicId,
                    String systemId,
                    String baseURI)
    {
      if (noNet && systemId != null && (systemId.startsWith("http://") || systemId.startsWith("ftp://"))) {
        if (systemId.startsWith(XMLConstants.W3C_XML_SCHEMA_NS_URI)) {
          return null; // use default resolver
        }
        try {
          this.errorHandler.warning(new SAXParseException(String.format("Attempt to load network entity '%s'", systemId), null));
        } catch (SAXException ex) {
        }
      } else {
        String adjusted = adjustSystemIdIfNecessary(currentDir, scriptFileName, baseURI, systemId);
        lsInput.setPublicId(publicId);
        lsInput.setSystemId(adjusted != null ? adjusted : systemId);
        lsInput.setBaseURI(baseURI);
      }
      return lsInput;
    }
  }

  private class SchemaLSInput implements LSInput
  {
    protected String fPublicId;
    protected String fSystemId;
    protected String fBaseSystemId;
    protected InputStream fByteStream;
    protected Reader fCharStream;
    protected String fData;
    protected String fEncoding;
    protected boolean fCertifiedText = false;

    @Override
    public String
    getBaseURI()
    {
      return fBaseSystemId;
    }

    @Override
    public InputStream
    getByteStream()
    {
      return fByteStream;
    }

    @Override
    public boolean
    getCertifiedText()
    {
      return fCertifiedText;
    }

    @Override
    public Reader
    getCharacterStream()
    {
      return fCharStream;
    }

    @Override
    public String
    getEncoding()
    {
      return fEncoding;
    }

    @Override
    public String
    getPublicId()
    {
      return fPublicId;
    }

    @Override
    public String
    getStringData()
    {
      return fData;
    }

    @Override
    public String
    getSystemId()
    {
      return fSystemId;
    }

    @Override
    public void
    setBaseURI(String baseURI)
    {
      fBaseSystemId = baseURI;
    }

    @Override
    public void
    setByteStream(InputStream byteStream)
    {
      fByteStream = byteStream;
    }

    @Override
    public void
    setCertifiedText(boolean certified)
    {
      fCertifiedText = certified;
    }

    @Override
    public void
    setCharacterStream(Reader charStream)
    {
      fCharStream = charStream;
    }

    @Override
    public void
    setEncoding(String encoding)
    {
      fEncoding = encoding;
    }

    @Override
    public void
    setPublicId(String pubId)
    {
      fPublicId = pubId;
    }

    @Override
    public void
    setStringData(String stringData)
    {
      fData = stringData;
    }

    @Override
    public void
    setSystemId(String sysId)
    {
      fSystemId = sysId;
    }

  }
}
