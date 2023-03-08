package nokogiri;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyModule;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.BasicLibraryService;

/**
 * Class to provide Nokogiri. This class is used to make "require 'nokogiri'" work
 * in JRuby. Also, this class holds a Ruby type cache and allocators of Ruby types.
 *
 * @author headius
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class NokogiriService implements BasicLibraryService
{
  public boolean
  basicLoad(Ruby ruby)
  {
    init(ruby);
    return true;
  }

  @SuppressWarnings("unchecked")
  public static Map<String, RubyClass>
  getNokogiriClassCache(Ruby ruby)
  {
    return (Map<String, RubyClass>) ruby.getModule("Nokogiri").getInternalVariable("cache");
  }

  private static Map<String, RubyClass>
  populateNokogiriClassCahce(Ruby ruby)
  {
    Map<String, RubyClass> nokogiriClassCache = new HashMap<String, RubyClass>();
    nokogiriClassCache.put("Nokogiri::HTML4::Document", (RubyClass)ruby.getClassFromPath("Nokogiri::HTML4::Document"));
    nokogiriClassCache.put("Nokogiri::HTML4::ElementDescription",
                           (RubyClass)ruby.getClassFromPath("Nokogiri::HTML4::ElementDescription"));
    nokogiriClassCache.put("Nokogiri::XML::Attr", (RubyClass)ruby.getClassFromPath("Nokogiri::XML::Attr"));
    nokogiriClassCache.put("Nokogiri::XML::Document", (RubyClass)ruby.getClassFromPath("Nokogiri::XML::Document"));
    nokogiriClassCache.put("Nokogiri::XML::DocumentFragment",
                           (RubyClass)ruby.getClassFromPath("Nokogiri::XML::DocumentFragment"));
    nokogiriClassCache.put("Nokogiri::XML::DTD", (RubyClass)ruby.getClassFromPath("Nokogiri::XML::DTD"));
    nokogiriClassCache.put("Nokogiri::XML::Text", (RubyClass)ruby.getClassFromPath("Nokogiri::XML::Text"));
    nokogiriClassCache.put("Nokogiri::XML::Comment", (RubyClass)ruby.getClassFromPath("Nokogiri::XML::Comment"));
    nokogiriClassCache.put("Nokogiri::XML::Element", (RubyClass)ruby.getClassFromPath("Nokogiri::XML::Element"));
    nokogiriClassCache.put("Nokogiri::XML::ElementContent",
                           (RubyClass)ruby.getClassFromPath("Nokogiri::XML::ElementContent"));
    nokogiriClassCache.put("Nokogiri::XML::ElementDecl", (RubyClass)ruby.getClassFromPath("Nokogiri::XML::ElementDecl"));
    nokogiriClassCache.put("Nokogiri::XML::EntityDecl", (RubyClass)ruby.getClassFromPath("Nokogiri::XML::EntityDecl"));
    nokogiriClassCache.put("Nokogiri::XML::EntityReference",
                           (RubyClass)ruby.getClassFromPath("Nokogiri::XML::EntityReference"));
    nokogiriClassCache.put("Nokogiri::XML::ProcessingInstruction",
                           (RubyClass)ruby.getClassFromPath("Nokogiri::XML::ProcessingInstruction"));
    nokogiriClassCache.put("Nokogiri::XML::CDATA", (RubyClass)ruby.getClassFromPath("Nokogiri::XML::CDATA"));
    nokogiriClassCache.put("Nokogiri::XML::Node", (RubyClass)ruby.getClassFromPath("Nokogiri::XML::Node"));
    nokogiriClassCache.put("Nokogiri::XML::NodeSet", (RubyClass)ruby.getClassFromPath("Nokogiri::XML::NodeSet"));
    nokogiriClassCache.put("Nokogiri::XML::Namespace", (RubyClass)ruby.getClassFromPath("Nokogiri::XML::Namespace"));
    nokogiriClassCache.put("Nokogiri::XML::SyntaxError", (RubyClass)ruby.getClassFromPath("Nokogiri::XML::SyntaxError"));
    nokogiriClassCache.put("Nokogiri::XML::Reader", (RubyClass)ruby.getClassFromPath("Nokogiri::XML::Reader"));
    nokogiriClassCache.put("Nokogiri::XML::RelaxNG", (RubyClass)ruby.getClassFromPath("Nokogiri::XML::RelaxNG"));
    nokogiriClassCache.put("Nokogiri::XML::Schema", (RubyClass)ruby.getClassFromPath("Nokogiri::XML::Schema"));
    nokogiriClassCache.put("Nokogiri::XML::XPathContext", (RubyClass)ruby.getClassFromPath("Nokogiri::XML::XPathContext"));
    nokogiriClassCache.put("Nokogiri::XML::AttributeDecl",
                           (RubyClass)ruby.getClassFromPath("Nokogiri::XML::AttributeDecl"));
    nokogiriClassCache.put("Nokogiri::XML::SAX::ParserContext",
                           (RubyClass)ruby.getClassFromPath("Nokogiri::XML::SAX::ParserContext"));
    return Collections.unmodifiableMap(nokogiriClassCache);
  }

  private void
  init(Ruby ruby)
  {
    RubyModule nokogiri = ruby.defineModule("Nokogiri");
    RubyModule xmlModule = nokogiri.defineModuleUnder("XML");
    RubyModule xmlSaxModule = xmlModule.defineModuleUnder("SAX");
    RubyModule htmlModule = nokogiri.defineModuleUnder("HTML4");
    RubyModule htmlSaxModule = htmlModule.defineModuleUnder("SAX");
    RubyModule xsltModule = nokogiri.defineModuleUnder("XSLT");

    createSyntaxErrors(ruby, nokogiri, xmlModule);
    RubyClass xmlNode = createXmlModule(ruby, xmlModule);
    createHtmlModule(ruby, htmlModule);
    createDocuments(ruby, xmlModule, htmlModule, xmlNode);
    createSaxModule(ruby, xmlSaxModule, htmlSaxModule);
    createXsltModule(ruby, xsltModule);
    nokogiri.setInternalVariable("cache", populateNokogiriClassCahce(ruby));
  }

  private void
  createSyntaxErrors(Ruby ruby, RubyModule nokogiri, RubyModule xmlModule)
  {
    RubyClass syntaxError = nokogiri.defineClassUnder("SyntaxError", ruby.getStandardError(),
                            ruby.getStandardError().getAllocator());
    RubyClass xmlSyntaxError = xmlModule.defineClassUnder("SyntaxError", syntaxError, XML_SYNTAXERROR_ALLOCATOR);
    xmlSyntaxError.defineAnnotatedMethods(XmlSyntaxError.class);
  }

  private RubyClass
  createXmlModule(Ruby ruby, RubyModule xmlModule)
  {
    RubyClass node = xmlModule.defineClassUnder("Node", ruby.getObject(), XML_NODE_ALLOCATOR);
    node.defineAnnotatedMethods(XmlNode.class);

    RubyClass attr = xmlModule.defineClassUnder("Attr", node, XML_ATTR_ALLOCATOR);
    attr.defineAnnotatedMethods(XmlAttr.class);

    RubyClass attrDecl = xmlModule.defineClassUnder("AttributeDecl", node, XML_ATTRIBUTE_DECL_ALLOCATOR);
    attrDecl.defineAnnotatedMethods(XmlAttributeDecl.class);

    RubyClass characterData = xmlModule.defineClassUnder("CharacterData", node, null);

    RubyClass comment = xmlModule.defineClassUnder("Comment", characterData, XML_COMMENT_ALLOCATOR);
    comment.defineAnnotatedMethods(XmlComment.class);

    RubyClass text = xmlModule.defineClassUnder("Text", characterData, XML_TEXT_ALLOCATOR);
    text.defineAnnotatedMethods(XmlText.class);

    RubyModule cdata = xmlModule.defineClassUnder("CDATA", text, XML_CDATA_ALLOCATOR);
    cdata.defineAnnotatedMethods(XmlCdata.class);

    RubyClass dtd = xmlModule.defineClassUnder("DTD", node, XML_DTD_ALLOCATOR);
    dtd.defineAnnotatedMethods(XmlDtd.class);

    RubyClass documentFragment = xmlModule.defineClassUnder("DocumentFragment", node, XML_DOCUMENT_FRAGMENT_ALLOCATOR);
    documentFragment.defineAnnotatedMethods(XmlDocumentFragment.class);

    RubyClass element = xmlModule.defineClassUnder("Element", node, XML_ELEMENT_ALLOCATOR);
    element.defineAnnotatedMethods(XmlElement.class);

    RubyClass elementContent = xmlModule.defineClassUnder("ElementContent", ruby.getObject(),
                               XML_ELEMENT_CONTENT_ALLOCATOR);
    elementContent.defineAnnotatedMethods(XmlElementContent.class);

    RubyClass elementDecl = xmlModule.defineClassUnder("ElementDecl", node, XML_ELEMENT_DECL_ALLOCATOR);
    elementDecl.defineAnnotatedMethods(XmlElementDecl.class);

    RubyClass entityDecl = xmlModule.defineClassUnder("EntityDecl", node, XML_ENTITY_DECL_ALLOCATOR);
    entityDecl.defineAnnotatedMethods(XmlEntityDecl.class);

    entityDecl.defineConstant("INTERNAL_GENERAL", RubyFixnum.newFixnum(ruby, XmlEntityDecl.INTERNAL_GENERAL));
    entityDecl.defineConstant("EXTERNAL_GENERAL_PARSED", RubyFixnum.newFixnum(ruby, XmlEntityDecl.EXTERNAL_GENERAL_PARSED));
    entityDecl.defineConstant("EXTERNAL_GENERAL_UNPARSED", RubyFixnum.newFixnum(ruby,
                              XmlEntityDecl.EXTERNAL_GENERAL_UNPARSED));
    entityDecl.defineConstant("INTERNAL_PARAMETER", RubyFixnum.newFixnum(ruby, XmlEntityDecl.INTERNAL_PARAMETER));
    entityDecl.defineConstant("EXTERNAL_PARAMETER", RubyFixnum.newFixnum(ruby, XmlEntityDecl.EXTERNAL_PARAMETER));
    entityDecl.defineConstant("INTERNAL_PREDEFINED", RubyFixnum.newFixnum(ruby, XmlEntityDecl.INTERNAL_PREDEFINED));

    RubyClass entref = xmlModule.defineClassUnder("EntityReference", node, XML_ENTITY_REFERENCE_ALLOCATOR);
    entref.defineAnnotatedMethods(XmlEntityReference.class);

    RubyClass namespace = xmlModule.defineClassUnder("Namespace", ruby.getObject(), XML_NAMESPACE_ALLOCATOR);
    namespace.defineAnnotatedMethods(XmlNamespace.class);

    RubyClass nodeSet = xmlModule.defineClassUnder("NodeSet", ruby.getObject(), XML_NODESET_ALLOCATOR);
    nodeSet.defineAnnotatedMethods(XmlNodeSet.class);

    RubyClass pi = xmlModule.defineClassUnder("ProcessingInstruction", node, XML_PROCESSING_INSTRUCTION_ALLOCATOR);
    pi.defineAnnotatedMethods(XmlProcessingInstruction.class);

    RubyClass reader = xmlModule.defineClassUnder("Reader", ruby.getObject(), XML_READER_ALLOCATOR);
    reader.defineAnnotatedMethods(XmlReader.class);

    RubyClass schema = xmlModule.defineClassUnder("Schema", ruby.getObject(), XML_SCHEMA_ALLOCATOR);
    schema.defineAnnotatedMethods(XmlSchema.class);

    RubyClass relaxng = xmlModule.defineClassUnder("RelaxNG", schema, XML_RELAXNG_ALLOCATOR);
    relaxng.defineAnnotatedMethods(XmlRelaxng.class);

    RubyClass xpathContext = xmlModule.defineClassUnder("XPathContext", ruby.getObject(), XML_XPATHCONTEXT_ALLOCATOR);
    xpathContext.defineAnnotatedMethods(XmlXpathContext.class);

    return node;
  }

  private void
  createHtmlModule(Ruby ruby, RubyModule htmlModule)
  {
    RubyClass htmlElemDesc = htmlModule.defineClassUnder("ElementDescription", ruby.getObject(),
                             HTML_ELEMENT_DESCRIPTION_ALLOCATOR);
    htmlElemDesc.defineAnnotatedMethods(Html4ElementDescription.class);

    RubyClass htmlEntityLookup = htmlModule.defineClassUnder("EntityLookup", ruby.getObject(),
                                 HTML_ENTITY_LOOKUP_ALLOCATOR);
    htmlEntityLookup.defineAnnotatedMethods(Html4EntityLookup.class);
  }

  private void
  createDocuments(Ruby ruby, RubyModule xmlModule, RubyModule htmlModule, RubyClass node)
  {
    RubyClass xmlDocument = xmlModule.defineClassUnder("Document", node, XML_DOCUMENT_ALLOCATOR);
    xmlDocument.defineAnnotatedMethods(XmlDocument.class);

    //RubyModule htmlDoc = html.defineOrGetClassUnder("Document", document);
    RubyModule htmlDocument = htmlModule.defineClassUnder("Document", xmlDocument, HTML_DOCUMENT_ALLOCATOR);
    htmlDocument.defineAnnotatedMethods(Html4Document.class);
  }

  private void
  createSaxModule(Ruby ruby, RubyModule xmlSaxModule, RubyModule htmlSaxModule)
  {
    RubyClass xmlSaxParserContext = xmlSaxModule.defineClassUnder("ParserContext", ruby.getObject(),
                                    XML_SAXPARSER_CONTEXT_ALLOCATOR);
    xmlSaxParserContext.defineAnnotatedMethods(XmlSaxParserContext.class);

    RubyClass xmlSaxPushParser = xmlSaxModule.defineClassUnder("PushParser", ruby.getObject(), XML_SAXPUSHPARSER_ALLOCATOR);
    xmlSaxPushParser.defineAnnotatedMethods(XmlSaxPushParser.class);

    RubyClass htmlSaxPushParser = htmlSaxModule.defineClassUnder("PushParser", ruby.getObject(),
                                  HTML_SAXPUSHPARSER_ALLOCATOR);
    htmlSaxPushParser.defineAnnotatedMethods(Html4SaxPushParser.class);

    RubyClass htmlSaxParserContext = htmlSaxModule.defineClassUnder("ParserContext", xmlSaxParserContext,
                                     HTML_SAXPARSER_CONTEXT_ALLOCATOR);
    htmlSaxParserContext.defineAnnotatedMethods(Html4SaxParserContext.class);
  }

  private void
  createXsltModule(Ruby ruby, RubyModule xsltModule)
  {
    RubyClass stylesheet = xsltModule.defineClassUnder("Stylesheet", ruby.getObject(), XSLT_STYLESHEET_ALLOCATOR);
    stylesheet.defineAnnotatedMethods(XsltStylesheet.class);
  }

  public static final ObjectAllocator HTML_DOCUMENT_ALLOCATOR = new ObjectAllocator()
  {
    private Html4Document htmlDocument = null;
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      if (htmlDocument == null) { htmlDocument = new Html4Document(runtime, klazz); }
      try {
        Html4Document clone = (Html4Document) htmlDocument.clone();
        clone.setMetaClass(klazz);
        return clone;
      } catch (CloneNotSupportedException e) {
        return new Html4Document(runtime, klazz);
      }
    }
  };

  private static final ObjectAllocator HTML_SAXPARSER_CONTEXT_ALLOCATOR = new ObjectAllocator()
  {
    private Html4SaxParserContext htmlSaxParserContext = null;
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      if (htmlSaxParserContext == null) { htmlSaxParserContext = new Html4SaxParserContext(runtime, klazz); }
      try {
        Html4SaxParserContext clone = (Html4SaxParserContext) htmlSaxParserContext.clone();
        clone.setMetaClass(klazz);
        return clone;
      } catch (CloneNotSupportedException e) {
        return new Html4SaxParserContext(runtime, klazz);
      }
    }
  };

  private static ObjectAllocator HTML_ELEMENT_DESCRIPTION_ALLOCATOR =
    new ObjectAllocator()
  {
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      return new Html4ElementDescription(runtime, klazz);
    }
  };

  private static ObjectAllocator HTML_ENTITY_LOOKUP_ALLOCATOR =
    new ObjectAllocator()
  {
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      return new Html4EntityLookup(runtime, klazz);
    }
  };

  public static final ObjectAllocator XML_ATTR_ALLOCATOR = new ObjectAllocator()
  {
    private XmlAttr xmlAttr = null;
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      if (xmlAttr == null) { xmlAttr = new XmlAttr(runtime, klazz); }
      try {
        XmlAttr clone = (XmlAttr) xmlAttr.clone();
        clone.setMetaClass(klazz);
        return clone;
      } catch (CloneNotSupportedException e) {
        return new XmlAttr(runtime, klazz);
      }
    }
  };

  public static final ObjectAllocator XML_CDATA_ALLOCATOR = new ObjectAllocator()
  {
    private XmlCdata xmlCdata = null;
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      if (xmlCdata == null) { xmlCdata = new XmlCdata(runtime, klazz); }
      try {
        XmlCdata clone = (XmlCdata) xmlCdata.clone();
        clone.setMetaClass(klazz);
        return clone;
      } catch (CloneNotSupportedException e) {
        return new XmlCdata(runtime, klazz);
      }
    }
  };

  public static final ObjectAllocator XML_COMMENT_ALLOCATOR = new ObjectAllocator()
  {
    private XmlComment xmlComment = null;
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      if (xmlComment == null) { xmlComment = new XmlComment(runtime, klazz); }
      try {
        XmlComment clone = (XmlComment) xmlComment.clone();
        clone.setMetaClass(klazz);
        return clone;
      } catch (CloneNotSupportedException e) {
        return new XmlComment(runtime, klazz);
      }
    }
  };

  public static final ObjectAllocator XML_DOCUMENT_ALLOCATOR = new ObjectAllocator()
  {
    private XmlDocument xmlDocument = null;
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      if (xmlDocument == null) { xmlDocument = new XmlDocument(runtime, klazz); }
      try {
        XmlDocument clone = (XmlDocument) xmlDocument.clone();
        clone.setMetaClass(klazz);
        return clone;
      } catch (CloneNotSupportedException e) {
        return new XmlDocument(runtime, klazz);
      }
    }
  };

  public static final ObjectAllocator XML_DOCUMENT_FRAGMENT_ALLOCATOR = new ObjectAllocator()
  {
    private XmlDocumentFragment xmlDocumentFragment = null;
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      if (xmlDocumentFragment == null) { xmlDocumentFragment = new XmlDocumentFragment(runtime, klazz); }
      try {
        XmlDocumentFragment clone = (XmlDocumentFragment)xmlDocumentFragment.clone();
        clone.setMetaClass(klazz);
        return clone;
      } catch (CloneNotSupportedException e) {
        return new XmlDocumentFragment(runtime, klazz);
      }
    }
  };

  public static final ObjectAllocator XML_DTD_ALLOCATOR = new ObjectAllocator()
  {
    private XmlDtd xmlDtd = null;
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      if (xmlDtd == null) { xmlDtd = new XmlDtd(runtime, klazz); }
      try {
        XmlDtd clone = (XmlDtd)xmlDtd.clone();
        clone.setMetaClass(klazz);
        return clone;
      } catch (CloneNotSupportedException e) {
        return new XmlDtd(runtime, klazz);
      }
    }
  };

  public static final ObjectAllocator XML_ELEMENT_ALLOCATOR = new ObjectAllocator()
  {
    private XmlElement xmlElement = null;
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      if (xmlElement == null) { xmlElement = new XmlElement(runtime, klazz); }
      try {
        XmlElement clone = (XmlElement)xmlElement.clone();
        clone.setMetaClass(klazz);
        return clone;
      } catch (CloneNotSupportedException e) {
        return new XmlElement(runtime, klazz);
      }
    }
  };

  public static ObjectAllocator XML_ELEMENT_DECL_ALLOCATOR = new ObjectAllocator()
  {
    private XmlElementDecl xmlElementDecl = null;
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      if (xmlElementDecl == null) { xmlElementDecl = new XmlElementDecl(runtime, klazz); }
      try {
        XmlElementDecl clone = (XmlElementDecl)xmlElementDecl.clone();
        clone.setMetaClass(klazz);
        return clone;
      } catch (CloneNotSupportedException e) {
        return new XmlElementDecl(runtime, klazz);
      }
    }
  };

  public static ObjectAllocator XML_ENTITY_REFERENCE_ALLOCATOR = new ObjectAllocator()
  {
    private XmlEntityReference xmlEntityRef = null;
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      if (xmlEntityRef == null) { xmlEntityRef = new XmlEntityReference(runtime, klazz); }
      try {
        XmlEntityReference clone = (XmlEntityReference)xmlEntityRef.clone();
        clone.setMetaClass(klazz);
        return clone;
      } catch (CloneNotSupportedException e) {
        return new XmlEntityReference(runtime, klazz);
      }
    }
  };

  public static final ObjectAllocator XML_NAMESPACE_ALLOCATOR = new ObjectAllocator()
  {
    private XmlNamespace xmlNamespace = null;
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      if (xmlNamespace == null) { xmlNamespace = new XmlNamespace(runtime, klazz); }
      try {
        XmlNamespace clone = (XmlNamespace) xmlNamespace.clone();
        clone.setMetaClass(klazz);
        return clone;
      } catch (CloneNotSupportedException e) {
        return new XmlNamespace(runtime, klazz);
      }
    }
  };

  public static final ObjectAllocator XML_NODE_ALLOCATOR = new ObjectAllocator()
  {
    private XmlNode xmlNode = null;
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      if (xmlNode == null) { xmlNode = new XmlNode(runtime, klazz); }
      try {
        XmlNode clone  = (XmlNode) xmlNode.clone();
        clone.setMetaClass(klazz);
        return clone;
      } catch (CloneNotSupportedException e) {
        return new XmlNode(runtime, klazz);
      }
    }
  };

  public static final ObjectAllocator XML_NODESET_ALLOCATOR = new ObjectAllocator()
  {
    private XmlNodeSet xmlNodeSet = null;
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      if (xmlNodeSet == null) { xmlNodeSet = new XmlNodeSet(runtime, klazz); }
      try {
        XmlNodeSet clone  = (XmlNodeSet) xmlNodeSet.clone();
        clone.setMetaClass(klazz);
        return clone;
      } catch (CloneNotSupportedException e) {
        return new XmlNodeSet(runtime, klazz);
      }
    }
  };

  public static ObjectAllocator XML_PROCESSING_INSTRUCTION_ALLOCATOR = new ObjectAllocator()
  {
    private XmlProcessingInstruction xmlProcessingInstruction = null;
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      if (xmlProcessingInstruction == null) { xmlProcessingInstruction = new XmlProcessingInstruction(runtime, klazz); }
      try {
        XmlProcessingInstruction clone = (XmlProcessingInstruction)xmlProcessingInstruction.clone();
        clone.setMetaClass(klazz);
        return clone;
      } catch (CloneNotSupportedException e) {
        return new XmlProcessingInstruction(runtime, klazz);
      }
    }
  };

  public static ObjectAllocator XML_READER_ALLOCATOR = new ObjectAllocator()
  {
    private XmlReader xmlReader = null;
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      if (xmlReader == null) { xmlReader = new XmlReader(runtime, klazz); }
      try {
        XmlReader clone  = (XmlReader) xmlReader.clone();
        clone.setMetaClass(klazz);
        return clone;
      } catch (CloneNotSupportedException e) {
        xmlReader = new XmlReader(runtime, klazz);
        return xmlReader;
      }
    }
  };

  private static ObjectAllocator XML_ATTRIBUTE_DECL_ALLOCATOR = new ObjectAllocator()
  {
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      return new XmlAttributeDecl(runtime, klazz);
    }
  };

  private static ObjectAllocator XML_ENTITY_DECL_ALLOCATOR = new ObjectAllocator()
  {
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      return new XmlEntityDecl(runtime, klazz);
    }
  };

  private static ObjectAllocator XML_ELEMENT_CONTENT_ALLOCATOR = new ObjectAllocator()
  {
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      throw runtime.newNotImplementedError("not implemented");
    }
  };

  public static final ObjectAllocator XML_RELAXNG_ALLOCATOR = new ObjectAllocator()
  {
    private XmlRelaxng xmlRelaxng = null;
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      if (xmlRelaxng == null) { xmlRelaxng = new XmlRelaxng(runtime, klazz); }
      try {
        XmlRelaxng clone  = (XmlRelaxng) xmlRelaxng.clone();
        clone.setMetaClass(klazz);
        return clone;
      } catch (CloneNotSupportedException e) {
        return new XmlRelaxng(runtime, klazz);
      }
    }
  };

  public static final ObjectAllocator XML_SAXPARSER_CONTEXT_ALLOCATOR = new ObjectAllocator()
  {
    private XmlSaxParserContext xmlSaxParserContext = null;
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      if (xmlSaxParserContext == null) { xmlSaxParserContext = new XmlSaxParserContext(runtime, klazz); }
      try {
        XmlSaxParserContext clone = (XmlSaxParserContext) xmlSaxParserContext.clone();
        clone.setMetaClass(klazz);
        return clone;
      } catch (CloneNotSupportedException e) {
        return new XmlSaxParserContext(runtime, klazz);
      }
    }
  };

  private static final ObjectAllocator XML_SAXPUSHPARSER_ALLOCATOR = new ObjectAllocator()
  {
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      return new XmlSaxPushParser(runtime, klazz);
    }
  };

  private static final ObjectAllocator HTML_SAXPUSHPARSER_ALLOCATOR = new ObjectAllocator()
  {
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      return new Html4SaxPushParser(runtime, klazz);
    }
  };

  public static final ObjectAllocator XML_SCHEMA_ALLOCATOR = new ObjectAllocator()
  {
    private XmlSchema xmlSchema = null;
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      if (xmlSchema == null) { xmlSchema = new XmlSchema(runtime, klazz); }
      try {
        XmlSchema clone  = (XmlSchema) xmlSchema.clone();
        clone.setMetaClass(klazz);
        return clone;
      } catch (CloneNotSupportedException e) {
        return new XmlSchema(runtime, klazz);
      }
    }
  };

  public static final ObjectAllocator XML_SYNTAXERROR_ALLOCATOR = new ObjectAllocator()
  {
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      return new XmlSyntaxError(runtime, klazz);
    }
  };

  public static final ObjectAllocator XML_TEXT_ALLOCATOR = new ObjectAllocator()
  {
    private XmlText xmlText = null;
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      if (xmlText == null) { xmlText = new XmlText(runtime, klazz); }
      try {
        XmlText clone  = (XmlText) xmlText.clone();
        clone.setMetaClass(klazz);
        return clone;
      } catch (CloneNotSupportedException e) {
        return new XmlText(runtime, klazz);
      }
    }
  };

  public static final ObjectAllocator XML_XPATHCONTEXT_ALLOCATOR = new ObjectAllocator()
  {
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      return new XmlXpathContext(runtime, klazz);
    }
  };

  public static ObjectAllocator XSLT_STYLESHEET_ALLOCATOR = new ObjectAllocator()
  {
    private XsltStylesheet xsltStylesheet = null;
    public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
      if (xsltStylesheet == null) { xsltStylesheet = new XsltStylesheet(runtime, klazz); }
      try {
        XsltStylesheet clone  = (XsltStylesheet) xsltStylesheet.clone();
        clone.setMetaClass(klazz);
        return clone;
      } catch (CloneNotSupportedException e) {
        return new XmlText(runtime, klazz);
      }
    }
  };
}
