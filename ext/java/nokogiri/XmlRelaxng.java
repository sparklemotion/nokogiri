package nokogiri;

import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.StringWriter;
import java.io.UnsupportedEncodingException;

import javax.xml.transform.Source;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

import org.iso_relax.verifier.Schema;
import org.iso_relax.verifier.Verifier;
import org.iso_relax.verifier.VerifierConfigurationException;
import org.iso_relax.verifier.VerifierFactory;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;
import org.xml.sax.ErrorHandler;
import org.xml.sax.SAXException;

/**
 * Class for Nokogiri::XML::RelaxNG
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */
@JRubyClass(name = "Nokogiri::XML::RelaxNG", parent = "Nokogiri::XML::Schema")
public class XmlRelaxng extends XmlSchema
{
  private static final long serialVersionUID = 1L;
  private Verifier verifier;

  public
  XmlRelaxng(Ruby ruby, RubyClass klazz)
  {
    super(ruby, klazz);
  }

  private void
  setVerifier(Verifier verifier)
  {
    this.verifier = verifier;
  }

  static XmlSchema
  createSchemaInstance(ThreadContext context, RubyClass klazz, Source source, IRubyObject parseOptions)
  {
    Ruby runtime = context.getRuntime();
    XmlRelaxng xmlRelaxng = (XmlRelaxng) NokogiriService.XML_RELAXNG_ALLOCATOR.allocate(runtime, klazz);

    if (parseOptions == null) {
      parseOptions = defaultParseOptions(context.getRuntime());
    }

    xmlRelaxng.setInstanceVariable("@errors", runtime.newEmptyArray());
    xmlRelaxng.setInstanceVariable("@parse_options", parseOptions);

    try {
      Schema schema = xmlRelaxng.getSchema(source, context);
      xmlRelaxng.setVerifier(schema.newVerifier());
      return xmlRelaxng;
    } catch (VerifierConfigurationException ex) {
      throw context.getRuntime().newRuntimeError("Could not parse document: " + ex.getMessage());
    }
  }

  private Schema
  getSchema(Source source, ThreadContext context)
  {
    InputStream is;
    VerifierFactory factory = new com.thaiopensource.relaxng.jarv.VerifierFactoryImpl();
    if (source instanceof StreamSource) {
      StreamSource ss = (StreamSource)source;
      is = ss.getInputStream();
    } else { //if (this.source instanceof DOMSource)
      DOMSource ds = (DOMSource)source;
      StringWriter xmlAsWriter = new StringWriter();
      StreamResult result = new StreamResult(xmlAsWriter);
      try {
        TransformerFactory.newInstance().newTransformer().transform(ds, result);
      } catch (TransformerConfigurationException ex) {
        throw context.getRuntime()
        .newRuntimeError("Could not parse document: " + ex.getMessage());
      } catch (TransformerException ex) {
        throw context.getRuntime()
        .newRuntimeError("Could not parse document: " + ex.getMessage());
      }
      try {
        is = new ByteArrayInputStream(xmlAsWriter.toString().getBytes("UTF-8"));
      } catch (UnsupportedEncodingException ex) {
        throw context.getRuntime()
        .newRuntimeError("Could not parse document: " + ex.getMessage());
      }
    }

    try {
      return factory.compileSchema(is);
    } catch (VerifierConfigurationException ex) {
      throw context.getRuntime()
      .newRuntimeError("Could not parse document: " + ex.getMessage());
    } catch (SAXException ex) {
      throw context.getRuntime()
      .newRuntimeError("Could not parse document: " + ex.getMessage());
    } catch (IOException ex) {
      throw context.getRuntime().newIOError(ex.getClass() + ": " + ex.getMessage());
    }
  }

  @Override
  protected void
  setErrorHandler(ErrorHandler errorHandler)
  {
    verifier.setErrorHandler(errorHandler);
  }

  @Override
  protected void
  validate(Document document) throws SAXException, IOException
  {
    verifier.verify(document);
  }
}
