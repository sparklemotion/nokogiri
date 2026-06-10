package nokogiri;

import static nokogiri.internals.NokogiriHelpers.adjustSystemIdIfNecessary;
import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;

import java.io.IOException;
import java.io.InputStream;
import java.io.Reader;

import java.net.URI;
import java.net.URISyntaxException;

import javax.xml.XMLConstants;
import javax.xml.transform.Source;
import javax.xml.transform.dom.DOMSource;
import javax.xml.validation.Schema;
import javax.xml.validation.SchemaFactory;
import javax.xml.validation.Validator;

import nokogiri.internals.SchemaErrorHandler;
import nokogiri.internals.XmlDomParserContext;
import nokogiri.internals.ParserContext;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
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

  private transient Validator validator;

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
    // TODO: switch to common undeprecated API when 9.4 adds 10 methods
    long intParseOptions = RubyFixnum.fix2long(Helpers.invoke(context, parseOptions, "to_i"));

    // TODO: switch to common undeprecated API when 9.4 adds 10 methods
    xmlSchema.setInstanceVariable("@errors", runtime.newEmptyArray());
    xmlSchema.setInstanceVariable("@parse_options", parseOptions);

    try {
      SchemaErrorHandler errorHandler =
        new SchemaErrorHandler(context.getRuntime(), (RubyArray<?>)xmlSchema.getInstanceVariable("@errors"));
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
    return runtime.getClassFromPath("Nokogiri::XML::ParseOptions").getConstant("DEFAULT_SCHEMA");
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
      // TODO: switch to common undeprecated API when 9.4 adds 10 methods
      throw context.runtime.newTypeError(msg);
    }
    if (!(rbDocument instanceof XmlDocument)) {
      context.runtime.getWarnings().warn("Passing a Node as the first parameter to Schema.from_document is deprecated. Please pass a Document instead. This will become an error in Nokogiri v1.17.0."); // TODO: deprecated in v1.15.3, remove in v1.17.0
    }

    XmlDocument doc = ((XmlDocument)((XmlNode) rbDocument).document(context));

    RubyArray<?> errors = (RubyArray<?>) doc.getInstanceVariable("@errors");
    if (!errors.isEmpty()) {
      // TODO: switch to common undeprecated API when 9.4 adds 10 methods
      throw((XmlSyntaxError) errors.first()).toThrowable();
    }

    DOMSource source = new DOMSource(doc.getDocument());

    IRubyObject uri = doc.url(context);

    if (!uri.isNil()) {
      source.setSystemId(uri.convertToString().asJavaString());
    }

    return getSchema(context, (RubyClass)klazz, source, parseOptions);
  }

  private static IRubyObject
  getSchema(ThreadContext context, RubyClass klazz, Source source, IRubyObject parseOptions)
  {
    // TODO: switch to common undeprecated API when 9.4 adds 10 methods
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
    try {
      XmlDocument xmlDocument = ctx.parse(context, getNokogiriClass(runtime, "Nokogiri::XML::Document"), context.nil);
      return validate_document_or_file(context, xmlDocument);
    } catch (Exception ex) {
      // TODO: switch to common undeprecated API when 9.4 adds 10 methods
      RubyArray<?> errors = context.runtime.newEmptyArray();
      XmlSyntaxError xmlSyntaxError = XmlSyntaxError.createXMLSyntaxError(context.runtime);
      xmlSyntaxError.setException(ex);
      // TODO: switch to common undeprecated API when 9.4 adds 10 methods
      errors.append(xmlSyntaxError);
      return errors;
    }
  }

  IRubyObject
  validate_document_or_file(ThreadContext context, XmlDocument xmlDocument)
  {
    // TODO: switch to common undeprecated API when 9.4 adds 10 methods
    RubyArray<?> errors = context.runtime.newEmptyArray();
    ErrorHandler errorHandler = new SchemaErrorHandler(context.runtime, errors);
    setErrorHandler(errorHandler);

    try {
      validate(xmlDocument.getDocument());
    } catch (SAXException ex) {
      XmlSyntaxError xmlSyntaxError = XmlSyntaxError.createXMLSyntaxError(context.runtime);
      xmlSyntaxError.setException(ex);
      // TODO: switch to common undeprecated API when 9.4 adds 10 methods
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
    if (document.getDocumentElement() == null) {
      throw new SAXException("Document is empty");
    }

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
      if (noNet && !effectiveResourceIsLocal(systemId, baseURI)) {
        try {
          this.errorHandler.warning(new SAXParseException(String.format("Attempt to load network entity '%s'", systemId), null));
        } catch (SAXException ignored) {
        }
        return new SchemaLSInput(); // an empty input blocks the fetch
      }

      String adjusted = adjustSystemIdIfNecessary(currentDir, scriptFileName, baseURI, systemId);
      lsInput.setPublicId(publicId);
      lsInput.setSystemId(adjusted != null ? adjusted : systemId);
      lsInput.setBaseURI(baseURI);
      return lsInput;
    }
  }

  // We enforce NONET for schema resolution by hand because Xerces-J (the JAXP implementation
  // backing XML::Schema on JRuby) does not implement the standard JAXP property
  // XMLConstants.ACCESS_EXTERNAL_SCHEMA — so we cannot simply restrict external access on the
  // SchemaFactory and must classify each resolved resource in the LSResourceResolver instead.
  //
  // Decides whether a schema-import resource may be resolved while NONET is on: true means
  // local (allowed), false means a network resource (blocked). A relative systemId inherits
  // its document's base, so it is resolved against baseURI before classification — a relative
  // import under a remote base is a network fetch even though the systemId alone looks local.
  private static boolean
  effectiveResourceIsLocal(String systemId, String baseURI)
  {
    // a null systemId means there is nothing external to resolve
    if (systemId == null) {
      return true;
    }
    try {
      URI uri = new URI(systemId);
      if (baseURI != null && !baseURI.isEmpty()) {
        uri = new URI(baseURI).resolve(uri);
      }
      return isLocalResource(uri);
    } catch (URISyntaxException | IllegalArgumentException e) {
      // fail closed: an unparseable base or systemId (e.g. a raw UNC path "\\host\share") is
      // not provably local, and the JVM's file/URL handling may still reach the network
      return false;
    }
  }

  // Test seam for the Ruby suite: local_resource?(systemId, baseURI = nil).
  @JRubyMethod(meta = true, name = "local_resource?", required = 1, optional = 1, visibility = Visibility.PRIVATE)
  public static IRubyObject
  local_resource_eh(ThreadContext context, IRubyObject klazz, IRubyObject[] args)
  {
    String systemId = args[0].isNil() ? null : args[0].asJavaString();
    String baseURI = (args.length > 1 && !args[1].isNil()) ? args[1].asJavaString() : null;
    return context.runtime.newBoolean(effectiveResourceIsLocal(systemId, baseURI));
  }

  // Classifies an already-parsed URI. Local is a missing scheme, or the "file" scheme, with
  // no remote authority and no UNC-shaped path. This is intentionally stricter than libxml2's
  // xmlNoNetExternalEntityLoader, which folds a remote host (file://host/...) into a local
  // path rather than rejecting it.
  //
  // TODO: a Windows drive-letter path like "C:\path" parses as scheme "c" and would be
  // blocked; support those if we need it later.
  private static boolean
  isLocalResource(URI uri)
  {
    // only a missing scheme (a relative or absolute path) or file: can be local; any
    // other scheme is a network resource
    String scheme = uri.getScheme();
    if (scheme != null && !scheme.equalsIgnoreCase("file")) {
      return false;
    }

    // an opaque "file:" URI (e.g. file:foo, with no "//") is not a usable local path; reject
    // it, matching libxml2, which does not resolve that form as a local file either
    if (uri.isOpaque()) {
      return false;
    }

    // a non-empty, non-localhost authority is a remote host — file://host/path, or the
    // schemeless network-path form //host/path. Stricter than libxml2, which folds such a
    // host into a (failing) local path.
    String authority = uri.getRawAuthority();
    if (authority != null && !authority.isEmpty() && !authority.equalsIgnoreCase("localhost")) {
      return false;
    }

    // reject UNC-shaped paths even under an allowed authority: file:////host/share,
    // file://localhost//host/share, and %2f/%5c-encoded variants. getPath() is decoded, so
    // the encoded forms are normalized before this check.
    String path = uri.getPath();
    if (path != null && (path.startsWith("//") || path.indexOf('\\') >= 0)) {
      return false;
    }

    return true;
  }

  private static class SchemaLSInput implements LSInput
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
