package nokogiri.internals;

import org.apache.xerces.parsers.DOMParser;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import org.xml.sax.SAXException;

import nokogiri.XmlDocument;

/**
 * Parser class for XML DOM processing. This class actually parses XML document
 * and creates DOM tree in Java side. However, DOM tree in Ruby side is not since
 * we delay creating objects for performance.
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class XmlDomParserContext extends DomParserContext<DOMParser>
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

  public
  XmlDomParserContext(Ruby runtime, IRubyObject options)
  {
    this(runtime, options, runtime.getNil());
  }

  public
  XmlDomParserContext(Ruby runtime, IRubyObject parserOptions, IRubyObject encoding)
  {
    super(runtime, parserOptions, encoding);

    initParser(runtime);
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

    if (options.noBlanks) {
      setFeature(FEATURE_INCLUDE_IGNORABLE_WHITESPACE, false);
    }

    if (options.recover) {
      setFeature(CONTINUE_AFTER_FATAL_ERROR, true);
    }

    if (options.dtdValid) {
      setFeature(FEATURE_VALIDATION, true);
    }

    if (!options.noEnt) {
      setFeature(FEATURE_NOT_EXPAND_ENTITY, true);
    }
    // If we turn off loading of external DTDs complete, we don't
    // getthe publicID.  Instead of turning off completely, we use
    // an entity resolver that returns empty documents.
    if (options.dtdLoad) {
      setFeature(FEATURE_LOAD_EXTERNAL_DTD, true);
      setFeature(FEATURE_LOAD_DTD_GRAMMAR, true);
    }
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

  /**
   * Must call setInputSource() before this method.
   */
  @Override
  public XmlDocument
  parse(ThreadContext context, RubyClass klass, IRubyObject url)
  {
    return super.parse(context, klass, url);
  }
}
