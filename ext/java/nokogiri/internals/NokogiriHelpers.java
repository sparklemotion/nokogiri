package nokogiri.internals;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.nio.charset.Charset;
import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyString;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;
import org.w3c.dom.Attr;
import org.w3c.dom.DOMException;
import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import nokogiri.Html4Document;
import nokogiri.NokogiriService;
import nokogiri.XmlAttr;
import nokogiri.XmlCdata;
import nokogiri.XmlComment;
import nokogiri.XmlDocument;
import nokogiri.XmlDtd;
import nokogiri.XmlElement;
import nokogiri.XmlEntityReference;
import nokogiri.XmlNamespace;
import nokogiri.XmlNode;
import nokogiri.XmlProcessingInstruction;
import nokogiri.XmlText;
import nokogiri.XmlXpathContext;

/**
 * A class for various utility methods.
 *
 * @author serabe
 * @author Patrick Mahoney <pat@polycrystal.org>
 * @author Yoko Harada <yokolet@gmail.com>
 */
public class NokogiriHelpers
{
  public static final String CACHED_NODE = "NOKOGIRI_CACHED_NODE";
  public static final String ROOT_NODE_INVALID = "NOKOGIRI_ROOT_NODE_INVALID";
  public static final String ENCODED_STRING = "NOKOGIRI_ENCODED_STRING";

  public static XmlNode
  getCachedNode(Node node)
  {
    return (XmlNode) node.getUserData(CACHED_NODE);
  }

  public static void
  clearCachedNode(Node node)
  {
    node.setUserData(CACHED_NODE, null, null);
  }

  public static void
  clearXpathContext(Node node)
  {
    if (node == null) { return; }

    Node ownerDocument = node.getOwnerDocument();
    if (ownerDocument == null) {
      ownerDocument = node;
    }
    ownerDocument.setUserData(XmlXpathContext.XPATH_CONTEXT, null, null);
  }

  /**
   * Get the XmlNode associated with the underlying
   * <code>node</code>. Creates a new XmlNode (or appropriate subclass)
   * or XmlNamespace wrapping <code>node</code> if there is no cached
   * value.
   */
  public static IRubyObject
  getCachedNodeOrCreate(Ruby runtime, Node node)
  {
    if (node == null) { return runtime.getNil(); }
    if (node.getNodeType() == Node.ATTRIBUTE_NODE && isNamespace(node.getNodeName())) {
      XmlDocument xmlDocument = (XmlDocument) node.getOwnerDocument().getUserData(CACHED_NODE);
      if (!(xmlDocument instanceof Html4Document)) {
        String prefix = getLocalNameForNamespace(((Attr) node).getName(), null);
        String href = ((Attr) node).getValue();
        XmlNamespace xmlNamespace = xmlDocument.getNamespaceCache().get(prefix, href);
        if (xmlNamespace != null) { return xmlNamespace; }
        return XmlNamespace.createFromAttr(runtime, (Attr) node);
      }
    }
    XmlNode xmlNode = getCachedNode(node);
    if (xmlNode == null) {
      xmlNode = (XmlNode) constructNode(runtime, node);
      node.setUserData(CACHED_NODE, xmlNode, null);
    }
    return xmlNode;
  }

  /**
   * Construct a new XmlNode wrapping <code>node</code>.  The proper
   * subclass of XmlNode is chosen based on the type of
   * <code>node</code>.
   */
  public static IRubyObject
  constructNode(Ruby runtime, Node node)
  {
    if (node == null) { return runtime.getNil(); }
    // this is slow; need a way to cache nokogiri classes/modules somewhere
    switch (node.getNodeType()) {
      case Node.ELEMENT_NODE:
        XmlElement xmlElement = (XmlElement) NokogiriService.XML_ELEMENT_ALLOCATOR.allocate(runtime, getNokogiriClass(runtime,
                                "Nokogiri::XML::Element"));
        xmlElement.setNode(runtime, node);
        return xmlElement;
      case Node.ATTRIBUTE_NODE:
        XmlAttr xmlAttr = (XmlAttr) NokogiriService.XML_ATTR_ALLOCATOR.allocate(runtime, getNokogiriClass(runtime,
                          "Nokogiri::XML::Attr"));
        xmlAttr.setNode(runtime, node);
        return xmlAttr;
      case Node.TEXT_NODE:
        XmlText xmlText = (XmlText) NokogiriService.XML_TEXT_ALLOCATOR.allocate(runtime, getNokogiriClass(runtime,
                          "Nokogiri::XML::Text"));
        xmlText.setNode(runtime, node);
        return xmlText;
      case Node.COMMENT_NODE:
        XmlComment xmlComment = (XmlComment) NokogiriService.XML_COMMENT_ALLOCATOR.allocate(runtime, getNokogiriClass(runtime,
                                "Nokogiri::XML::Comment"));
        xmlComment.setNode(runtime, node);
        return xmlComment;
      case Node.ENTITY_NODE:
        return new XmlNode(runtime, getNokogiriClass(runtime, "Nokogiri::XML::EntityDecl"), node);
      case Node.ENTITY_REFERENCE_NODE:
        XmlEntityReference xmlEntityRef = (XmlEntityReference) NokogiriService.XML_ENTITY_REFERENCE_ALLOCATOR.allocate(runtime,
                                          getNokogiriClass(runtime, "Nokogiri::XML::EntityReference"));
        xmlEntityRef.setNode(runtime, node);
        return xmlEntityRef;
      case Node.PROCESSING_INSTRUCTION_NODE:
        XmlProcessingInstruction xmlProcessingInstruction = (XmlProcessingInstruction)
            NokogiriService.XML_PROCESSING_INSTRUCTION_ALLOCATOR.allocate(runtime, getNokogiriClass(runtime,
                "Nokogiri::XML::ProcessingInstruction"));
        xmlProcessingInstruction.setNode(runtime, node);
        return xmlProcessingInstruction;
      case Node.CDATA_SECTION_NODE:
        XmlCdata xmlCdata = (XmlCdata) NokogiriService.XML_CDATA_ALLOCATOR.allocate(runtime, getNokogiriClass(runtime,
                            "Nokogiri::XML::CDATA"));
        xmlCdata.setNode(runtime, node);
        return xmlCdata;
      case Node.DOCUMENT_NODE:
        XmlDocument xmlDocument = (XmlDocument) NokogiriService.XML_DOCUMENT_ALLOCATOR.allocate(runtime,
                                  getNokogiriClass(runtime, "Nokogiri::XML::Document"));
        xmlDocument.setDocumentNode(runtime, (Document) node);
        return xmlDocument;
      case Node.DOCUMENT_TYPE_NODE:
        XmlDtd xmlDtd = (XmlDtd) NokogiriService.XML_DTD_ALLOCATOR.allocate(runtime, getNokogiriClass(runtime,
                        "Nokogiri::XML::DTD"));
        xmlDtd.setNode(runtime, node);
        return xmlDtd;
      default:
        XmlNode xmlNode = (XmlNode) NokogiriService.XML_NODE_ALLOCATOR.allocate(runtime, getNokogiriClass(runtime,
                          "Nokogiri::XML::Node"));
        xmlNode.setNode(runtime, node);
        return xmlNode;
    }
  }

  public static RubyClass
  getNokogiriClass(Ruby ruby, String name)
  {
    return NokogiriService.getNokogiriClassCache(ruby).get(name);
  }

  public static IRubyObject
  stringOrNil(Ruby runtime, String str)
  {
    return str == null ? runtime.getNil() : convertString(runtime, str);
  }

  public static IRubyObject
  stringOrNil(Ruby runtime, CharSequence str)
  {
    return str == null ? runtime.getNil() : convertString(runtime, str);
  }

  public static IRubyObject
  stringOrNil(Ruby runtime, byte[] bytes)
  {
    return bytes == null ? runtime.getNil() : RubyString.newString(runtime, bytes);
  }

  public static IRubyObject
  stringOrBlank(Ruby runtime, String str)
  {
    return str == null ? runtime.newString() : convertString(runtime, str);
  }

  public static RubyString
  convertString(Ruby runtime, String str)
  {
    return RubyString.newUTF8String(runtime, str);
  }

  public static RubyString
  convertString(Ruby runtime, CharSequence str)
  {
    return RubyString.newUTF8String(runtime, str);
  }

  /**
   * Convert <code>s</code> to a RubyString, or if s is null or
   * empty return RubyNil.
   */
  public static IRubyObject
  nonEmptyStringOrNil(Ruby runtime, String s)
  {
    if (s == null || s.length() == 0) { return runtime.getNil(); }
    return RubyString.newString(runtime, s);
  }

  /**
   * Return the prefix of a qualified name like "prefix:local".
   * Returns null if there is no prefix.
   */
  public static String
  getPrefix(String qName)
  {
    if (qName == null) { return null; }

    final int pos = qName.indexOf(':');
    return pos > 0 ? qName.substring(0, pos) : null;
  }

  /**
   * Return the local part of a qualified name like "prefix:local".
   * Returns <code>qName</code> if there is no prefix.
   */
  public static String
  getLocalPart(String qName)
  {
    if (qName == null) { return null; }

    final int pos = qName.indexOf(':');
    return pos > 0 ? qName.substring(pos + 1) : qName;
  }

  public static String
  getLocalNameForNamespace(String name, String defValue)
  {
    String localName = getLocalPart(name);
    return ("xmlns".equals(localName)) ? defValue : localName;
  }

  public static String
  rubyStringToString(IRubyObject str)
  {
    if (str.isNil()) { return null; }
    return str.convertToString().decodeString();
  }

  public static String
  rubyStringToString(RubyString str)
  {
    return str.decodeString(); // if encoding UTF-8 will decode UTF-8
  }

  public static ByteArrayInputStream
  stringBytesToStream(final IRubyObject str)
  {
    if (str instanceof RubyString || str.respondsTo("to_str")) {
      final ByteList bytes = str.convertToString().getByteList();
      return new ByteArrayInputStream(bytes.unsafeBytes(), bytes.begin(), bytes.length());
    }
    return null;
  }

  public static String
  getNodeCompletePath(Node node)
  {

    Node cur, tmp, next;

    String buffer = "";

    cur = node;

    do {
      String name = "";
      String sep = "?";
      int occur = 0;
      boolean generic = false;

      if (cur.getNodeType() == Node.DOCUMENT_NODE) {
        if (buffer.startsWith("/")) { break; }

        sep = "/";
        next = null;
      } else if (cur.getNodeType() == Node.ELEMENT_NODE) {
        generic = false;
        sep = "/";

        name = cur.getLocalName();
        if (name == null) { name = cur.getNodeName(); }
        if (cur.getNamespaceURI() != null) {
          if (cur.getPrefix() != null) {
            name = cur.getPrefix() + ":" + name;
          } else {
            generic = true;
            name = "*";
          }
        }

        next = cur.getParentNode();

        /*
         * Thumbler index computation
         */

        tmp = cur.getPreviousSibling();

        while (tmp != null) {
          if ((tmp.getNodeType() == Node.ELEMENT_NODE) &&
              (generic || fullNamesMatch(tmp, cur))) {
            occur++;
          }
          tmp = tmp.getPreviousSibling();
        }

        if (occur == 0) {
          tmp = cur.getNextSibling();

          while (tmp != null && occur == 0) {
            if ((tmp.getNodeType() == Node.ELEMENT_NODE) &&
                (generic || fullNamesMatch(tmp, cur))) {
              occur++;
            }
            tmp = tmp.getNextSibling();
          }

          if (occur != 0) { occur = 1; }

        } else {
          occur++;
        }
      } else if (cur.getNodeType() == Node.COMMENT_NODE) {
        sep = "/";
        name = "comment()";
        next = cur.getParentNode();

        /*
         * Thumbler index computation.
         */

        tmp = cur.getPreviousSibling();

        while (tmp != null) {
          if (tmp.getNodeType() == Node.COMMENT_NODE) {
            occur++;
          }
          tmp = tmp.getPreviousSibling();
        }

        if (occur == 0) {
          tmp = cur.getNextSibling();
          while (tmp != null && occur == 0) {
            if (tmp.getNodeType() == Node.COMMENT_NODE) {
              occur++;
            }
            tmp = tmp.getNextSibling();
          }
          if (occur != 0) { occur = 1; }
        } else {
          occur = 1;
        }

      } else if (cur.getNodeType() == Node.TEXT_NODE ||
                 cur.getNodeType() == Node.CDATA_SECTION_NODE) {
        // I'm here. gist:129
        // http://gist.github.com/144923

        sep = "/";
        name = "text()";
        next = cur.getParentNode();

        /*
         * Thumbler index computation.
         */

        tmp = cur.getPreviousSibling();
        while (tmp != null) {
          if (tmp.getNodeType() == Node.TEXT_NODE ||
              tmp.getNodeType() == Node.CDATA_SECTION_NODE) {
            occur++;
          }
          tmp = tmp.getPreviousSibling();
        }

        if (occur == 0) {
          tmp = cur.getNextSibling();

          while (tmp != null && occur == 0) {
            if (tmp.getNodeType() == Node.TEXT_NODE ||
                tmp.getNodeType() == Node.CDATA_SECTION_NODE) {
              occur++;
            }
            tmp = tmp.getNextSibling();
          }
        } else {
          occur++;
        }

      } else if (cur.getNodeType() == Node.PROCESSING_INSTRUCTION_NODE) {
        sep = "/";
        name = "processing-instruction('" + cur.getLocalName() + "')";
        next = cur.getParentNode();

        /*
         * Thumbler index computation.
         */

        tmp = cur.getParentNode();

        while (tmp != null) {
          if (tmp.getNodeType() == Node.PROCESSING_INSTRUCTION_NODE &&
              tmp.getLocalName().equals(cur.getLocalName())) {
            occur++;
          }
          tmp = tmp.getPreviousSibling();
        }

        if (occur == 0) {
          tmp = cur.getNextSibling();

          while (tmp != null && occur == 0) {
            if (tmp.getNodeType() == Node.PROCESSING_INSTRUCTION_NODE &&
                tmp.getLocalName().equals(cur.getLocalName())) {
              occur++;
            }
            tmp = tmp.getNextSibling();
          }

          if (occur != 0) {
            occur = 1;
          }

        } else {
          occur++;
        }

      } else if (cur.getNodeType() == Node.ATTRIBUTE_NODE) {
        sep = "/@";
        name = cur.getLocalName();

        if (cur.getNamespaceURI() != null) {
          if (cur.getPrefix() != null) {
            name = cur.getPrefix() + ":" + name;
          }
        }

        next = ((Attr) cur).getOwnerElement();

      } else {
        next = cur.getParentNode();
      }

      if (occur == 0) {
        buffer = sep + name + buffer;
      } else {
        buffer = sep + name + "[" + occur + "]" + buffer;
      }

      cur = next;

    } while (cur != null);

    return buffer;
  }

  static boolean
  compareTwoNodes(Node m, Node n)
  {
    return nodesAreEqual(m.getLocalName(), n.getLocalName()) &&
           nodesAreEqual(m.getPrefix(), n.getPrefix());
  }

  private static boolean
  nodesAreEqual(Object a, Object b)
  {
    return (((a == null) && (b == null)) ||
            ((a != null) && (b != null) && (b.equals(a))));
  }

  private static boolean
  fullNamesMatch(Node a, Node b)
  {
    return a.getNodeName().equals(b.getNodeName());
  }

  private static final Pattern encoded_pattern = Pattern.compile("&amp;|&gt;|&lt;|&#13;");
  private static final String[] encoded = {"&amp;", "&gt;", "&lt;", "&#13;"};
  private static final Pattern decoded_pattern = Pattern.compile("&|>|<|\r");
  private static final String[] decoded = {"&", ">", "<", "\r"};

  private static StringBuffer
  convert(Pattern ptn, CharSequence input, String[] oldChars, String[] newChars)
  {
    Matcher matcher = ptn.matcher(input);
    boolean result = matcher.find();
    StringBuffer sb = new StringBuffer(input.length() + 8);
    while (result) {
      String matched = matcher.group();
      String replacement = "";
      for (int i = 0; i < oldChars.length; i++) {
        if (matched.contains(oldChars[i])) {
          replacement = matched.replace(oldChars[i], newChars[i]);
          break;
        }
      }
      matcher.appendReplacement(sb, replacement);
      result = matcher.find();
    }
    matcher.appendTail(sb);
    return sb;
  }

  public static CharSequence
  encodeJavaString(CharSequence str)
  {
    return convert(decoded_pattern, str, decoded, encoded);
  }

  public static CharSequence
  decodeJavaString(CharSequence str)
  {
    return convert(encoded_pattern, str, encoded, decoded);
  }

  public static final String XMLNS_URI = "http://www.w3.org/2000/xmlns/";
  public static boolean
  isNamespace(Node node)
  {
    return (XMLNS_URI.equals(node.getNamespaceURI()) || isNamespace(node.getNodeName()));
  }

  public static boolean
  isNamespace(String nodeName)
  {
    return (nodeName.startsWith("xmlns"));
  }

  public static boolean
  isNonDefaultNamespace(Node node)
  {
    return (isNamespace(node) && ! "xmlns".equals(node.getNodeName()));
  }

  public static boolean
  isXmlBase(String attrName)
  {
    return "xml:base".equals(attrName) || "xlink:href".equals(attrName);
  }

  public static boolean
  isBlank(IRubyObject obj)
  {
    if (!(obj instanceof XmlText)) { return false; }

    CharSequence content = ((XmlNode) obj).getContentImpl();
    return content == null || isBlank(content);
  }

  public static boolean
  isBlank(CharSequence str)
  {
    int len = str.length();
    int beg = 0;
    while ((beg < len) && (str.charAt(beg) <= ' ')) { beg++; }
    return beg == len;
  }

  public static boolean
  isBlank(String str)
  {
    return str.isEmpty() || isBlank((CharSequence) str);
  }

  public static boolean
  isNullOrEmpty(String str)
  {
    return str == null || str.isEmpty();
  }

  public static CharSequence
  canonicalizeWhitespace(CharSequence str)
  {
    final int len = str.length();
    StringBuilder sb = new StringBuilder(len);
    boolean newline_added = false;
    for (int i = 0; i < len; i++) {
      char c = str.charAt(i);
      if (c == '\n') {
        if (! newline_added) {
          sb.append(c);
          newline_added = true;
        }
      } else {
        sb.append(c);
      }
    }
    return sb;
  }

  public static String
  newQName(String newPrefix, Node node)
  {
    String tagName = getLocalPart(node.getNodeName());
    if (newPrefix == null) { return tagName; }
    return newPrefix + ':' + tagName;
  }

  public static IRubyObject[]
  nodeListToRubyArray(Ruby runtime, NodeList nodes)
  {
    IRubyObject[] array = new IRubyObject[nodes.getLength()];
    for (int i = 0; i < nodes.getLength(); i++) {
      array[i] = NokogiriHelpers.getCachedNodeOrCreate(runtime, nodes.item(i));
    }
    return array;
  }

  public static IRubyObject[]
  nodeListToArray(Ruby ruby, List<Node> nodes)
  {
    IRubyObject[] result = new IRubyObject[nodes.size()];
    for (int i = 0; i < result.length; i++) {
      result[i] = NokogiriHelpers.getCachedNodeOrCreate(ruby, nodes.get(i));
    }
    return result;
  }

  public static RubyArray<?>
  nodeArrayToRubyArray(Ruby ruby, Node[] nodes)
  {
    RubyArray<?> n = RubyArray.newArray(ruby, nodes.length);
    for (int i = 0; i < nodes.length; i++) {
      n.append(NokogiriHelpers.getCachedNodeOrCreate(ruby, nodes[i]));
    }
    return n;
  }

  public static String
  getValidEncodingOrNull(IRubyObject encoding)
  {
    if (encoding.isNil()) { return null; } // charsetNames does not like contains(null)
    String enc = rubyStringToString(encoding.convertToString());
    if (CharsetNames.contains(enc)) { return enc; }
    return null;
  }

  public static String
  getValidEncoding(IRubyObject encoding)
  {
    String validEncoding = getValidEncodingOrNull(encoding);
    if (validEncoding != null) { return validEncoding; }
    return Charset.defaultCharset().name();
  }

  private static final Set<String> CharsetNames = Charset.availableCharsets().keySet();

  public static String
  adjustSystemIdIfNecessary(String currentDir, String scriptFileName, String baseURI, String systemId)
  {
    if (systemId == null) { return systemId; }
    File file = new File(systemId);
    if (file.isAbsolute()) { return systemId; }
    String path = resolveSystemId(baseURI, systemId);
    if (path != null) { return path; }
    path = resolveSystemId(currentDir, systemId);
    if (path != null) { return path; }
    return resolveSystemId(scriptFileName, systemId);
  }

  private static String
  resolveSystemId(String baseName, String systemId)
  {
    if (baseName == null || baseName.length() < 1) { return null; }
    String parentName;
    baseName = baseName.replace("%20", " ");
    File base = new File(baseName);
    if (base.isDirectory()) { parentName = baseName; }
    else { parentName = base.getParent(); }
    if (parentName == null) { return null; }
    if (parentName.toLowerCase().startsWith("file:")) { parentName = parentName.substring("file:".length()); }
    File dtdFile = new File(parentName + "/" + systemId);
    if (dtdFile.exists()) { return dtdFile.getPath(); }
    return null;
  }

  private static final Charset UTF8 = Charset.forName("UTF-8");

  public static boolean
  isUTF8(String encoding)
  {
    if (encoding == null) { return true; } // no need to convert encoding

    if ("UTF-8".equals(encoding)) { return true; }
    return UTF8.aliases().contains(encoding);
  }

  public static ByteBuffer
  convertEncoding(Charset output_charset, CharSequence input_string)
  {
    return output_charset.encode(CharBuffer.wrap(input_string)); // does replace implicitly on un-mappable characters
  }

  public static CharSequence
  convertEncodingByNKFIfNecessary(ThreadContext context, XmlDocument doc, CharSequence str)
  {
    if (!(doc instanceof Html4Document)) { return str; }
    String parsed_encoding = ((Html4Document)doc).getPraedEncoding();
    if (parsed_encoding == null) { return str; }
    String ruby_encoding = rubyStringToString(doc.getEncoding());
    if (ruby_encoding == null) { return str; }
    Charset encoding = Charset.forName(ruby_encoding);
    if (Charset.forName(parsed_encoding).compareTo(encoding) == 0) { return str; }
    if (str.length() == 0) { return str; } // no need to convert
    return NokogiriHelpers.nkf(context, encoding, str);
  }

  private static final ByteList _Sw = new ByteList(new byte[] { '-', 'S', 'w' }, false);
  private static final ByteList _Jw = new ByteList(new byte[] { '-', 'J', 'w' }, false);
  private static final ByteList _Ew = new ByteList(new byte[] { '-', 'E', 'w' }, false);
  private static final ByteList _Ww = new ByteList(new byte[] { '-', 'W', 'w' }, false);

  // This method is used from HTML documents. HTML meta tag with encoding specification
  // might appear after non-ascii characters are used. For example, a title tag before
  // a meta tag. In such a case, Xerces encodes characters in UTF-8 without seeing meta tag.
  // Nokogiri uses NKF library to convert characters correct encoding. This means the method
  // works only for JIS/Shift_JIS/EUC-JP.
  private static CharSequence
  nkf(ThreadContext context, Charset encoding, CharSequence str)
  {
    final Ruby runtime = context.getRuntime();
    final ByteList opt;
    if (NokogiriHelpers.Shift_JIS.compareTo(encoding) == 0) { opt = _Sw; }
    else if (NokogiriHelpers.ISO_2022_JP.compareTo(encoding) == 0) { opt = _Jw; }
    else if (NokogiriHelpers.EUC_JP.compareTo(encoding) == 0) { opt = _Ew; }
    else { opt = _Ww; } // should not come here. should be treated before this method.

    Class<?> nkfClass;
    try {
      nkfClass = Ruby.getClassLoader().loadClass("org.jruby.ext.nkf.RubyNKF");
    } catch (ClassNotFoundException e1) {
      return str;
    }
    Method nkf_method;
    try {
      nkf_method = nkfClass.getMethod("nkf", ThreadContext.class, IRubyObject.class, IRubyObject.class, IRubyObject.class);
      RubyString r_str =
        (RubyString)nkf_method.invoke(null, context, null, runtime.newString(opt), runtime.newString(str.toString()));
      return NokogiriHelpers.rubyStringToString(r_str);
    } catch (SecurityException e) {
      return str;
    } catch (NoSuchMethodException e) {
      return str;
    } catch (IllegalArgumentException e) {
      return str;
    } catch (IllegalAccessException e) {
      return str;
    } catch (InvocationTargetException e) {
      return str;
    }
  }

  private static final Charset Shift_JIS = Charset.forName("Shift_JIS");
  private static final Charset ISO_2022_JP = Charset.forName("ISO-2022-JP"); // JIS
  private static final Charset EUC_JP = Charset.forName("EUC-JP");

  public static boolean
  shouldEncode(Node text)
  {
    final Boolean encoded = (Boolean) text.getUserData(NokogiriHelpers.ENCODED_STRING);
    return encoded == null || ! encoded;
  }

  public static boolean
  shouldDecode(Node text)
  {
    return !shouldEncode(text);
  }

  public static NokogiriNamespaceCache
  getNamespaceCache(Node node)
  {
    XmlDocument xmlDoc = (XmlDocument) getCachedNode(node.getOwnerDocument());
    return xmlDoc.getNamespaceCache();
  }

  public static Node
  renameNode(Node node, String namespaceURI, String qualifiedName) throws DOMException
  {
    Document doc = node.getOwnerDocument();
    NokogiriNamespaceCache nsCache = getNamespaceCache(node);
    Node result = doc.renameNode(node, namespaceURI, qualifiedName);
    if (result != node) {
      nsCache.replaceNode(node, result);
    }
    return result;
  }
}
