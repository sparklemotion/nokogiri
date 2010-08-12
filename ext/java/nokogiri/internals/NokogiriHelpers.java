package nokogiri.internals;

import java.nio.ByteBuffer;
import java.nio.charset.Charset;

import nokogiri.NokogiriService;
import nokogiri.XmlAttr;
import nokogiri.XmlCdata;
import nokogiri.XmlComment;
import nokogiri.XmlDocument;
import nokogiri.XmlElement;
import nokogiri.XmlNamespace;
import nokogiri.XmlNode;
import nokogiri.XmlText;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyString;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;
import org.w3c.dom.Attr;
import org.w3c.dom.Document;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

/**
 *
 * @author serabe
 */
public class NokogiriHelpers {
    public static final String CACHED_NODE = "NOKOGIRI_CACHED_NODE";
    public static final String VALID_ROOT_NODE = "NOKOGIRI_VALIDE_ROOT_NODE";

    public static XmlNode getCachedNode(Node node) {
        return (XmlNode) node.getUserData(CACHED_NODE);
    }

    /**
     * Get the XmlNode associated with the underlying
     * <code>node</code>. Creates a new XmlNode (or appropriate subclass)
     * or XmlNamespace wrapping <code>node</code> if there is no cached
     * value.
     */
    public static IRubyObject getCachedNodeOrCreate(Ruby ruby, Node node) {
        if(node == null) return ruby.getNil();
        if (node.getNodeType() == Node.ATTRIBUTE_NODE && isNamespace(node.getNodeName())) {
            XmlDocument xmlDocument = (XmlDocument)node.getOwnerDocument().getUserData(CACHED_NODE);
            String prefix = getLocalNameForNamespace(((Attr)node).getName());
            prefix = prefix != null ? prefix : "";
            String href = ((Attr)node).getValue();
            XmlNamespace xmlNamespace = xmlDocument.getNamespaceCache().get(prefix, href);
            if (xmlNamespace == null) {
                return xmlDocument.getNamespaceCache().put(ruby, prefix, ((Attr)node).getValue(), node, xmlDocument);
            }
        }
        XmlNode xmlNode = getCachedNode(node);
        if(xmlNode == null) {
            xmlNode = (XmlNode)constructNode(ruby, node);
            node.setUserData(CACHED_NODE, xmlNode, null);
        }
        return xmlNode;
    }
    
    /**
     * Construct a new XmlNode wrapping <code>node</code>.  The proper
     * subclass of XmlNode is chosen based on the type of
     * <code>node</code>.
     */
    public static IRubyObject constructNode(Ruby ruby, Node node) {
        if (node == null) return ruby.getNil();
        // this is slow; need a way to cache nokogiri classes/modules somewhere
        switch (node.getNodeType()) {
            case Node.ELEMENT_NODE:
                XmlElement xmlElement = (XmlElement) getNokogiriClass(ruby, "Nokogiri::XML::Element").allocate();
                xmlElement.setNode(ruby.getCurrentContext(), node);
                return xmlElement;
            case Node.ATTRIBUTE_NODE:
                XmlAttr xmlAttr = (XmlAttr) getNokogiriClass(ruby, "Nokogiri::XML::Attr").allocate();
                xmlAttr.setNode(ruby.getCurrentContext(), node);
                return xmlAttr;
            case Node.TEXT_NODE:
                XmlText xmlText = (XmlText) getNokogiriClass(ruby, "Nokogiri::XML::Text").allocate();
                xmlText.setNode(ruby.getCurrentContext(), node);
                return xmlText;
            case Node.COMMENT_NODE:
                XmlComment xmlComment = (XmlComment) getNokogiriClass(ruby, "Nokogiri::XML::Comment").allocate();
                xmlComment.setNode(ruby.getCurrentContext(), node);
                return xmlComment;
            case Node.ENTITY_NODE:
                return new XmlNode(ruby, getNokogiriClass(ruby, "Nokogiri::XML::EntityDecl"), node);
            case Node.CDATA_SECTION_NODE:
                XmlCdata xmlCdata = (XmlCdata) getNokogiriClass(ruby, "Nokogiri::XML::CDATA").allocate();
                xmlCdata.setNode(ruby.getCurrentContext(), node);
                return xmlCdata;
            case Node.DOCUMENT_NODE:
                return new XmlDocument(ruby, getNokogiriClass(ruby, "Nokogiri::XML::Document"), (Document) node);
            default:
                XmlNode xmlNode = (XmlNode) getNokogiriClass(ruby, "Nokogiri::XML::Node").allocate();
                xmlNode.setNode(ruby.getCurrentContext(), node);
                return xmlNode;
        }
    }
    
    public static RubyClass getNokogiriClass(Ruby ruby, String name) {
        RubyHash classCache = (RubyHash) ruby.getGlobalVariables().get(NokogiriService.nokogiriClassCacheGvarName);
        IRubyObject rubyName = JavaUtil.convertJavaToUsableRubyObject(ruby, name);
        return (RubyClass)classCache.fastARef(rubyName);
    }

    public static IRubyObject stringOrNil(Ruby ruby, String s) {
        if (s == null)
            return ruby.getNil();

        return JavaUtil.convertJavaToUsableRubyObject(ruby, s);
    }
    
    public static IRubyObject stringOrBlank(Ruby ruby, String s) {
        if (s == null) return ruby.newString();
        return ruby.newString(s);
    }

    /**
     * Convert <code>s</code> to a RubyString, or if s is null or
     * empty return RubyNil.
     */
    public static IRubyObject nonEmptyStringOrNil(Ruby ruby, String s) {
        if (s == null || s.length() == 0)
            return ruby.getNil();

        return ruby.newString(s);
    }

    /**
     * Return the prefix of a qualified name like "prefix:local".
     * Returns null if there is no prefix.
     */
    public static String getPrefix(String qName) {
        if (qName == null) return null;

        int pos = qName.indexOf(':');
        if (pos > 0)
            return qName.substring(0, pos);
        else
            return null;
    }

    /**
     * Return the local part of a qualified name like "prefix:local".
     * Returns <code>qName</code> if there is no prefix.
     */
    public static String getLocalPart(String qName) {
        if (qName == null) return null;

        int pos = qName.indexOf(':');
        if (pos > 0)
            return qName.substring(pos + 1);
        else
            return qName;
    }

    public static String getLocalNameForNamespace(String name) {
        String localName = getLocalPart(name);
        return ("xmlns".equals(localName)) ? null : localName;
    }

    protected static Charset utf8 = null;
    protected static Charset getCharsetUTF8() {
        if (utf8 == null) {
            utf8 = Charset.forName("UTF-8");
        }

        return utf8;
    }

    /**
     * Converts a RubyString in to a Java String.  Assumes the
     * RubyString is encoded as UTF-8.  This is generally the case for
     * RubyStrings created with getRuntime().newString("java string").
     * It also seems to be the case for strings created within Ruby
     * where $KCODE has not been set.
     *
     * Note that RubyString#toString() decodes the string data as
     * ISO-8859-1 (See org.jruby.util.ByteList.java).  This is not
     * what you want if you have any multibyte characters in your
     * UTF-8 string.
     *
     * FIXME: This really needs to be more robust in terms of
     * detecting the encoding and properly converting to a Java
     * String.  It's unfortunate that RubyString#toString() doesn't do
     * this for us.
     */
    public static String rubyStringToString(IRubyObject str) {
        return rubyStringToString(str.convertToString());
    }

    public static String rubyStringToString(RubyString str) {
        ByteList byteList = str.getByteList();
        byte[] data = byteList.unsafeBytes();
        int offset = byteList.begin();
        int len = byteList.length();
        ByteBuffer buf = ByteBuffer.wrap(data, offset, len);
        return getCharsetUTF8().decode(buf).toString();
    }

    public static String getNodeCompletePath(Node node) {

        Node cur, tmp, next;

        // TODO: Rename buffer to path.
        String buffer = "";
        String sep;
        String name;

        int occur = 0;
        boolean generic;

        cur = node;

        do {
            name = "";
            sep = "?";
            occur = 0;
            generic = false;

            if(cur.getNodeType() == Node.DOCUMENT_NODE) {
                if(buffer.startsWith("/")) break;

                sep = "/";
                next = null;
            } else if(cur.getNodeType() == Node.ELEMENT_NODE) {
                generic = false;
                sep = "/";

                name = cur.getLocalName();
                if (name == null) name = cur.getNodeName();
                if(cur.getNamespaceURI() != null) {
                    if(cur.getPrefix() != null) {
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

                while(tmp != null) {
                    if((tmp.getNodeType() == Node.ELEMENT_NODE) &&
                       (generic || fullNamesMatch(tmp, cur))) {
                        occur++;
                    }
                    tmp = tmp.getPreviousSibling();
                }

                if(occur == 0) {
                    tmp = cur.getNextSibling();

                    while(tmp != null && occur == 0) {
                        if((tmp.getNodeType() == Node.ELEMENT_NODE) &&
                            (generic || fullNamesMatch(tmp,cur))) {
                            occur++;
                        }
                        tmp = tmp.getNextSibling();
                    }

                    if(occur != 0) occur = 1;

                } else {
                    occur++;
                }
            } else if(cur.getNodeType() == Node.COMMENT_NODE) {
                sep = "/";
                name = "comment()";
                next = cur.getParentNode();

                /*
                 * Thumbler index computation.
                 */

                tmp = cur.getPreviousSibling();

                while(tmp != null) {
                    if(tmp.getNodeType() == Node.COMMENT_NODE) {
                        occur++;
                    }
                    tmp = tmp.getPreviousSibling();
                }

                if(occur == 0) {
                    tmp = cur.getNextSibling();
                    while(tmp != null && occur == 0) {
                        if(tmp.getNodeType() == Node.COMMENT_NODE) {
                            occur++;
                        }
                        tmp = tmp.getNextSibling();
                    }
                    if(occur != 0) occur = 1;
                } else {
                    occur = 1;
                }

            } else if(cur.getNodeType() == Node.TEXT_NODE ||
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
                while(tmp != null) {
                    if(tmp.getNodeType() == Node.TEXT_NODE ||
                            tmp.getNodeType() == Node.CDATA_SECTION_NODE) {
                        occur++;
                    }
                    tmp = tmp.getPreviousSibling();
                }

                if(occur == 0) {
                    tmp = cur.getNextSibling();

                    while(tmp != null && occur == 0) {
                        if(tmp.getNodeType() == Node.TEXT_NODE ||
                                tmp.getNodeType() == Node.CDATA_SECTION_NODE) {
                            occur++;
                        }
                        tmp = tmp.getNextSibling();
                    }
                } else {
                    occur++;
                }

            } else if(cur.getNodeType() == Node.PROCESSING_INSTRUCTION_NODE) {
                sep = "/";
                name = "processing-instruction('"+cur.getLocalName()+"')";
                next = cur.getParentNode();

                /*
                 * Thumbler index computation.
                 */

                tmp = cur.getParentNode();

                while(tmp != null) {
                    if(tmp.getNodeType() == Node.PROCESSING_INSTRUCTION_NODE &&
                            tmp.getLocalName().equals(cur.getLocalName())) {
                        occur++;
                    }
                    tmp = tmp.getPreviousSibling();
                }

                if(occur == 0) {
                    tmp = cur.getNextSibling();

                    while(tmp != null && occur == 0) {
                        if(tmp.getNodeType() == Node.PROCESSING_INSTRUCTION_NODE &&
                                tmp.getLocalName().equals(cur.getLocalName())){
                            occur++;
                        }
                        tmp = tmp.getNextSibling();
                    }

                    if(occur != 0) {
                        occur = 1;
                    }

                } else {
                    occur++;
                }

            } else if(cur.getNodeType() == Node.ATTRIBUTE_NODE) {
                sep = "/@";
                name = cur.getLocalName();

                if(cur.getNamespaceURI() != null) {
                    if(cur.getPrefix() != null) {
                        name = cur.getPrefix() + ":" + name;
                    }
                }

                next = ((Attr) cur).getOwnerElement();

            } else {
                next = cur.getParentNode();
            }

            if(occur == 0){
                buffer = sep+name+buffer;
            } else {
                buffer = sep+name+"["+occur+"]"+buffer;
            }

            cur = next;

        } while(cur != null);

        return buffer;
    }

    protected static boolean compareTwoNodes(Node m, Node n) {
        return nodesAreEqual(m.getLocalName(), n.getLocalName()) &&
               nodesAreEqual(m.getPrefix(), n.getPrefix());
    }

    protected static boolean fullNamesMatch(Node a, Node b) {
        return a.getNodeName().equals(b.getNodeName());
        //return getFullName(a).equals(getFullName(b));
    }

    protected static String getFullName(Node n) {
        String lname = n.getLocalName();
        String prefix = n.getPrefix();
        if (lname != null) {
            if (prefix != null)
                return prefix + ":" + lname;
            else
                return lname;
        } else {
            return n.getNodeName();
        }
    }

    private static boolean nodesAreEqual(Object a, Object b) {
      return (((a == null) && (a == null)) ||
                (a != null) && (b != null) &&
                (b.equals(a)));
    }

    public static String encodeJavaString(String s) {

        // From entities.c
        s = s.replaceAll("&", "&amp;");
        s = s.replaceAll("<", "&lt;");
        s = s.replaceAll(">", "&gt;");
//        s = s.replaceAll("\"", "&quot;");
        return s.replaceAll("\r", "&#13;");
    }
    
    public static String decodeJavaString(String s) {
        s = s.replaceAll("&amp;", "&");
        s = s.replaceAll("&lt;", "<");
        s = s.replaceAll("&gt;", ">");
        return s.replaceAll("&#13;", "\r");
    }
    
    public static boolean isXmlEscaped(String s) {
        if (s == null) return true;
        if (s.contains("<") || s.contains(">") || s.contains("\r")) return false;
        if (s.contains("&") && !s.contains("&amp;")) return false;
        return true;
    }

    public static String getNodeName(Node node) {
        if(node == null) { System.out.println("node is null"); return ""; }
        String name = node.getNodeName();
        if(name == null) { System.out.println("name is null"); return ""; }
        if(name.equals("#document")) {
            return "document";
        } else if(name.equals("#text")) {
            return "text";
        } else {
            name = getLocalPart(name);
            return (name == null) ? "" : name;
        }
    }

    public static final String XMLNS_URI = "http://www.w3.org/2000/xmlns/";
    public static boolean isNamespace(Node node) {
        return (XMLNS_URI.equals(node.getNamespaceURI()) ||
                isNamespace(node.getNodeName()));
    }

    public static boolean isNamespace(String nodeName) {
        return (nodeName.equals("xmlns") || nodeName.startsWith("xmlns:"));
    }

    public static boolean isNonDefaultNamespace(Node node) {
        return (isNamespace(node) && ! "xmlns".equals(node.getNodeName()));
    }

    public static boolean isXmlBase(String attrName) {
        return "xml:base".equals(attrName) || "xlink:href".equals(attrName);
    }

    public static String newQName(String newPrefix, Node node) {
        if(newPrefix == null) {
            return node.getLocalName();
        } else {
            return newPrefix + ":" + node.getLocalName();
        }
    }

    public static RubyArray nodeListToRubyArray(Ruby ruby, NodeList nodes) {
        RubyArray n = RubyArray.newArray(ruby, nodes.getLength());
        for(int i = 0; i < nodes.getLength(); i++) {
            n.append(NokogiriHelpers.getCachedNodeOrCreate(ruby, nodes.item(i)));
        }
        return n;
    }
    
    public static RubyArray nodeArrayToRubyArray(Ruby ruby, Node[] nodes) {
        RubyArray n = RubyArray.newArray(ruby, nodes.length);
        for(int i = 0; i < nodes.length; i++) {
            n.append(NokogiriHelpers.getCachedNodeOrCreate(ruby, nodes[i]));
        }
        return n;
    }
    
    public static RubyArray namedNodeMapToRubyArray(Ruby ruby, NamedNodeMap map) {
        RubyArray n = RubyArray.newArray(ruby, map.getLength());
        for(int i = 0; i < map.getLength(); i++) {
            n.append(NokogiriHelpers.getCachedNodeOrCreate(ruby, map.item(i)));
        }
        return n;
    }
    
    public static String guessEncoding(Ruby ruby) {
        String name = null;
        if (name == null) name = System.getProperty("file.encoding");
        if (name == null) name = "UTF-8";
        return name;
    }
}
