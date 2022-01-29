package nokogiri;

import static nokogiri.internals.NokogiriHelpers.getLocalNameForNamespace;
import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;
import static nokogiri.internals.NokogiriHelpers.getPrefix;
import static nokogiri.internals.NokogiriHelpers.isNamespace;
import static nokogiri.internals.NokogiriHelpers.rubyStringToString;

import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Block;
import org.jruby.runtime.Helpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;
import org.w3c.dom.Attr;
import org.w3c.dom.NamedNodeMap;

/**
 * Class for Nokogiri::XML::DocumentFragment
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */
@JRubyClass(name = "Nokogiri::XML::DocumentFragment", parent = "Nokogiri::XML::Node")
public class XmlDocumentFragment extends XmlNode
{
  private static final long serialVersionUID = 1L;

  public
  XmlDocumentFragment(Ruby ruby)
  {
    this(ruby, getNokogiriClass(ruby, "Nokogiri::XML::DocumentFragment"));
  }

  public
  XmlDocumentFragment(Ruby ruby, RubyClass klazz)
  {
    super(ruby, klazz);
  }

  @JRubyMethod(name = "new", meta = true, required = 1, optional = 3)
  public static IRubyObject
  rbNew(ThreadContext context, IRubyObject cls, IRubyObject[] args, Block block)
  {
    if (args.length < 1) {
      throw context.runtime.newArgumentError(args.length, 1);
    }

    if (!(args[0] instanceof XmlDocument)) {
      throw context.runtime.newArgumentError("first parameter must be a Nokogiri::XML::Document instance");
    }

    XmlDocument doc = (XmlDocument) args[0];

    // make wellformed fragment, ignore invalid namespace, or add appropriate namespace to parse
    if (args.length > 1 && args[1] instanceof RubyString) {
      final RubyString arg1 = (RubyString) args[1];
      if (XmlDocumentFragment.isTag(arg1)) {
        args[1] = RubyString.newString(context.runtime, addNamespaceDeclIfNeeded(doc, rubyStringToString(arg1)));
      }
    }

    XmlDocumentFragment fragment = (XmlDocumentFragment) NokogiriService.XML_DOCUMENT_FRAGMENT_ALLOCATOR.allocate(
                                     context.runtime, (RubyClass)cls);
    fragment.setDocument(context, doc);
    fragment.setNode(context.runtime, doc.getDocument().createDocumentFragment());

    Helpers.invoke(context, fragment, "initialize", args, block);
    return fragment;
  }

  private static final ByteList TAG_BEG = ByteList.create("<");
  private static final ByteList TAG_END = ByteList.create(">");

  private static boolean
  isTag(final RubyString str)
  {
    return str.getByteList().startsWith(TAG_BEG) && str.getByteList().endsWith(TAG_END);
  }

  private static boolean
  isNamespaceDefined(String qName, NamedNodeMap nodeMap)
  {
    if (isNamespace(qName.intern())) { return true; }
    for (int i = 0; i < nodeMap.getLength(); i++) {
      Attr attr = (Attr)nodeMap.item(i);
      if (isNamespace(attr.getNodeName())) {
        String localPart = getLocalNameForNamespace(attr.getNodeName(), null);
        if (getPrefix(qName).equals(localPart)) {
          return true;
        }
      }
    }
    return false;
  }

  private static final Pattern QNAME_RE = Pattern.compile("[^</:>\\s]+:[^</:>=\\s]+");
  private static final Pattern START_TAG_RE = Pattern.compile("<[^</>]+>");

  private static String
  addNamespaceDeclIfNeeded(XmlDocument doc, String tags)
  {
    if (doc.getDocument() == null) { return tags; }
    if (doc.getDocument().getDocumentElement() == null) { return tags; }
    Matcher matcher = START_TAG_RE.matcher(tags);
    Map<CharSequence, CharSequence> rewriteTable = null;
    while (matcher.find()) {
      String start_tag = matcher.group();
      Matcher matcher2 = QNAME_RE.matcher(start_tag);
      while (matcher2.find()) {
        String qName = matcher2.group();
        NamedNodeMap nodeMap = doc.getDocument().getDocumentElement().getAttributes();
        if (isNamespaceDefined(qName, nodeMap)) {
          CharSequence namespaceDecl = getNamespaceDecl(getPrefix(qName), nodeMap);
          if (namespaceDecl != null) {
            if (rewriteTable == null) { rewriteTable = new HashMap<CharSequence, CharSequence>(8, 1); }
            StringBuilder str = new StringBuilder(qName.length() + namespaceDecl.length() + 3);
            String key = str.append('<').append(qName).append('>').toString();
            str.setCharAt(key.length() - 1, ' '); // (last) '>' -> ' '
            rewriteTable.put(key, str.append(namespaceDecl).append('>'));
          }
        }
      }
    }
    if (rewriteTable != null) {
      for (Map.Entry<CharSequence, CharSequence> e : rewriteTable.entrySet()) {
        tags = tags.replace(e.getKey(), e.getValue());
      }
    }

    return tags;
  }

  private static CharSequence
  getNamespaceDecl(final String prefix, NamedNodeMap nodeMap)
  {
    for (int i = 0; i < nodeMap.getLength(); i++) {
      Attr attr = (Attr) nodeMap.item(i);
      if (prefix.equals(attr.getLocalName())) {
        return new StringBuilder().
               append(attr.getName()).append('=').append('"').append(attr.getValue()).append('"');
      }
    }
    return null;
  }

  @Override
  public void
  relink_namespace(ThreadContext context)
  {
    relink_namespace(context, getChildren());
  }
}
