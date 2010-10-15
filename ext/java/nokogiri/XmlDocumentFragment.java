package nokogiri;

import static nokogiri.internals.NokogiriHelpers.getLocalNameForNamespace;
import static nokogiri.internals.NokogiriHelpers.getLocalPart;
import static nokogiri.internals.NokogiriHelpers.getNokogiriClass;
import static nokogiri.internals.NokogiriHelpers.getPrefix;
import static nokogiri.internals.NokogiriHelpers.isNamespace;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import nokogiri.internals.SaveContext;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Attr;
import org.w3c.dom.NamedNodeMap;

/**
 *
 * @author sergio
 */
@JRubyClass(name="Nokogiri::XML::DocumentFragment", parent="Nokogiri::XML::Node")
public class XmlDocumentFragment extends XmlNode {
    private XmlElement fragmentContext = null;

    public XmlDocumentFragment(Ruby ruby) {
        this(ruby, getNokogiriClass(ruby, "Nokogiri::XML::DocumentFragment"));
    }

    public XmlDocumentFragment(Ruby ruby, RubyClass klazz) {
        super(ruby, klazz);
    }

//    @JRubyMethod(name="new", meta = true)
//    public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject doc) {
//        IRubyObject[] argc = new IRubyObject[1];
//        argc[0] = doc;
//        return rbNew(context, cls, argc);
//    }

    @JRubyMethod(name="new", meta = true, required=1, optional=2)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject cls, IRubyObject[] argc) {
        
        if(argc.length < 1) {
            throw context.getRuntime().newArgumentError(argc.length, 1);
        }

        if(!(argc[0] instanceof XmlDocument)){
            throw context.getRuntime().newArgumentError("first parameter must be a Nokogiri::XML::Document instance");
        }

        XmlDocument doc = (XmlDocument) argc[0];
        
        // make wellformed fragment, ignore invalid namespace, or add appropriate namespace to parse
        if (argc.length > 1 && argc[1] instanceof RubyString) {
            argc[1] = JavaUtil.convertJavaToRuby(context.getRuntime(), ignoreNamespaceIfNeeded(doc, (String)argc[1].toJava(String.class)));
            argc[1] = JavaUtil.convertJavaToRuby(context.getRuntime(), addNamespaceDeclIfNeeded(doc, (String)argc[1].toJava(String.class)));
        }

        XmlDocumentFragment fragment = (XmlDocumentFragment) ((RubyClass)cls).allocate();
        fragment.setDocument(context, doc);
        fragment.setNode(context, doc.getDocument().createDocumentFragment());

        //TODO: Get namespace definitions from doc.
        if (argc.length == 3 && argc[2] != null && argc[2] instanceof XmlElement) {
            fragment.fragmentContext = (XmlElement)argc[2];
        }
        RuntimeHelpers.invoke(context, fragment, "initialize", argc);
        return fragment;
    }

    private static Pattern qname_pattern = Pattern.compile("[^</:>\\s]+:[^</:>=\\s]+");
    private static Pattern starttag_pattern = Pattern.compile("<[^</>]+>");
    
    private static String ignoreNamespaceIfNeeded(XmlDocument doc, String tags) {
        if (doc.getDocument() == null) return tags;
        if (doc.getDocument().getDocumentElement() == null) return tags;
        Matcher matcher = qname_pattern.matcher(tags);
        Map<String, String> rewriteTable = new HashMap<String, String>();
        while(matcher.find()) {
            String qName = matcher.group();
            NamedNodeMap nodeMap = doc.getDocument().getDocumentElement().getAttributes();
            if (!isNamespaceDefined(qName, nodeMap)) {
                rewriteTable.put(qName, getLocalPart(qName));
            }
        }
        Set<String> keys = rewriteTable.keySet();
        for (String key : keys) {
            tags = tags.replace(key, rewriteTable.get(key));
        }
        return tags;
    }
    
    private static boolean isNamespaceDefined(String qName, NamedNodeMap nodeMap) {
        if (isNamespace(qName.intern())) return true;
        for (int i=0; i < nodeMap.getLength(); i++) {
            Attr attr = (Attr)nodeMap.item(i);
            if (isNamespace(attr.getNodeName())) {
                String localPart = getLocalNameForNamespace(attr.getNodeName());
                if (getPrefix(qName).equals(localPart)) {
                    return true;
                }
            }
        }
        return false;
    }
    
    private static String addNamespaceDeclIfNeeded(XmlDocument doc, String tags) {
        if (doc.getDocument() == null) return tags;
        if (doc.getDocument().getDocumentElement() == null) return tags;
        Matcher matcher = starttag_pattern.matcher(tags);
        Map<String, String> rewriteTable = new HashMap<String, String>();
        while(matcher.find()) {
            String start_tag = matcher.group();
            Matcher matcher2 = qname_pattern.matcher(start_tag);
            while(matcher2.find()) {
                String qName = matcher2.group();
                NamedNodeMap nodeMap = doc.getDocument().getDocumentElement().getAttributes();
                if (isNamespaceDefined(qName, nodeMap)) {
                    String namespaceDecl = getNamespceDecl(getPrefix(qName), nodeMap);
                    if (namespaceDecl != null) {
                        rewriteTable.put("<"+qName+">", "<"+qName + " " + namespaceDecl+">");
                    }
                }
            }
        }
        Set<String> keys = rewriteTable.keySet();
        for (String key : keys) {
            tags = tags.replace(key, rewriteTable.get(key));
        }
        
        return tags;
    }
    
    private static String getNamespceDecl(String prefix, NamedNodeMap nodeMap) {
        for (int i=0; i < nodeMap.getLength(); i++) {
            Attr attr = (Attr)nodeMap.item(i);
            if (prefix.equals(attr.getLocalName())) {
                return attr.getName() + "=\"" + attr.getValue() + "\"";
            }
        }
        return null;
    }

    public XmlElement getFragmentContext() {
        return fragmentContext;
    }

    //@Override
    public void add_child(ThreadContext context, XmlNode child) {
        // Some magic for DocumentFragment

        Ruby ruby = context.getRuntime();
        XmlNodeSet children = (XmlNodeSet) child.children(context);

        long length = children.length();

        RubyArray childrenArray = children.convertToArray();

        if(length != 0) {
            for(int i = 0; i < length; i++) {
                XmlNode item = (XmlNode) ((XmlNode) childrenArray.aref(ruby.newFixnum(i))).dup_implementation(context, true);
                add_child(context, item);
            }
        }
    }

    @Override
    public void relink_namespace(ThreadContext context) {
        ((XmlNodeSet) children(context)).relink_namespace(context);
    }

    @Override
    public void saveContent(ThreadContext context, SaveContext ctx) {
        saveNodeListContent(context, (XmlNodeSet) children(context), ctx);
    }

}
